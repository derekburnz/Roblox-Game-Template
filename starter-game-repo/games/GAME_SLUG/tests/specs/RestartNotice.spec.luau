--!strict
return function()
	local RestartNotice = require(game:GetService("ReplicatedStorage").Shared.RestartNotice)

	local function decode(text: string): unknown
		if text == '{"kind":"restart","seconds":120}' then
			return { kind = "restart", seconds = 120 }
		end
		error("not JSON")
	end

	describe("RestartNotice", function()
		it("reads the countdown's message", function()
			expect(RestartNotice.parse('{"kind":"restart","seconds":120}', decode)).to.equal(120)
			expect(RestartNotice.parse({ kind = "restart", seconds = 0 }, decode)).to.equal(0)
		end)

		it("ignores anything else", function()
			expect(RestartNotice.parse("nonsense", decode)).to.equal(nil)
			expect(RestartNotice.parse({ kind = "other", seconds = 5 }, decode)).to.equal(nil)
			expect(RestartNotice.parse({ kind = "restart", seconds = -1 }, decode)).to.equal(nil)
			expect(RestartNotice.parse({ kind = "restart", seconds = 1.5 }, decode)).to.equal(nil)
		end)

		it("says minutes, seconds and now in calm words", function()
			expect(RestartNotice.text(600)).to.contain("10 minutes")
			expect(RestartNotice.text(30)).to.contain("30 seconds")
			expect(RestartNotice.text(0)).to.contain("Updating now")
			expect(RestartNotice.kind(600)).to.equal("info")
			expect(RestartNotice.kind(30)).to.equal("warning")
		end)
	end)
end
