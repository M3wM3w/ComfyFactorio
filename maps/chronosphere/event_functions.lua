local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Public_event = {}

local tick_tack_trap = require "functions.tick_tack_trap"
local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"

local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil

local function get_ore_amount()
	local objective = Chrono_table.get_table()

	local amount = Balance.Base_ore_loot_yield(objective.chronojumps) * objective.planet[1].ore_richness.factor
	if amount > 600 then amount = 600 end
	amount = math_random(math_floor(amount * 0.7), math_floor(amount * 1.3))
	return amount
end

local function reward_ores(amount, mined_loot, surface, player, entity)
	local a = 0
	if player then a = player.insert {name = mined_loot, count = amount} end
	amount = amount - a
	if amount > 0 then
		if amount >= 50 then
			for i = 1, math_floor(amount / 50), 1 do
				local e = surface.create_entity{name = "item-on-ground", position = entity.position, stack = {name = mined_loot, count = 50}}
				e.to_be_looted = true
				amount = amount - 50
			end
		end
		if amount > 0 then
			surface.spill_item_stack(entity.position, {name = mined_loot, count = amount},true)
		end
	end
end

function Public_event.biters_chew_rocks_faster(event)
	if event.entity.force.index ~= 3 then return end --Neutral Force
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index ~= 2 then return end --Enemy Force
	event.entity.health = event.entity.health - event.final_damage_amount * 5
end

function Public_event.isprotected(entity)
	local objective = Chrono_table.get_table()
	if entity.surface.name == "cargo_wagon" then return true end
	local protected = {objective.locomotive, objective.locomotive_cargo[1], objective.locomotive_cargo[2], objective.locomotive_cargo[3]}
	for i = 1, #objective.comfychests,1 do
		table.insert(protected, objective.comfychests[i])
	end
	for i = 1, #protected do
    if protected[i] == entity then
      return true
    end
  end
	return false
end

function Public_event.trap(entity, trap)
	if trap then
		tick_tack_trap(entity.surface, entity.position)
		tick_tack_trap(entity.surface, {x = entity.position.x + math_random(-2,2), y = entity.position.y + math_random(-2,2)})
		return
	end
	if math_random(1,256) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	if math_random(1,128) == 1 then unearthing_worm(entity.surface, entity.surface.find_non_colliding_position("big-worm-turret",entity.position,5,1)) end
	if math_random(1,64) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end
end

function Public_event.lava_planet(event)
	local objective = Chrono_table.get_table()
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	if player.surface.name == "cargo_wagon" then return end
	local safe = {"stone-path", "concrete", "hazard-concrete-left", "hazard-concrete-right", "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right"}
	local pavement = player.surface.get_tile(player.position.x, player.position.y)
	for i = 1, 7, 1 do
		if pavement.name == safe[i] then return end
	end
	if not objective.flame_boots[player.index].steps then objective.flame_boots[player.index].steps = {} end
	local steps = objective.flame_boots[player.index].steps

	local elements = #steps

	steps[elements + 1] = {x = player.position.x, y = player.position.y}

	if elements > 10 then
		player.surface.create_entity({name = "fire-flame", position = steps[elements - 1], })
		for i = 1, elements, 1 do
			steps[i] = steps[i+1]
		end
		steps[elements + 1] = nil
	end
end

function Public_event.shred_simple_entities(entity)
	--game.print(entity.name)
	if game.forces["enemy"].evolution_factor < 0.25 then return end
	local simple_entities = entity.surface.find_entities_filtered({type = {"simple-entity", "tree"}, area = {{entity.position.x - 3, entity.position.y - 3},{entity.position.x + 3, entity.position.y + 3}}})
	if #simple_entities == 0 then return end
	for i = 1, #simple_entities, 1 do
		if not simple_entities[i] then break end
		if simple_entities[i].valid then
			simple_entities[i].die("enemy", simple_entities[i])
		end
	end
end

function Public_event.spawner_loot(surface, position)
	local objective = Chrono_table.get_table()
	if math_random(1,20) == 1 then
		surface.spill_item_stack(position, {name = "railgun-dart", count = math_random(1, 1 + objective.chronojumps)}, true)
	end
end

