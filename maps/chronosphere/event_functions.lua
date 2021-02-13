local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Chrono = require "maps.chronosphere.chrono"
local Upgrades = require "maps.chronosphere.upgrades"
local Public = {}

local tick_tack_trap = require "functions.tick_tack_trap"
local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"

local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil

local function get_ore_amount(scrap)
	local objective = Chrono_table.get_table()
	local scaling = (game.forces.player.mining_drill_productivity_bonus - 1) / 2
	local amount = Balance.Base_ore_loot_yield(objective.chronojumps, scrap) * (1 + scaling)
	if not scrap then amount = amount * objective.world.ores.factor end
	if amount > 500 then amount = 500 end
	amount = math_random(math_floor(amount * 0.7), math_floor(amount * 1.3))
	if amount < 1 then amount = 1 end
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
				if e and e.valid then e.to_be_looted = true end
				amount = amount - 50
			end
		end
		if amount > 0 then
			if amount < 5 then
				surface.spill_item_stack(entity.position,{name = mined_loot, count = amount}, true)
			else
				local e = surface.create_entity{name = "item-on-ground", position = entity.position, stack = {name = mined_loot, count = amount}}
				if e and e.valid then e.to_be_looted = true end
			end
		end
	end
end

local function flying_text(surface, position, text, color)
	surface.create_entity({
		name = "flying-text",
		position = {position.x, position.y - 0.5},
		text = text,
		color = color
	})
end

function Public.biters_chew_rocks_faster(event)
	if event.entity.force.index ~= 3 then return end --Neutral Force
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index ~= 2 then return end --Enemy Force
	event.entity.health = event.entity.health - event.final_damage_amount * 5
end

function Public.isprotected(entity)
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

function Public.trap(entity, trap)
	if trap then
		tick_tack_trap(entity.surface, entity.position)
		tick_tack_trap(entity.surface, {x = entity.position.x + math_random(-2,2), y = entity.position.y + math_random(-2,2)})
		return
	end
	if math_random(1,256) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	if math_random(1,128) == 1 then unearthing_worm(entity.surface, entity.surface.find_non_colliding_position("big-worm-turret",entity.position,5,1)) end
	if math_random(1,64) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end
end

function Public.lava_planet(event)
	local playertable = Chrono_table.get_player_table()
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	if player.surface.name == "cargo_wagon" then return end
	local safe = {"stone-path", "concrete", "hazard-concrete-left", "hazard-concrete-right", "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right"}
	local pavement = player.surface.get_tile(player.position.x, player.position.y)
	for i = 1, 7, 1 do
		if pavement.name == safe[i] then return end
	end
	if not playertable.flame_boots[player.index].steps then playertable.flame_boots[player.index].steps = {} end
	local steps = playertable.flame_boots[player.index].steps

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

function Public.shred_simple_entities(entity)
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

function Public.spawner_loot(surface, position)
	local objective = Chrono_table.get_table()
	if math_random(1,18) == 1 then
		local count = math_random(1, 1 + objective.chronojumps)
		objective.research_tokens.weapons = objective.research_tokens.weapons + count
		flying_text(surface, position, {"chronosphere.token_weapons_add", count}, {r = 0.8, g = 0.8, b = 0.8})
	end
end

function Public.research_loot(event)
	local objective = Chrono_table.get_table()
	local bonus = 1
	if #event.research.research_unit_ingredients >= 6 then bonus = 2 end
	objective.research_tokens.tech = objective.research_tokens.tech + 5 * #event.research.research_unit_ingredients * bonus
end

function Public.tree_loot()
	local objective = Chrono_table.get_table()
	objective.research_tokens.ecology = objective.research_tokens.ecology + 1
end

