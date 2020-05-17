local Public = {}
local Global = require 'utils.global'
local explosives = {}
Global.register(
    explosives,
    function(tbl)
        explosives = tbl
    end
)

local math_abs = math.abs
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_round = math.round
local math_random = math.random
local shuffle_table = table.shuffle_table
local speed = 3
local density = 1
local density_r = density * 0.5
local valid_container_types = {
	["container"] = true,
	["logistic-container"] = true,
	["car"] = true,
	["cargo-wagon"] = true	
}

local function pos_to_key(position)
	return tostring(position.x .. "_" .. position.y)
end

local function get_explosion_name(health)
	if health < 2500 then return "explosion" end
	if health < 25000 then return "big-explosion" end
	return "big-artillery-explosion"
end

local function cell_birth(surface_index, origin_position, origin_tick, position, health)
	local key = pos_to_key(position)

	--Merge cells that are overlapping.
	if explosives.cells[key] then
		explosives.cells[key].health = explosives.cells[key].health + health	
		return
	end

	--Spawn new cell.
	explosives.cells[key] = {
		surface_index = surface_index,
		origin_position = origin_position,
		origin_tick = origin_tick,
		position = {x = position.x, y = position.y},
		spawn_tick = game.tick + speed,
		health = health,
	}
end

local function grow_cell(cell)
	shuffle_table(explosives.vectors)
	local radius = math_floor((game.tick - cell.origin_tick) / 9) + 2
	local positions = {}
	for i = 1, 4, 1 do
		local position = {x = cell.position.x + explosives.vectors[i][1], y = cell.position.y + explosives.vectors[i][2]}			
		if not explosives.cells[pos_to_key(position)] then
			local distance = math_sqrt((cell.origin_position.x - position.x) ^ 2 + (cell.origin_position.y - position.y) ^ 2)
			if distance < radius then
				positions[#positions + 1] = position
			end
		end	
	end
	
	if #positions == 0 then positions[#positions + 1] = {x = cell.position.x + explosives.vectors[1][1], y = cell.position.y + explosives.vectors[1][2]} end
	
	local new_cell_health = math_round(cell.health / #positions, 3) - explosives.damage_decay
	
	--[[
	if new_cell_health > 0 then
		explosives.cells_damage_dealt = explosives.cells_damage_dealt + damage_decay * #positions
	else
		explosives.cells_damage_dealt = explosives.cells_damage_dealt + (new_cell_health + damage_decay) * #positions
	end
	]]
	
	if new_cell_health <= 0 then return end
	
	for _, p in pairs(positions) do
		cell_birth(cell.surface_index, cell.origin_position, cell.origin_tick, p, new_cell_health)
	end
end

local function damage_entity(entity, cell)
	if not entity.valid then return true end
	if not entity.health then return true end
	if entity.health <= 0 then return true end
	if not entity.destructible then return true end
	
	local damage_required = entity.health
	for _ = 1, 4, 1 do
		if damage_required > cell.health then		
			entity.damage(cell.health, "player", "explosion")
			return false
		end		
		local damage_dealt = entity.damage(damage_required, "player", "explosion")		
		cell.health = cell.health - damage_required
		if not entity then return true end
		if not entity.valid then return true end
		if entity.health <= 0 then return true end
		damage_required = math_floor(entity.health * (damage_required / damage_dealt)) + 1
	end										
end

local function damage_area(cell)
	local surface = game.surfaces[cell.surface_index]
	if not surface then return end
	if not surface.valid then return end
	
	if math_random(1,4) == 1 then
		surface.create_entity({name = get_explosion_name(cell.health), position = cell.position})
	end
	
	for _, entity in pairs(surface.find_entities({{cell.position.x - density_r, cell.position.y - density_r},{cell.position.x + density_r, cell.position.y + density_r}})) do
		if not damage_entity(entity, cell) then return end
	end
	
	local tile = surface.get_tile(cell.position)
	if explosives.destructible_tiles[tile.name] then
		local key = pos_to_key(tile.position)
		if not explosives.tiles[key] then explosives.tiles[key] = explosives.destructible_tiles[tile.name] end
		
		if cell.health > explosives.tiles[key] then			
			cell.health = cell.health - explosives.tiles[key]
			explosives.tiles[key] = nil
			if math_abs(tile.position.y) < surface.map_gen_settings.height * 0.5 and math_abs(tile.position.x) < surface.map_gen_settings.width * 0.5 then
				surface.set_tiles({{name = "landfill", position = tile.position}}, true)
			end
		else
			explosives.tiles[key] = explosives.tiles[key] - cell.health
			return
		end		
	end
	
	return true
end

local function life_cycle(cell)
	if not damage_area(cell) then return end
	grow_cell(cell)
end

local function tick(event)
	for key, cell in pairs(explosives.cells) do
		if cell.spawn_tick < game.tick then
			life_cycle(cell)
			explosives.cells[key] = nil
		end
	end
	if game.tick % 216000 == 0 then explosives.tiles = {} end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if not valid_container_types[entity.type] then return end
	if explosives.surface_whitelist then
		if not explosives.surface_whitelist[entity.surface.name] then
			return
		end
	end
	
	local inventory = defines.inventory.chest
	if entity.type == "car" then inventory = defines.inventory.car_trunk end
	
	local i = entity.get_inventory(inventory)
	local amount = i.get_item_count("explosives")
	if not amount then return end
	if amount < 1 then return end
	
	cell_birth(entity.surface.index, {x = entity.position.x, y = entity.position.y}, game.tick, {x = entity.position.x, y = entity.position.y}, amount * explosives.damage_per_explosive)
end

function Public.reset()
	explosives.cells = {}
	explosives.tiles = {}
	if not explosives.vectors then explosives.vectors = {{density, 0}, {density * -1, 0}, {0, density}, {0, density * -1}} end
	if not explosives.damage_per_explosive then explosives.damage_per_explosive = 500 end
	if not explosives.damage_decay then explosives.damage_decay = 10 end
	if not explosives.destructible_tiles then explosives.destructible_tiles = {} end
end

function Public.set_destructible_tile(tile_name, health)
	explosives.destructible_tiles[tile_name] = health
end

function Public.set_surface_whitelist(list)
	explosives.surface_whitelist = list
end

function Public.get_table()
	return explosives
end

local function on_init()
	Public.reset()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(speed, tick)
Event.add(defines.events.on_entity_died, on_entity_died)

return Public