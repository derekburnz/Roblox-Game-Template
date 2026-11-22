# tools/cloudcheck: tests and screen checks without Roblox Studio

Node 20 or newer only, no Rokit tools and no Studio. It runs on any PC and in the cloud, and CI runs it on every
pull request (the `tests` job in `.github/workflows/check.yml`).

```
cd games/GAME_SLUG/tools/cloudcheck
npm ci                       # once
npm test                     # tests/specs/*.spec.luau, one fresh Luau state per spec file
npm run analyze:tests        # strict type check and lint of src/ and tests/, Roblox API types included
npm run uigate               # the UI gate at desktop, laptop and phone sizes
npm run uigate:tablets       # the same on iPad mini, a 4:3 iPad, iPad Pro, a 16:10 Android tablet and a Fire 7
npm run uigate:devices       # a 10th-gen iPad, the smallest iPhone, a small Android phone and a console
npm run check                # everything CI runs
node run-tests.mjs --filter Guard        # one spec
node uigate.mjs --profile phone --scene Example --out /tmp/look   # one scene at one size, pictures in /tmp/look
```

| File | What |
|---|---|
| `run-tests.mjs` | Builds the instance tree from `tests.project.json`, loads every ModuleScript with its own `script` and `require`, and runs `tests/StudioRunner.luau` as Studio would. Exit code 1 on any failure. |
| `analyze.mjs` | The Luau type checker (the engine luau-lsp wraps) in strict mode, with the Roblox API definitions. Also compiles every module at Roblox's optimization levels, so a file over Luau's 200 local limit fails here. |
| `rojo-tree.mjs` | Rojo project file to instance tree. |
| `roblox-shim.luau` | A small fake Roblox (`game`, `task`, `Enum`, `Vector3`, `UDim2` and friends) for pure modules. DataStores, Players events and `Instance.new` in the world are not there on purpose: a module that needs them is tested in Studio. |
| `world-shim.luau`, `ui-shim.luau` | The fuller fake Roblox the UI gate uses: a client with PlayerGui, camera and input, signals on a virtual clock and Roblox's 2D layout. |
| `uigate.mjs`, `uigate-checks.mjs` | The UI gate: builds the real UI (`src/client/UI`) at each screen size, opens every scene and fails on buttons too small to tap (44 px on touch, 36 px with a mouse), text under 9 px, anything off screen or under Roblox's top bar, more than two fonts, and anything that keeps flickering once settled. |
| `uigate-scenes.luau` | What the gate opens. `setup()` starts the UI as `Controllers/UIController` does; each entry in `SCENES` opens one window. **Add a scene for every new window.** |
| `uigate-baseline.json` | Known findings that do not fail. Starts empty; keep it that way where you can. `node uigate.mjs --update-baseline` rewrites it from a full run. |
| `enum-keep.txt` | Enums kept in the type definitions (the full list is too big for the WebAssembly checker). Add a name here if you see `Unknown type 'Enum.X'`. |

The gate writes a report, a picture of each scene (SVG) and an `index.html` to the `--out` folder (default: the
system temp folder), never into the repo. In CI they are kept as the `uigate-report` artifact for a week.

## Limits to know
- The runtime is `@luau-rs/luau`, Luau compiled to WebAssembly. The real type gate is still `./check.sh` with the
  pinned luau-lsp, which CI also runs. Green here means "very likely fine"; red here means "definitely look".
- Each spec file runs in its own fresh Luau state with the garbage collector stopped: in one shared state the
  WebAssembly build can fail tests that pass alone. If a spec fails here but passes with `--filter` and in Studio,
  suspect the runtime first and say so in the pull request.
- `analyze.mjs --tests` fails a `*.spec.luau` file over 100,000 bytes: past about 120,000 the checker gives up on
  the whole file. Split big spec files early.
- `Enum.X` for an enum not in `enum-keep.txt` type checks as `any`. `script.Parent.Foo` outside `require()` is
  typed as `Instance` here.
