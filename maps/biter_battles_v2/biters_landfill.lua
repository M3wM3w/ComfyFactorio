-- biters will landfill tiles on death within a tiny radius
local Public = {}
local vectors = {{0,0}, {1,0}, {0,1}, {-1,0}, {0,-1}}
local math_random = math.random
local math_abs = math.abs

local whitelist = {
	["big-biter"] = true,
	["behemoth-biter"] = true,
}

local function create_particles(surface, position)
	local m = math_random(8, 12)
	local m2 = m * 0.005
	for i = 1, 75, 1 do 
		surface.create_particle({
			name = "stone-particle",
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end
end

function Public.entity_died(entity)
	if not whitelist[entity.name] then return end	
	local position = entity.position
	if math_abs(position.y) < 8 then return true end
	local surface = entity.surface
	for _, vector in pairs(vectors) do
		local tile = surface.get_tile({position.x + vector[1], position.y + vector[2]})
		if tile.collides_with("resource-layer") then
			--create_particles(surface, tile.position)
			surface.set_tiles({{name = "landfill", position = tile.position}})
		end
	end
	return true
end

return Public