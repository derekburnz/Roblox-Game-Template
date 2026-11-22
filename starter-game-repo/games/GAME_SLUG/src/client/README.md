# src/client

Runs on each player's device (it becomes `StarterPlayerScripts.Client`). Treat it as untrusted: a player can change it.

- `Main.client.luau` loads every module in `Controllers/`.
- `Controllers/`: client state and input. They talk to the server through remotes.
- `UI/`: screens built in code. They read controller state and never fire remotes directly. The starter `UI/init.luau` is a tiny example HUD (one button, one window, toasts) so the UI gate has something to check; replace it, and add a scene in `tools/cloudcheck/uigate-scenes.luau` for every new window.
- `Effects/` and `Audio/`: cosmetic only (owned by the vfx-animator and sound-designer roles).

Add the `Effects/` and `Audio/` folders when the first feature needs them.
