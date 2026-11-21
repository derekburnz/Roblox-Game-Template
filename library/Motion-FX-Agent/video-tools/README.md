# video-tools

Scripts and templates for making videos of the game. Motion-FX-Agent owns this folder. Each tool has a short README.

| Path | What it is |
|---|---|
| `shot-list-template.md` | The plan a recording session works from |
| `recording-tips.md` | How to get smooth, clean takes in Studio on the owner's PC |
| `page-video/` | `cut.sh`: joins raw takes into the game page video (real gameplay, no text) |
| `story-clips/` | `story.py`: a narrated story over real gameplay clips, portrait, for short-video apps |

The fully animated story format (scenes rendered from scripts, with a voice and word captions) is assembled with the tools in `library/Growth-Agent/story-kit/`.

## Who does what
1. Growth-Agent (its Social Video helper) plans the video and writes the script and caption. See `library/Growth-Agent/playbooks/short-video-format.md`.
2. Sync-Agent records real gameplay from a shot list.
3. Motion-FX-Agent cuts with these tools and checks the result.
4. The owner approves, uploads the page video and says when a social post may go out.

## Rules
- No rendered video, voice file or picture from another game is kept here. Tools only.
- Every script takes its paths, fonts, colours and names as arguments or environment variables. Never write a PC path, a game name or a key into a script.
- Music and fonts must be ones you may use. Creator Store music is for use inside Roblox only.
- Finals go to `library/` under 95 MB each. Drafts stay out of the library.
