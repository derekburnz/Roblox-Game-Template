#!/usr/bin/env bash
# Game page video cut: joins raw gameplay takes into one clip. 1920x1080, 30 fps, H.264, about 20 s.
#
# Usage: ./cut.sh RAW_DIR SHOTS_FILE [MUSIC_FILE]
#   RAW_DIR     folder holding the raw takes, one file per take: <take>.mp4
#   SHOTS_FILE  the shot list, one shot per line (see shots.example.txt):
#                   take  start  length  [text|size]
#               take is the file name without .mp4, start is seconds into the raw take, length is seconds.
#               Leave text off for the game page video: its rule is real gameplay with no on-screen text.
#               Text (for other uses) needs FONT set to a .ttf file.
#   MUSIC_FILE  optional, a track you may use off Roblox. Without it the video is silent, which is fine:
#               the page autoplays muted for most people.
# Environment: OUT (output path, default ./page-video.mp4), FONT, BOX_COLOR (text box colour, default 0x000000),
#              WORK_ROOT (where the temp folder goes).
# Runs in Git Bash on Windows too: awk does the sums and the temp folder sits next to the output, so
# Windows ffmpeg can read the concat list.
set -euo pipefail
RAW=${1:?raw folder}
SHOTS_FILE=${2:?shot list file}
MUSIC=${3:-}
FONT=${FONT:-}
BOX_COLOR=${BOX_COLOR:-0x000000}
OUT=${OUT:-$PWD/page-video.mp4}
# both absolute: ffmpeg reads concat entries relative to the list's own folder, so a relative OUT would break them
mkdir -p "$(dirname "$OUT")"
OUT=$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")
WORK=$(mktemp -d "${WORK_ROOT:-$(dirname "$OUT")}/cut-work.XXXXXX")
WORK=$(cd "$WORK" && pwd)
trap 'rm -rf "$WORK"' EXIT
# the concat list holds paths ffmpeg reads itself, so on Git Bash they are written as C:/... (cygpath -m)
LISTDIR=$WORK
if command -v cygpath > /dev/null; then LISTDIR=$(cygpath -m "$WORK"); fi
sub() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.3f", a - b }'; }

mapfile -t SHOTS < <(grep -vE '^[[:space:]]*(#|$)' "$SHOTS_FILE")
[ "${#SHOTS[@]}" -gt 0 ] || { echo "no shots in $SHOTS_FILE" >&2; exit 1; }
last=$((${#SHOTS[@]} - 1))
i=0
LIST="$WORK/list.txt"
: > "$LIST"
for shot in "${SHOTS[@]}"; do
  read -r take start len rest <<< "$shot"
  text=""
  size=72
  if [ -n "${rest:-}" ]; then
    text=${rest%|*}
    case "$rest" in *"|"*) size=${rest##*|} ;; esac
  fi
  vf="scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,fps=30,format=yuv420p"
  if [ -n "${text// /}" ]; then
    [ -n "$FONT" ] || { echo "shot '$take' has text: set FONT to a .ttf file" >&2; exit 1; }
    esc=${text//:/\\:}
    esc=${esc//\'/\\\'}
    vf="$vf,drawtext=fontfile=$FONT:text='$esc':fontsize=$size:fontcolor=white:box=1:boxcolor=$BOX_COLOR@0.92:boxborderw=28:x=(w-text_w)/2:y=(h-text_h)/2"
  fi
  # fading the first shot in would hide the hook, so only the last shot fades out
  if [ "$i" = "$last" ]; then
    vf="$vf,fade=t=out:st=$(sub "$len" 0.4):d=0.4"
  fi
  ffmpeg -loglevel error -y -ss "$start" -t "$len" -i "$RAW/$take.mp4" -an -vf "$vf" -c:v libx264 -preset medium -crf 18 "$WORK/$i.mp4"
  echo "file '$LISTDIR/$i.mp4'" >> "$LIST"
  i=$((i + 1))
done
ffmpeg -loglevel error -y -f concat -safe 0 -i "$LIST" -c copy "$WORK/video.mp4"
if [ -n "$MUSIC" ]; then
  total=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WORK/video.mp4")
  ffmpeg -loglevel error -y -i "$WORK/video.mp4" -i "$MUSIC" -filter_complex "[1:a]volume=0.5,afade=t=out:st=$(sub "$total" 1):d=1[a]" -map 0:v -map "[a]" -shortest -c:v copy -c:a aac -b:a 160k -movflags +faststart "$OUT"
else
  ffmpeg -loglevel error -y -i "$WORK/video.mp4" -c copy -movflags +faststart "$OUT"
fi
ffprobe -v error -show_entries format=duration:stream=width,height,r_frame_rate,codec_name -of compact "$OUT"
