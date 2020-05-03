local math_random = math.random
local Public = {}

function Public.shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end


function Public.raffle(values,weights) --arguments of the form {[1] = a, [2] = b, ...} and {[1] = a_weight, [2] = b_weight, ...} or just {a,b,c,...} and {1,2,3...}
	assert(#values == #weights)

	local total_weight = 0
	for i,w in pairs(weights) do
		assert(values[i])
		if w > 0 then
			total_weight = total_weight + w
		end
	end
	assert(total_weight > 0)

	local cumulative_probability = 0
	local rng = math_random() --0 to 1
	for i,v in pairs(values) do
		cumulative_probability = cumulative_probability + weights[i] / total_weight
		if rng <= cumulative_probability then return v end
	end
end

return Public