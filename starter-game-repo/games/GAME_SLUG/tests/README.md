# tests/ -> ReplicatedStorage.Tests (only with tests.project.json)

Unit tests for pure modules: modules that load without DataStores, Players events or the world.

| File | What |
|---|---|
| `TestKit.luau` | Small TestEZ-compatible framework: describe / it / expect, hooks, skip and focus. Runs in Studio and in a plain Luau VM. |
| `StudioRunner.luau` | Finds `*.spec` ModuleScripts under a folder, requires them and runs them with TestKit. |
| `specs/*.spec.luau` | One spec file per module under test. |

## Writing a spec

```lua
--!strict
return function()
	local Guard = require(game:GetService("ReplicatedStorage").Shared.Guard)

	describe("Guard.int", function()
		it("refuses NaN", function()
			expect(Guard.int(0 / 0, 1, 5)).to.equal(nil)
		end)
	end)
end
```

A spec returns a function. Inside it, `describe`, `it`, `expect`, `beforeEach`, `afterEach`, `beforeAll`,
`afterAll`, `itSKIP`, `itFOCUS`, `describeSKIP` and `describeFOCUS` are globals. `expect(x)` supports `to.equal`,
`to.be.ok()`, `to.be.near(n, limit)`, `to.be.a("type")`, `to.throw("part of message")`, `never`, `to.deepEqual(t)`
and `to.contain(item)`.

Keep game rules in pure modules (a `shared/` module or `server/Util/`) and the Roblox calls in a thin service on
top, as `SaveSchema` and `DataService` do. Then the rules get specs.

## Running
- **Anywhere with Node 20+:** `cd tools/cloudcheck && npm ci && npm test` (see its README).
- **In Roblox Studio:** `rojo serve tests.project.json`, connect the Rojo plugin, then in the command bar:

```lua
local run = require(game:GetService("ReplicatedStorage").Tests.StudioRunner)
local s = run(nil, { verbose = true })
print(string.format("%d passed, %d failed, %d skipped", s.passed, s.failed, s.skipped))
```
