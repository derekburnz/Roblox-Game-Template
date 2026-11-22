--!strict
return function()
	local SaveSchema = require(game:GetService("ReplicatedStorage").Shared.SaveSchema)

	describe("SaveSchema.migrate", function()
		it("gives a new player the template", function()
			local save = SaveSchema.migrate(nil, 100)
			expect(save).to.be.ok()
			expect((save :: any).version).to.equal(SaveSchema.VERSION)
			expect((save :: any).createdAt).to.equal(100)
		end)

		it("fills fields an old save lacks and keeps the rest", function()
			local save =
				SaveSchema.migrate({ version = SaveSchema.VERSION, coins = 42 }, 100) :: any
			expect(save.coins).to.equal(42)
			expect(save.funnel).to.be.a("table")
			expect(save.playSeconds).to.equal(0)
		end)

		it("refuses a save newer than this server", function()
			local save, reason = SaveSchema.migrate({ version = SaveSchema.VERSION + 1 }, 100)
			expect(save).to.equal(nil)
			expect(reason).to.be.a("string")
		end)
	end)
end
