ncdk.Fraction = {}
local Fraction = ncdk.Fraction

ncdk.Fraction_metatable = {}
local Fraction_metatable = ncdk.Fraction_metatable
Fraction_metatable.__index = Fraction

Fraction.new = function(self, numerator, denominator, maximumDenominator)
	local fraction = {}
	
	fraction.numerator = numerator or 0
	fraction.denominator = denominator or 1
	fraction.maximumDenominator = maximumDenominator
	
	if fraction.numerator % 1 ~= 0 or fraction.denominator % 1 ~= 0 or fraction.denominator == 0 then
		error("invalid fraction\n" ..
			"n -> " .. type(fraction.numerator) .. " -> " .. tostring(fraction.numerator) .. "\n" ..
			"d -> " .. type(fraction.denominator) .. " -> " .. tostring(fraction.denominator)
		)
	end
	
	fraction.number = fraction.numerator / fraction.denominator
	
	setmetatable(fraction, Fraction_metatable)
	
	fraction:reduce()
	
	return fraction
end

Fraction.fromString = function(self, line)
	local numerator, denominator = line:match("^(%d+)/(%d+)$")
	
	if not numerator then
		error("invalid fraction detection: (" .. line .. ")")
	end
	
	return ncdk.Fraction:new(tonumber(numerator), tonumber(denominator))
end

Fraction.fromNumber = function(self, number, accuracy)
	local sign = number / math.abs(number)
	local number = math.floor(math.abs(number) * accuracy) / accuracy
	local decimalPart = number % 1
	if decimalPart == 0 then
		return ncdk.Fraction:new(number, 1)
	else
		return ncdk.Fraction:new(sign * math.floor(number * accuracy), accuracy)
	end
end

Fraction.reduce = function(self)
	local reduceFactor = gcd(self.numerator, self.denominator)
	
	self.numerator = self.numerator / reduceFactor
	self.denominator = self.denominator / reduceFactor
end

Fraction.tonumber = function(self)
	return self.number
end

Fraction_metatable.__tostring = function(self)
	return self.numerator .. "/" .. self.denominator
end

Fraction_metatable.__unm = function(fa)
	fraction = Fraction:new(
		-fa.numerator,
		fa.denominator
	)
	
	return fraction
end

local getFractions = function(fa, fb)
	if type(fa) == "number" or type(fa) == "string" then
		fa = Fraction:new(tonumber(fa), 1)
	end
	if type(fb) == "number" or type(fb) == "string" then
		fb = Fraction:new(tonumber(fb), 1)
	end
	
	return fa, fb
end

Fraction_metatable.__add = function(fa, fb)
	fa, fb = getFractions(fa, fb)
	
	fraction = Fraction:new(
		fa.numerator * fb.denominator + fa.denominator * fb.numerator,
		fa.denominator * fb.denominator
	)
	
	return fraction
end

Fraction_metatable.__sub = function(fa, fb)
	fa, fb = getFractions(fa, fb)
	
	fraction = Fraction:new(
		fa.numerator * fb.denominator - fa.denominator * fb.numerator,
		fa.denominator * fb.denominator
	)
	
	return fraction
end

Fraction_metatable.__mul = function(fa, fb)
	fa, fb = getFractions(fa, fb)
	
	fraction = Fraction:new(
		fa.numerator * fb.numerator,
		fa.denominator * fb.denominator
	)
	
	return fraction
end

Fraction_metatable.__div = function(fa, fb)
	fa, fb = getFractions(fa, fb)
	
	fraction = Fraction:new(
		fa.numerator * fb.denominator,
		fa.denominator * fb.numerator
	)
	
	return fraction
end

Fraction_metatable.__mod = function(fa, fb)
end

Fraction_metatable.__pow = function(fa, fb)
end

Fraction_metatable.__concat = function(fa, fb)	
	return tostring(fa) .. tostring(fb)
end

Fraction.floor = function(self)
	local numerator = self.numerator
	
	while numerator % self.denominator ~= 0 do
		numerator = numerator - 1
	end
	
	return numerator / self.denominator
end

Fraction.ceil = function(self)
	local numerator = self.numerator
	
	while numerator % self.denominator ~= 0 do
		numerator = numerator + 1
	end
	
	return numerator / self.denominator
end

Fraction_metatable.__eq = function(fa, fb)
	return fa.numerator * fb.denominator == fa.denominator * fb.numerator
end

Fraction_metatable.__lt = function(fa, fb)
	return fa.numerator * fb.denominator < fa.denominator * fb.numerator
end

Fraction_metatable.__le = function(fa, fb)
	return fa.numerator * fb.denominator <= fa.denominator * fb.numerator
end

gcd = function(a, b)
	local a, b = math.abs(a), math.abs(b)
	a, b = math.max(a, b), math.min(a, b)
	
	if a == b then
		return a
	end
	if a == 1 or b == 1 or a == 0 or b == 0 then
		return 1
	end
	if a % b == 0 then
		return b
	end
	
	return gcd(b, a % b)
end

assert(gcd(1, 1) == 1)
assert(gcd(1, 0) == 1)
assert(gcd(1, 2) == 1)
assert(gcd(2, 3) == 1)
assert(gcd(24, 16) == 8)