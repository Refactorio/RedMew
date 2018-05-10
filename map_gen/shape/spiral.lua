return function(x, y, world)
	local distance = math.sqrt(x * x + y * y)
	if distance > 128 then
		local angle = 180 + math.deg(math.atan2(x, y))

		local offset = distance
		if angle ~= 0 then
			offset = offset + angle / 3.75
		end
		--if angle ~= 0 then offset = offset + angle /1.33333333 end

		return offset % 96 >= 48
	end

	return true
end
