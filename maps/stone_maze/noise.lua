local simplex_noise = require "utils.simplex_noise".d2

local noises = {
	["trees_01"] = {{modifier = 0.03, weight = 1}, {modifier = 0.05, weight = 0.3}, {modifier = 0.1, weight = 0.05}},
	["scrap_01"] = {{modifier = 0.04, weight = 1}, {modifier = 0.06, weight = 0.3}, {modifier = 0.08, weight = 0.1}}
}

local function get_noise(name, pos, seed)
	local noise = 0
	local x = pos.x
	local y = pos.y
	if not x then x = pos[1] end
	if not y then y = pos[2] end
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(x * n.modifier, y * n.modifier, seed) * n.weight
		seed = seed + 10000
	end
	return noise
end

return get_noise