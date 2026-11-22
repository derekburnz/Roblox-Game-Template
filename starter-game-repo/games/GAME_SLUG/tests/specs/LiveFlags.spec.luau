--!strict
return function()
	local LiveFlags = require(game:GetService("ReplicatedStorage").Shared.LiveFlags)

	describe("LiveFlags.resolve", function()
		it("keeps a plain switch on unless the store says false", function()
			expect(LiveFlags.resolve("someKillSwitch", nil)).to.equal(true)
			expect(LiveFlags.resolve("someKillSwitch", "junk")).to.equal(true)
			expect(LiveFlags.resolve("someKillSwitch", false)).to.equal(false)
		end)

		it("keeps an off-by-default switch off unless the store says true", function()
			expect(LiveFlags.resolve("exampleFeature", nil)).to.equal(false)
			expect(LiveFlags.resolve("exampleFeature", 1)).to.equal(false)
			expect(LiveFlags.resolve("exampleFeature", true)).to.equal(true)
		end)

		it("lists every off-by-default key in KEYS", function()
			for key in LiveFlags.OFF_BY_DEFAULT do
				expect(table.find(LiveFlags.KEYS, key) ~= nil).to.equal(true)
			end
		end)
	end)
end
