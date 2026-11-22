# src/server

Runs on Roblox's server only (it becomes `ServerScriptService.Server`). Players cannot read or change it.

- `Main.server.luau` loads every module in `Services/`, runs `Init(services)` on all of them, then `Start()`.
- `Services/NetService.luau`: creates every remote in `shared/Remotes` and is the only way client calls come in, each with a rate limit (`NetService.on`). Also `NetService.notice` for a toast.
- `Services/DataService.luau`: session-locked saves on ProfileStore, brought up to date by `shared/SaveSchema`.
- `Services/Telemetry.luau`: funnels, custom events and economy events to Roblox analytics, checked by `shared/TelemetryRules`.
- `Services/LiveFlagService.luau`: copies the live switches to attributes every minute.
- `Services/RestartNoticeService.luau`: shows players the restart countdown the `restart-servers` workflow sends.
- `Util/RateLimiter.luau`: a token bucket per key, used by `NetService`; `Util/` modules are required by services, never loaded by `Main`.
- `Vendor/`: third-party single-file modules (`ProfileStore.luau`, MIT). Never edit or reformat them; replace the whole file to update.

Rule: the server decides every outcome. Check every remote argument with `Guard` and every rule (ownership, range, cooldown) on the server. See the `remote-security-checklist` skill before writing a remote handler.
