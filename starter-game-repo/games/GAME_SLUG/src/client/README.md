# src/client

Runs on each player's device (it becomes `StarterPlayerScripts.Client`). Treat it as untrusted: a player can change it.

- `Main.client.luau` loads every module in `Controllers/`.
- `Controllers/`: client state and input. They talk to the server through remotes.
- `UI/`: screens built in code. They read controller state and never fire remotes directly.
- `Effects/` and `Audio/`: cosmetic only (owned by the vfx-animator and sound-designer roles).

Add the `UI/`, `Effects/` and `Audio/` folders when the first feature needs them.