function Public.choppy_loot(event)
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
		local amount = math_ceil(get_ore_amount(false) / 2)
		local second_item_amount = math_random(1,3)
		local second_item = "wood"
		local main_item = choppy_entity_yield[entity.name][math_random(1,#choppy_entity_yield[entity.name])]
		local text = "+" .. amount .. " [item=" .. main_item .. "] +" .. second_item_amount .. " [item=" .. second_item .. "]"
		local player = game.players[event.player_index]
		flying_text(entity.surface, entity.position, text, {r = 0.8, g = 0.8, b = 0.8})
		reward_ores(amount, main_item, entity.surface, player, player)
		reward_ores(second_item_amount, second_item, entity.surface, player, player)
	end
end

function Public.rocky_loot(event)
	local player = game.players[event.player_index]
	local amount = math_ceil(get_ore_amount(false))
	local rock_mining = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore", "stone", "stone", "coal", "coal"}
	local mined_loot = rock_mining[math_random(1,#rock_mining)]
	local text = "+" .. amount .. " [item=" .. mined_loot .. "]"
	flying_text(player.surface, player.position, text, {r = 0.98, g = 0.66, b = 0.22})
	reward_ores(amount, mined_loot, player.surface, player, player)
	reward_ores(math_random(1,3), "raw-fish", player.surface, player, player)
end

function Public.scrap_loot(event)
	local objective = Chrono_table.get_table()
	local scrap_table = Balance.scrap()
	local scrap = scrap_table.main[math_random(1, #scrap_table.main)]
	local scrap2 = scrap_table.second[math_random(1, #scrap_table.second)]
	local amount = math_ceil(get_ore_amount(true) * scrap.amount)
	local amount2 = math_ceil(get_ore_amount(true) * scrap2.amount)
	local player = game.players[event.player_index]
	local text = "+" .. amount .. " [item=" .. scrap.name .. "] + " .. amount2 .. " [item=" .. scrap2.name .. "]"
	flying_text(player.surface, player.position, text, {r = 0.98, g = 0.66, b = 0.22})
	reward_ores(amount, scrap.name, player.surface, player, player)
	reward_ores(amount2, scrap2.name, player.surface, player, player)
	if math_random(1, 50) == 1 then
		objective.research_tokens.tech = objective.research_tokens.tech + 1
		flying_text(player.surface, {x = player.position.x, y = player.position.y - 0.5}, {"chronosphere.token_tech_add", 1}, {r = 0.8, g = 0.8, b = 0.8})
	end
end

local biter_yield = {
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

function Public.swamp_loot(event)
	local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
	local amount = math_floor(get_ore_amount(false) / 10)
	if biter_yield[event.entity.name] then
		amount = math_floor((get_ore_amount(false) * biter_yield[event.entity.name]) / 10)
	end
	if amount > 50 then amount = 50 end

	local rock_mining = {"iron-ore", "iron-ore", "coal"}
	local mined_loot = rock_mining[math_random(1,#rock_mining)]
	reward_ores(amount, mined_loot, surface, nil, event.entity)
	local text = "+" .. amount .. " [img=item/" .. mined_loot .. "]"
	flying_text(surface, event.entity.position, text, {r=0.7,g=0.8,b=0.4})
end

function Public.biter_loot(event)
	local objective = Chrono_table.get_table()
	if biter_yield[event.entity.name] then
		objective.research_tokens.biters = objective.research_tokens.biters + biter_yield[event.entity.name]
	end
end

function Public.danger_silo(entity)
	local objective = Chrono_table.get_table()
	if objective.world.id == 2 and objective.world.variant.id == 2 then
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

function Public.biter_immunities(event)
	local objective = Chrono_table.get_table()
	local id = objective.world.id
	if event.damage_type.name == "fire" then
		if id == 1 and objective.world.variant.id == 11 then --lava planet
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
		if id == 8 then --swamp planet
			event.entity.health = event.entity.health + event.final_damage_amount
		else
			if objective.upgrades[25] > 0 then
				event.entity.health = event.entity.health - event.final_damage_amount * (0.25 * objective.upgrades[25])
			end
		end
	end
end

function Public.flamer_nerfs()
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

function Public.mining_buffs(event)

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

function Public.on_technology_effects_reset(event)
	local objective = Chrono_table.get_table()
	if event.force.name == "player" then
		game.forces.player.character_inventory_slots_bonus = game.forces.player.character_inventory_slots_bonus + objective.invupgradetier * 10
		game.forces.player.character_loot_pickup_distance_bonus = game.forces.player.character_loot_pickup_distance_bonus + objective.pickupupgradetier

		local fake_event = {}
		Public.mining_buffs(nil)
		for tech, bonuses in pairs(mining_researches) do
			tech = game.forces.player.technologies[tech]
			if tech.researched == true or bonuses.infinite == true then
				fake_event.research = tech
				if bonuses.infinite and bonuses.infinite_level and tech.level > bonuses.infinite_level then
					for i = bonuses.infinite_level, tech.level - 1 do
						Public.mining_buffs(fake_event)
					end
				else
					Public.mining_buffs(fake_event)
				end
			end
		end
	end
end

function Public.check_if_overstayed()
	local objective = Chrono_table.get_table()
  if objective.passivetimer * objective.passive_chronocharge_rate > (objective.chronochargesneeded * 0.75) and objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) then
	  objective.overstaycount = objective.overstaycount + 1
  end
end

function Public.initiate_jump_countdown()
	local objective = Chrono_table.get_table()
	objective.jump_countdown_start_time = objective.passivetimer
	game.print({"chronosphere.message_jump180"}, {r=0.98, g=0.66, b=0.22})
end

function Public.render_train_hp()
	local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
	objective.health_text = rendering.draw_text{
		text = {"chronosphere.train_HP", objective.health, objective.max_health},
		surface = surface,
		target = objective.locomotive,
		target_offset = {0, -2.5},
		color = objective.locomotive.color,
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	objective.caption = rendering.draw_text{
		text = {"chronosphere.train_name"},
		surface = surface,
		target = objective.locomotive,
		target_offset = {0, -4.25},
		color = objective.locomotive.color,
		scale = 1.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end

function Public.set_objective_health(final_damage_amount)
	if final_damage_amount == 0 then return end
	local objective = Chrono_table.get_table()
	objective.health = math_floor(objective.health - final_damage_amount)
	if objective.health > objective.max_health then objective.health = objective.max_health end

	if objective.health <= 0 then
		Chrono.objective_died()
	end
	if objective.health < objective.max_health / 2 and final_damage_amount > 0 then
		Upgrades.trigger_poison()
	end
	rendering.set_text(objective.health_text, {"chronosphere.train_HP", objective.health, objective.max_health})
end

function Public.nuclear_artillery(entity, cause)
	local objective = Chrono_table.get_table()
	if objective.upgrades[24] > 0 and objective.last_artillery_event ~= game.tick then
		entity.surface.create_entity({name = "atomic-rocket", position = entity.position, force = "player", speed = 1, max_range = 100, target = entity, source = cause})
		objective.upgrades[24] = objective.upgrades[24] - 1
		objective.last_artillery_event = game.tick
	end
end

return Public
