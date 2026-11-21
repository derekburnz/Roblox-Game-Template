# page-video: the game page video cut

`./cut.sh RAW_DIR shots.txt [music file]` joins raw gameplay takes into one 1920x1080, 30 fps clip of about 20 seconds.

## Steps
1. Write the shot list first (copy `shots.example.txt`): which takes, in which order, how long each. The best moment goes first.
2. Sync-Agent records each take on the owner's PC, one file per take named `<take>.mp4` (see `../recording-tips.md`).
3. Watch each raw take and set its `start` in the shot list.
4. Run the script. `OUT=path/to/file.mp4` sets the output.
5. Check the result frame by frame for a stray pop-up or name tag, then give the file to the owner. The owner uploads it.

## Rules for the page video
- Real gameplay only.
- No on-screen text. (The script can draw text for other uses; leave the text column off for the page video.)
- Smooth takes with no repeated frames.
- The test character is not the focus, and nothing cluttering the frame: no tips, gift pop-ups or other players' names.
- Music only if you may use it off Roblox. Silent is fine.

## Needs
`ffmpeg` and `ffprobe` on PATH. Works in Git Bash on Windows.

## Status
Carried over from a first game and changed to read its shots from a file. Not run end to end since the change: make one test cut first.
