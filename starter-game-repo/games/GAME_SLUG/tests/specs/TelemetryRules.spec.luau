--!strict
return function()
	local TelemetryRules = require(game:GetService("ReplicatedStorage").Shared.TelemetryRules)

	describe("TelemetryRules", function()
		it("takes lower case names only", function()
			expect(TelemetryRules.validName("shop_opened")).to.equal(true)
			expect(TelemetryRules.validName("ShopOpened")).to.equal(false)
			expect(TelemetryRules.validName("")).to.equal(false)
		end)

		it("refuses a 4th custom field, which Roblox would drop", function()
			local fields, reason = TelemetryRules.fields({ "a", "b", "c", "d" })
			expect(fields).to.equal(nil)
			expect(reason).to.be.a("string")
		end)

		it("names the fields CustomField01 to 03 and cleans them", function()
			local fields = TelemetryRules.fields({ "phone", "tier<2>" }) :: any
			expect(fields.CustomField01).to.equal("phone")
			expect(fields.CustomField02).to.equal("tier2")
			expect(fields.CustomField03).to.equal(nil)
		end)
	end)
end
