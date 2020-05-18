-- biters will landfill a tile on death within a certain radius

local r = 6
local vectors = {{0,0}, {1,0}, {0,1}, {-1,0}, {0,-1}}
local math_random = math.random

local function create_particles(surface, position)
	local m = math_random(8, 12)
	local m2 = m * 0.005
	for i = 1, 75, 1 do 
		surface.create_entity({
			name = "stone-particle",
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end
end

local function coord_string(x, y)
	local str = tostring(x) .. "_"
	str = str .. tostring(y)
	return str
end

local function get_replacement_tile(surface, position)	
	for _, vector in pairs(vectors) do
		local tile = surface.get_tile({position.x + vector[1], position.y + vector[2]})
		if not tile.collides_with("resource-layer") then return tile.name end
	end
	return "grass-1"
end

local function landfill(surface, entity)
	local position = {x = math.floor(entity.position.x), y = math.floor(entity.position.y)}
	local pos_str = coord_string(position.x, position.y)		
	if global.biters_landfill_on_death[pos_str] then return end		
	local tiles = surface.find_tiles_filtered({name = {"water", "deepwater"}, area = {{position.x - r, position.y - r},{position.x + r, position.y + r}}})
	if #tiles == 0 then global.biters_landfill_on_death[pos_str] = true return end
	local p = tiles[math_random(1, #tiles)].position
	surface.set_tiles({{name = get_replacement_tile(surface, position), position = p}})
	create_particles(entity.surface, {p.x + 0.5, p.y + 0.5})
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end	
	if entity.type ~= "unit" then return end	
	landfill(entity.surface, entity)
end

local function on_init()
	global.biters_landfill_on_death = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_entity_died, on_entity_died)