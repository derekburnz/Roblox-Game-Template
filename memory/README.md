# memory

Empty in the template. During setup the coordinator writes two files here, and Sync-Agent keeps them word for word equal to the project's own:

- `project-instructions.md`: the project instructions as saved in the Claude project.
- `project-memory.md`: the project memory index (`MEMORY.md`).

Each memory topic gets its own file beside them, linked from `project-memory.md`.

Why: a Claude project can be lost or remade. These copies let a new project start where the last one stopped. Never save a secret here.
