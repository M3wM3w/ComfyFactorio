-- all the kabooms --  by mewmew

local event = require 'utils.event'
local math_random = math.random

local valid_container_types = {
	["container"] = true,
	["logistic-container"] = true,
	["car"] = true,
	["cargo-wagon"] = true	
}

local projectile_types = {
	["explosives"] = {name = "grenade", count = 0.5, max_range = 32, tick_speed = 1},
	["land-mine"] = {name = "grenade", count = 1, max_range = 32, tick_speed = 1},
	
	["grenade"] = {name = "grenade", count = 1, max_range = 40, tick_speed = 1},
	["cluster-grenade"] = {name = "cluster-grenade", count = 1, max_range = 40, tick_speed = 3},
	
	["artillery-shell"] = {name = "artillery-projectile", count = 1, max_range = 60, tick_speed = 3},
	
	["cannon-shell"] = {name = "cannon-projectile", count = 1, max_range = 60, tick_speed = 1},	
	["explosive-cannon-shell"] = {name = "explosive-cannon-projectile", count = 1, max_range = 60, tick_speed = 1},
	["explosive-uranium-cannon-shell"] = {name = "explosive-uranium-cannon-projectile", count = 1, max_range = 60, tick_speed = 1},
	["uranium-cannon-shell"] = {name = "uranium-cannon-projectile", count = 1, max_range = 60, tick_speed = 1},
	
	["atomic-bomb"] = {name = "atomic-rocket", count = 1, max_range = 80, tick_speed = 20},
	["explosive-rocket"] = {name = "explosive-rocket", count = 1, max_range = 48, tick_speed = 1},
	["rocket"] = {name = "rocket", count = 1, max_range = 48, tick_speed = 1},
	
	["flamethrower-ammo"] = {name = "flamethrower-fire-stream", count = 4, max_range = 28, tick_speed = 1},
	["crude-oil-barrel"] = {name = "flamethrower-fire-stream", count = 3, max_range = 24, tick_speed = 1},
	["petroleum-gas-barrel"] = {name = "flamethrower-fire-stream", count = 4, max_range = 24, tick_speed = 1},
	["light-oil-barrel"] = {name = "flamethrower-fire-stream", count = 4, max_range = 24, tick_speed = 1},
	["heavy-oil-barrel"] = {name = "flamethrower-fire-stream", count = 4, max_range = 24, tick_speed = 1},
	
	["sulfuric-acid-barrel"] = {name = "acid-stream-spitter-big", count = 3, max_range = 16, tick_speed = 1, force = "enemy"},
	["lubricant-barrel"] = {name = "acid-stream-spitter-big", count = 3, max_range = 16, tick_speed = 1},
	
	["railgun-dart"] = {name = "railgun-beam", count = 5, max_range = 40, tick_speed = 5},
	
	["shotgun-shell"] = {name = "shotgun-pellet", count = 16, max_range = 24, tick_speed = 1},
	["piercing-shotgun-shell"] = {name = "piercing-shotgun-pellet", count = 16, max_range = 24, tick_speed = 1},
	
	["firearm-magazine"] = {name = "shotgun-pellet", count = 16, max_range = 24, tick_speed = 1},
	["piercing-rounds-magazine"] = {name = "piercing-shotgun-pellet", count = 16, max_range = 24, tick_speed = 1},
	["uranium-rounds-magazine"] = {name = "piercing-shotgun-pellet", count = 32, max_range = 24, tick_speed = 1},
	
	["cliff-explosives"] = {name = "cliff-explosives", count = 1, max_range = 48, tick_speed = 2},
}

local function create_projectile(surface, name, position, force, target, max_range)
	surface.create_entity({	
		name = name,
		position = position,
		force = force,
		source = position,
		target = target,
		max_range = max_range, 
		speed = 0.4
	})	
end

local function get_near_range(range)
	local r = math_random(1, math.floor(range * 2))
	for i = 1, 2, 1 do
		local r2 = math_random(1, math.floor(range * 2))
		if r2 < r then r = r2 end
	end
	return r
end

local function get_near_coord_modifier(range)
	local coord = {x = (range * -1) + math_random(0, range * 2), y = (range * -1) + math_random(0, range * 2)}
	for i = 1, 5, 1 do
		local new_coord = {x = (range * -1) + math_random(0, range * 2), y = (range * -1) + math_random(0, range * 2)}
		if new_coord.x^2 + new_coord.y^2 < coord.x^2 + coord.y^2 then
			coord = new_coord
		end
	end
	return coord
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if not valid_container_types[entity.type] then return end
	
	local inventory = defines.inventory.chest
	if entity.type == "car" then inventory = defines.inventory.car_trunk end
	local i = entity.get_inventory(inventory)
	
	for key, projectile in pairs(projectile_types) do
		local amount = i.get_item_count(key)
		local force = entity.force.name
		if projectile.force then force = projectile.force end
		local projectile_count = amount * projectile.count
		
		if amount > 0 then			
			for t = 0, amount * projectile.tick_speed, projectile.tick_speed do		
				if not global.dangerous_on_tick_schedule[game.tick + t + 1] then global.dangerous_on_tick_schedule[game.tick + t + 1] = {} end				
				
				for c = 1, math.ceil(projectile.count), 1 do
					local coord_modifier = get_near_coord_modifier(projectile.max_range)	
					global.dangerous_on_tick_schedule[game.tick + t + 1][#global.dangerous_on_tick_schedule[game.tick + t + 1] + 1] = {
						func = create_projectile,
						args = {
							entity.surface,
							projectile.name,
							{x = entity.position.x, y = entity.position.y},
							force,
							{entity.position.x + coord_modifier.x, entity.position.y + coord_modifier.y},
							get_near_range(projectile.max_range)
						}
					}
					projectile_count = projectile_count - 1
				end
				
				if projectile_count <= 0 then break end
			end
		end
	end
end

local function on_tick()	
	if not global.dangerous_on_tick_schedule[game.tick] then return end	
	for _, schedule in pairs(global.dangerous_on_tick_schedule[game.tick]) do
		schedule.func(unpack(schedule.args))		
	end		
	global.dangerous_on_tick_schedule[game.tick] = nil
end

local function on_init(event)
	if not global.dangerous_on_tick_schedule then global.dangerous_on_tick_schedule = {} end
end

event.on_init(on_init)
event.add(defines.events.on_tick, on_tick)	
event.add(defines.events.on_entity_died, on_entity_died)
