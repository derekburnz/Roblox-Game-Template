# Playbook: posting through Buffer

Buffer is a scheduling tool that cross-posts one video to several apps (TikTok, Instagram Reels, YouTube Shorts). The owner holds the Buffer login and every social login. This playbook is how a video goes from a file to a scheduled post.

## The one rule
**The owner approves every push.** Claude prepares the draft, the caption and the slot. Nothing is queued, moved or published until the owner says so for that video. A public post cannot be taken back, and it goes out under the owner's name.

## Flow
1. **Draft.** The finished video file is saved in `library/Growth-Agent/` (finals only) and its path is given to the coordinator, with the caption and the proposed slot.
2. **The owner's OK,** for that video, in their own words.
3. **Queue.** In the owner's signed-in browser, with their say for this job: add the video to Buffer for each app, paste the caption, set the slot. Never type a password or a code. If a login prompt appears, stop and tell the owner.
4. **Check.** Read the queue back: the right video, the right caption per app, the right time in the owner's time zone.
5. **After it posts,** note the post time and schedule the results read.

## Captions per app
Follow the caption rule in `short-video-format.md`: game name, link, three to five plain search words and tags. Each app has its own limits on tags and on links in captions; check them when queuing. Where a link is not allowed, say "search" plus the game's name. A video title can carry a short hook plus the game's name.

## Slots
- Pick times when the audience is out of school and awake in the main region. Start with late afternoon on weekdays and late morning on weekends, in the owner's time zone, then follow the results.
- Space posts so each can be read on its own.
- The queue lives in Buffer itself. It does not die when a Claude project is remade, so list what is queued in the handoff notes.

## Swapping a queued post
When a better version of a video is approved, replace the queued one rather than adding a second. Read the queue back afterwards.

## Results
A few days after each post, read views, likes, comments and follows per video per app (from each app's page or Buffer's own stats) and append a row to the results table in `library/Growth-Agent/Social-Video-Agent/`. Tell the owner in a few lines which story and which app did best.

## Setting up accounts (the owner does this once)
The owner creates the social accounts and connects them to Buffer. Claude can list the steps and suggested defaults (a handle that matches the game, a bio that says what the game is and links to it) and never creates accounts or enters credentials.

## Roblox's own video features
In-platform clips and moments have their own rules, such as limits on voice and music. Read the current rules before making a version for them, and keep the game's own sound only when in doubt.
