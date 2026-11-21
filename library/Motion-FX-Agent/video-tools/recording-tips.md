# Recording tips (Studio on the owner's PC)

How to get smooth, clean gameplay recordings. Sync-Agent records; Motion-FX-Agent cuts.

## Before the session
- **Plan every clip first:** a shot list with camera, action and length. The owner's PC time is short; do not spend it deciding what to film.
- **One clip first, the owner's OK, then the rest.** Once the owner hands over PC time for an approved plan, record straight through the takes. Stop for an OK only for something irreversible, paid or truly in doubt.
- Record in the dev place in a Studio playtest. Never join live servers to film, and never save the place.
- Use a test account, with the player list and chat hidden, so no player names are on screen.
- Hide side menus before recording. Clear each pop-up before the next action; one thing on screen at a time.
- Raising luck or giving the test account items for a good shot is fine in Studio, as long as anything shown as odds on screen is the real number.

## Capture
- **Choppy motion usually comes from the capture tool, not the game.** A screen grabber that repeats frames makes smooth play look bad. Use a desktop duplication style capture (the kind good screen recorders use) and check a take for repeated frames before filming the rest.
- Record a little before and after the action and trim later. The first frame of the cut is already mid action.
- For portrait clips, set Studio's device emulator to a 1080 x 1920 custom device and capture the viewport. For the page video, 1920 x 1080.
- Capture raw takes first and cut later. Name them `<day>-<slug>.mp4`.

## Keeping the frame clean
- Hiding things with a heavy sweep every fraction of a second can drop the frame rate. Use a light sweep plus a per-frame hide of the few things that respawn.
- Things that respawn can flash for a frame or two in a take you thought was clean. Check finals with an automated frame check and a slow scrub by eye.
- An effect or character that sits out of frame at the normal camera height needs a staged spot: raise it or move the camera rather than hoping.

## Camera moves
A slow orbit or push looks better than a hand-moved camera. In a playtest, a short client script can set the camera to scriptable and move it along a curve around a target for a set number of seconds, then hand the camera back. Paste it into the command bar right before recording. Studio's own tools may reset the camera while they run, so keep everything else quiet during the take.

## Shots to avoid
Sky only, a dark scene where the action cannot be seen, a character standing still under an effect, a character clipping through scenery. Every shot shows something happening.

## After
- Raw takes stay on the PC or in the shared folder. Only finals go in the library, and files stay under 95 MB.
- Send the cutter the paths and a note of what each take shows.
