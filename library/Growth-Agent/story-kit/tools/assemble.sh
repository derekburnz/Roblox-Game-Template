#!/usr/bin/env bash
# Assemble a finished story video: the rendered story, an optional real gameplay tail, the end card
# (game icon plus a join line) and music ducked under the voice.
#
# Usage:
#   assemble.sh --main story.mp4 --voice mix.m4a --endcard endcard.png --out final.mp4 \
#               [--music track.ogg] [--card-seconds 3.0] \
#               [--tail gameplay.mp4 --tail-start 0 --tail-seconds 2.5] \
#               [--music-tempo 0.9] [--music-volume 0.55]
#
#   --main     the rendered story video, 1080x1920 (its own sound is dropped)
#   --voice    the voice track with any sound effects already mixed in
#   --endcard  a 1080x1920 picture: the game icon plus a join line
#   --music    optional; a track you may use off Roblox. It is ducked whenever the voice speaks
#   --tail     optional; a real gameplay clip shown between the story and the end card. The default
#              format has no tail: the end card alone sends viewers to the game page.
# Needs ffmpeg and ffprobe on PATH. Works in Git Bash on Windows.
set -euo pipefail

MAIN="" VOICE="" ENDCARD="" OUT="" MUSIC="" TAIL=""
CARD_SECONDS=3.0 TAIL_START=0 TAIL_SECONDS=2.5 MUSIC_TEMPO=0.9 MUSIC_VOLUME=0.55
while [ $# -gt 0 ]; do
  case "$1" in
    --main) MAIN=$2 ;;
    --voice) VOICE=$2 ;;
    --endcard) ENDCARD=$2 ;;
    --out) OUT=$2 ;;
    --music) MUSIC=$2 ;;
    --card-seconds) CARD_SECONDS=$2 ;;
    --tail) TAIL=$2 ;;
    --tail-start) TAIL_START=$2 ;;
    --tail-seconds) TAIL_SECONDS=$2 ;;
    --music-tempo) MUSIC_TEMPO=$2 ;;
    --music-volume) MUSIC_VOLUME=$2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift 2
done
for need in MAIN VOICE ENDCARD OUT; do
  [ -n "${!need}" ] || { echo "missing --$(echo "$need" | tr 'A-Z' 'a-z'); see the top of this file" >&2; exit 2; }
done

abs() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
MAIN=$(abs "$MAIN"); VOICE=$(abs "$VOICE"); ENDCARD=$(abs "$ENDCARD")
mkdir -p "$(dirname "$OUT")"; OUT=$(abs "$OUT")
[ -z "$MUSIC" ] || MUSIC=$(abs "$MUSIC")
[ -z "$TAIL" ] || TAIL=$(abs "$TAIL")

WORK=$(mktemp -d "$(dirname "$OUT")/assemble-work.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

ffmpeg -y -loglevel error -i "$MAIN" -an -c:v libx264 -crf 16 -r 30 main.mp4
printf "file 'main.mp4'\n" > list.txt
if [ -n "$TAIL" ]; then
  ffmpeg -y -loglevel error -ss "$TAIL_START" -t "$TAIL_SECONDS" -i "$TAIL" -an \
    -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,format=yuv420p" -c:v libx264 -crf 16 tail.mp4
  printf "file 'tail.mp4'\n" >> list.txt
fi
ffmpeg -y -loglevel error -loop 1 -t "$CARD_SECONDS" -i "$ENDCARD" \
  -vf "scale=1080:1920,fps=30,format=yuv420p,fade=t=in:st=0:d=0.25" -c:v libx264 -crf 16 end.mp4
printf "file 'end.mp4'\n" >> list.txt
ffmpeg -y -loglevel error -f concat -safe 0 -i list.txt -c copy video.mp4

T=$(ffprobe -v error -show_entries format=duration -of csv=p=0 video.mp4)
FADE_START=$(awk -v t="$T" 'BEGIN { printf "%.3f", t - 1.0 }')
if [ -n "$MUSIC" ]; then
  # The voice is split in two: one copy is heard, the other only tells the compressor when to duck the music.
  ffmpeg -y -loglevel error -i video.mp4 -i "$VOICE" -i "$MUSIC" -filter_complex \
    "[1:a]apad,atrim=0:$T,asplit=2[vo][sc];[2:a]atempo=$MUSIC_TEMPO,atrim=0:$T,volume=$MUSIC_VOLUME[m0];[m0][sc]sidechaincompress=threshold=0.05:ratio=6:attack=20:release=300[md];[md]afade=t=out:st=$FADE_START:d=1.0[mf];[vo][mf]amix=inputs=2:normalize=0,alimiter=limit=0.9[a]" \
    -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -movflags +faststart -t "$T" "$OUT"
else
  ffmpeg -y -loglevel error -i video.mp4 -i "$VOICE" -filter_complex "[1:a]apad,atrim=0:$T,alimiter=limit=0.9[a]" \
    -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -movflags +faststart -t "$T" "$OUT"
fi
echo "total $T s -> $OUT"
