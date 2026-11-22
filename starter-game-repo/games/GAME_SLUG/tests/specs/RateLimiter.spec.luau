--!strict
return function()
	local RateLimiter = require(game:GetService("ServerScriptService").Server.Util.RateLimiter)

	describe("RateLimiter", function()
		it("allows a burst, then refills over time", function()
			local now = 0
			local limiter = RateLimiter.new(2, 1, function()
				return now
			end)
			expect(limiter:allow("p")).to.equal(true)
			expect(limiter:allow("p")).to.equal(true)
			expect(limiter:allow("p")).to.equal(false)
			now = 0.5
			expect(limiter:allow("p")).to.equal(true)
			expect(limiter:allow("p")).to.equal(false)
		end)

		it("keeps each key apart and forgets on request", function()
			local now = 0
			local limiter = RateLimiter.new(1, 1, function()
				return now
			end)
			expect(limiter:allow("a")).to.equal(true)
			expect(limiter:allow("b")).to.equal(true)
			expect(limiter:allow("a")).to.equal(false)
			limiter:forget("a")
			expect(limiter:allow("a")).to.equal(true)
		end)
	end)
end