function Public_event.choppy_loot(event)
	local entity = event.entity
	local choppy_entity_yield = {
			["tree-01"] = {"iron-ore"},
			["tree-02-red"] = {"copper-ore"},
			["tree-04"] = {"coal"},
			["tree-08-brown"] = {"stone"}
		}
	if choppy_entity_yield[entity.name] then
		if event.buffer then event.buffer.clear() end
		if not event.player_index then return end
		local amount = math_ceil(math_ceil(get_ore_amount() / 5))
		local second_item_amount = math_random(1,3)
		local second_item = "wood"
		local main_item = choppy_entity_yield[entity.name][math_random(1,#choppy_entity_yield[entity.name])]

		entity.surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "+" .. amount .. " [item=" .. main_item .. "] +" .. second_item_amount .. " [item=" .. second_item .. "]",
			color = {r=0.8,g=0.8,b=0.8}
		})

		local player = game.players[event.player_index]
		reward_ores(amount, main_item, entity.surface, player, player)

		local inserted_count = player.insert({name = second_item, count = second_item_amount})
		second_item_amount = second_item_amount - inserted_count
		if second_item_amount > 0 then
			entity.surface.spill_item_stack(entity.position,{name = second_item, count = second_item_amount}, true)
		end
	end
end

function Public_event.rocky_loot(event)
	local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
	local player = game.players[event.player_index]
	surface.spill_item_stack(player.position,{name = "raw-fish", count = math_random(1,3)},true)
	local amount = math_floor(get_ore_amount())
	local rock_mining = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore", "stone", "stone", "coal", "coal"}
	local mined_loot = rock_mining[math_random(1,#rock_mining)]
	surface.create_entity({
		name = "flying-text",
		position = {player.position.x, player.position.y - 0.5},
		text = "+" .. amount .. " [img=item/" .. mined_loot .. "]",
		color = {r=0.98, g=0.66, b=0.22}
	})
	reward_ores(amount, mined_loot, surface, player, player)
end

function Public_event.swamp_loot(event)
	local objective = Chrono_table.get_table()
	local ore_yield = {
		["behemoth-biter"] = 5,
		["behemoth-spitter"] = 5,
		["behemoth-worm-turret"] = 6,
		["big-biter"] = 3,
		["big-spitter"] = 3,
		["big-worm-turret"] = 4,
		["biter-spawner"] = 10,
		["medium-biter"] = 2,
		["medium-spitter"] = 2,
		["medium-worm-turret"] = 3,
		["small-biter"] = 1,
		["small-spitter"] = 1,
		["small-worm-turret"] = 2,
		["spitter-spawner"] = 10,
	}
	local surface = game.surfaces[objective.active_surface_index]
	local amount = math_floor(get_ore_amount() / 10)
	if ore_yield[event.entity.name] then
		amount = math_floor((get_ore_amount() * ore_yield[event.entity.name]) / 10)
	end
	if amount > 50 then amount = 50 end

	local rock_mining = {"iron-ore", "iron-ore", "coal"}
	local mined_loot = rock_mining[math_random(1,#rock_mining)]
	--reward_ores(amount, mined_loot, surface, nil, event.entity)
	if amount < 5 then
		surface.spill_item_stack(event.entity.position,{name = mined_loot, count = amount}, true)
	else
		surface.create_entity{name = "item-on-ground", position = event.entity.position, stack = {name = mined_loot, count = amount}}
	end

	event.entity.surface.create_entity({
		name = "flying-text",
		position = event.entity.position,
		text = "+" .. amount .. " [img=item/" .. mined_loot .. "]",
		color = {r=0.7,g=0.8,b=0.4}
	})

	--surface.spill_item_stack(event.entity.position,{name = mined_loot, count = amount}, true)
end

function Public_event.danger_silo(entity)
	local objective = Chrono_table.get_table()
	if objective.planet[1].type.id == 19 then
		if objective.dangers and #objective.dangers > 1 then
	    for i = 1, #objective.dangers, 1 do
	      if entity == objective.dangers[i].silo then
					game.print({"chronosphere.message_silo", Balance.nukes_looted_per_silo(Difficulty.get().difficulty_vote_value)}, {r=0.98, g=0.66, b=0.22})
					objective.dangers[i].destroyed = true
					objective.dangers[i].silo = nil
					objective.dangers[i].speaker.destroy()
					objective.dangers[i].combinator.destroy()
					objective.dangers[i].solar.destroy()
					objective.dangers[i].acu.destroy()
					objective.dangers[i].pole.destroy()
					rendering.destroy(objective.dangers[i].text)
					rendering.destroy(objective.dangers[i].timer)
					objective.dangers[i].text = -1
					objective.dangers[i].timer = -1
				end
	    end
	  end
	end
end

function Public_event.biter_immunities(event)
	local objective = Chrono_table.get_table()
	local planet = objective.planet[1].type.id
	if event.damage_type.name == "fire" then
		if planet == 14 then --lava planet
			event.entity.health = event.entity.health + event.final_damage_amount
			local fire = event.entity.stickers
			if fire and #fire > 0 then
				for i = 1, #fire, 1 do
					if fire[i].sticked_to == event.entity and fire[i].name == "fire-sticker" then fire[i].destroy() break end
				end
			end
		-- else -- other planets
		-- 	event.entity.health = math_floor(event.entity.health + event.final_damage_amount - (event.final_damage_amount / (1 + 0.02 * Difficulty.get().difficulty_vote_value * objective.chronojumps)))
		end
	elseif event.damage_type.name == "poison" then
		if planet == 18 then --swamp planet
			event.entity.health = event.entity.health + event.final_damage_amount
		end
	end
end

function Public_event.flamer_nerfs()
	local objective = Chrono_table.get_table()
	local difficulty = Difficulty.get().difficulty_vote_value
	
	local flame_researches = {
		[1] = {name = "refined-flammables-1", bonus = 0.2},
		[2] = {name = "refined-flammables-2", bonus = 0.2},
		[3] = {name = "refined-flammables-3", bonus = 0.2},
		[4] = {name = "refined-flammables-4", bonus = 0.3},
		[5] = {name = "refined-flammables-5", bonus = 0.3},
		[6] = {name = "refined-flammables-6", bonus = 0.4},
		[7] = {name = "refined-flammables-7", bonus = 0.2}
	}

	local flamer_power = 0
	for i = 1, 6, 1 do
		if game.forces.player.technologies[flame_researches[i].name].researched then
			flamer_power = flamer_power + flame_researches[i].bonus
		end
	end
	flamer_power = flamer_power + (game.forces.player.technologies[flame_researches[7].name].level - 7) * 0.2

	game.forces.player.set_ammo_damage_modifier("flamethrower", flamer_power - Balance.flamers_nerfs_size(objective.chronojumps, difficulty))
	game.forces.player.set_turret_attack_modifier("flamethrower-turret", flamer_power - Balance.flamers_nerfs_size(objective.chronojumps, difficulty))
end

local mining_researches = {
	-- these already give .1 productivity so we're only adding .1 to get to 20%
	["mining-productivity-1"] = {bonus_productivity = .1, bonus_mining_speed = .2, bonus_inventory = 10},
	["mining-productivity-2"] = {bonus_productivity = .1, bonus_mining_speed = .2, bonus_inventory = 10},
	["mining-productivity-3"] = {bonus_productivity = .1, bonus_mining_speed = .2, bonus_inventory = 10},
	["mining-productivity-4"] = {bonus_productivity = .1, bonus_mining_speed = .2, bonus_inventory = 10, infinite = true, infinite_level = 4},
}

function Public_event.mining_buffs(event)

	if event == nil then
		-- initialization/reset call
		game.forces.player.mining_drill_productivity_bonus = game.forces.player.mining_drill_productivity_bonus + 1
		game.forces.player.manual_mining_speed_modifier = game.forces.player.manual_mining_speed_modifier + 1
		return
	end

	if mining_researches[event.research.name] == nil then return end
	
	local tech = mining_researches[event.research.name]

	if tech.bonus_productivity then
		game.forces.player.mining_drill_productivity_bonus = game.forces.player.mining_drill_productivity_bonus + tech.bonus_productivity
	end

	if tech.bonus_mining_speed then
		game.forces.player.manual_mining_speed_modifier = game.forces.player.manual_mining_speed_modifier + tech.bonus_mining_speed
	end

	if tech.bonus_inventory then
		game.forces.player.character_inventory_slots_bonus = game.forces.player.character_inventory_slots_bonus + tech.bonus_inventory
	end
end

function Public_event.on_technology_effects_reset(event)
	local objective = Chrono_table.get_table()
	if event.force.name == "player" then
		game.forces.player.character_inventory_slots_bonus = game.forces.player.character_inventory_slots_bonus + objective.invupgradetier * 10
		game.forces.player.character_loot_pickup_distance_bonus = game.forces.player.character_loot_pickup_distance_bonus + objective.pickupupgradetier

		local fake_event = {}
		Public_event.mining_buffs(nil)
		for tech, bonuses in pairs(mining_researches) do
			tech = game.forces.player.technologies[tech]
			if tech.researched == true or bonuses.infinite == true then
				fake_event.research = tech
				if bonuses.infinite and bonuses.infinite_level and tech.level > bonuses.infinite_level then
					for i = bonuses.infinite_level, tech.level - 1 do
						Public_event.mining_buffs(fake_event)
					end
				else
					Public_event.mining_buffs(fake_event)
				end
			end
		end
	end
end

return Public_event
