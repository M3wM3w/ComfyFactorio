
require "on_tick_schedule"
require "modules.dynamic_landfill"
require "modules.difficulty_vote"
require "modules.shotgun_buff"
require "maps.scrapyard.burden"
require "modules.rocks_heal_over_time"
require "modules.no_deconstruction_of_neutral_entities"
require "maps.scrapyard.flamethrower_nerf"
require "modules.rocks_yield_ore_veins"
require "modules.spawners_contain_biters"
require "modules.biters_yield_coins"
require "modules.biter_noms_you"
require "modules.wave_defense.main"
require "maps.scrapyard.comfylatron"
require "modules.explosives"

local Color = require 'utils.color_presets'
local ICW = require "maps.scrapyard.icw.main"
local WD = require "modules.wave_defense.table"
local Map = require 'modules.map_info'
local RPG = require 'maps.scrapyard.rpg'
local Reset = require "functions.soft_reset"
local BiterRolls = require "modules.wave_defense.biter_rolls"
local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"
local Loot = require 'maps.scrapyard.loot'
local Pets = require "modules.biter_pets"
local tick_tack_trap = require "functions.tick_tack_trap"
local Terrain = require 'maps.scrapyard.terrain'
local Event = require 'utils.event'
local Scrap_table = require "maps.scrapyard.table"
local Locomotive = require "maps.scrapyard.locomotive".locomotive_spawn
local render_train_hp = require "maps.scrapyard.locomotive".render_train_hp
local Score = require "comfy_panel.score"
local Poll = require "comfy_panel.poll"
local Collapse = require "maps.scrapyard.collapse"

local Public = {}
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs

function Public.print(msg)
	if _DEBUG then
		game.print(serpent.block(msg))
	end
end

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['wood'] = 4, ['rail'] = 16, ['raw-fish'] = 2}
local disabled_entities = {"gun-turret", "laser-turret", "flamethrower-turret", "land-mine"}
local colors = {"green-refined-concrete", "black-refined-concrete", "orange-refined-concrete", "red-refined-concrete", "yellow-refined-concrete", "brown-refined-concrete", "blue-refined-concrete"}
local treasure_chest_messages = {
	"You notice an old crate within the rubble. It's filled with treasure!",
	"You find a chest underneath the broken rocks. It's filled with goodies!",
	"We has found the precious!",
}

local rare_treasure_chest_messages = {
	"Your magic improves. You have found a chest that is filled with rare treasure!",
	"Oh wonderful magic. You found a chest underneath the broken rocks. It's filled with rare goodies!",
	"You're a wizard Harry! We has found the rare precious!",
}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function set_objective_health(entity, final_damage_amount)
	local this = Scrap_table.get_table()
	if final_damage_amount == 0 then return end
	this.locomotive_health = math_floor(this.locomotive_health - final_damage_amount)
	this.cargo_health = math_floor(this.cargo_health - final_damage_amount)
	if this.locomotive_health > this.locomotive_max_health then this.locomotive_health = this.locomotive_max_health end
	if this.cargo_health > this.cargo_max_health then this.cargo_health = this.cargo_max_health end
	if this.locomotive_health <= 0 then
		Public.loco_died()
	end
	local m
	if entity == this.locomotive then
		m = this.locomotive_health / this.locomotive_max_health
		entity.health = 1000 * m
	elseif entity == this.locomotive_cargo then
		m = this.cargo_health / this.cargo_max_health
		entity.health = 600 * m
	end
	rendering.set_text(this.health_text, "HP: " .. this.locomotive_health .. " / " .. this.locomotive_max_health)
end

local function set_difficulty()
	local wave_defense_table = WD.get_table()
	local player_count = #game.connected_players

	wave_defense_table.max_active_biters = 1024

	-- threat gain / wave
	wave_defense_table.threat_gain_multiplier = 2 + player_count * 0.1

	local amount = player_count * 0.25 + 2
	amount = math.floor(amount)
	if amount > 8 then amount = 8 end
	Collapse.set_amount(amount)


	--20 Players for fastest wave_interval
	wave_defense_table.wave_interval = 3600 - player_count * 90
	if wave_defense_table.wave_interval < 1800 then wave_defense_table.wave_interval = 1800 end
end

function Public.reset_map()
	local this = Scrap_table.get_table()
	local wave_defense_table = WD.get_table()
	local get_score = Score.get_table()
	Poll.reset()
	ICW.reset()
	game.reset_time_played()
	Scrap_table.reset_table()
	wave_defense_table.math = 8
	this.revealed_spawn = game.tick + 100

	local map_gen_settings = {
		["seed"] = math_random(1, 1000000),
		["water"] = 0.001,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
		["entity"] = {treat_missing_as_default = false},
		["tile"] = {treat_missing_as_default = true},
		["decorative"] = {treat_missing_as_default = true},
		},
	}

	if not this.active_surface_index then
		this.active_surface_index = game.create_surface("scrapyard", map_gen_settings).index
	else
		game.forces.player.set_spawn_position({0,21}, game.surfaces[this.active_surface_index])
		this.active_surface_index = Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
	end

	local surface = game.surfaces[this.active_surface_index]

	surface.request_to_generate_chunks({0,0}, 0.5)
	surface.force_generate_chunk_requests()

	local p = surface.find_non_colliding_position("character-corpse", {2,21}, 2, 2)
	surface.create_entity({name = "character-corpse", position = p})

	game.forces.player.technologies["landfill"].enabled = false
	game.forces.player.technologies["optics"].researched = true
	game.forces.player.set_spawn_position({0, 21}, surface)

	global.friendly_fire_history = {}
	global.landfill_history = {}
	global.mining_history = {}
	get_score.score_table = {}
	global.difficulty_poll_closing_timeout = game.tick + 90000
	global.difficulty_player_votes = {}

	game.difficulty_settings.technology_price_multiplier = 0.6

	Collapse.set_kill_entities(false)
	Collapse.set_speed(8)
	Collapse.set_amount(1)
	Collapse.set_max_line_size(Terrain.level_depth)
	Collapse.set_surface(surface)
	Collapse.set_position({0, 290})
	Collapse.set_direction("north")
	Collapse.start_now(false)

	surface.ticks_per_day = surface.ticks_per_day * 2
	surface.min_brightness = 0.08
	surface.daytime = 0.7
	surface.brightness_visual_weights = {1, 0, 0, 0}
	surface.freeze_daytime = false
	surface.solar_power_multiplier = 1
	this.locomotive_health = 10000
	this.locomotive_max_health = 10000
	this.cargo_health = 10000
	this.cargo_max_health = 10000

	Locomotive(surface, {x = -18, y = 10})
	render_train_hp()

	rendering.draw_text{
		text = "Welcome to Scrapyard!",
		surface = surface,
		target = {-0,30},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}

	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,40},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,50},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,60},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,70},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,80},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,90},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,100},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,110},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "Biters will attack this area.",
		surface = surface,
		target = {-0,120},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}

	WD.reset_wave_defense()
	wave_defense_table.surface_index = this.active_surface_index
	wave_defense_table.target = this.locomotive_cargo
	wave_defense_table.nest_building_density = 32
	wave_defense_table.game_lost = false
	wave_defense_table.spawn_position = {x=0,y=220}

	game.forces.player.set_friend('scrap', true)
	game.forces.enemy.set_friend('scrap', true)
	game.forces.scrap.set_friend('player', true)
	game.forces.scrap.set_friend('enemy', true)
	game.forces.scrap.share_chart = false

	surface.create_entity({name = "electric-beam", position = {-196, 190}, source = {-196, 190}, target = {196,190}})
	surface.create_entity({name = "electric-beam", position = {-196, 190}, source = {-196, 190}, target = {196,190}})

	RPG.rpg_reset_all_players()

	set_difficulty()
end

local function is_protected(entity)
	local this = Scrap_table.get_table()
	if string.sub(entity.surface.name, 0, 9) ~= "scrapyard" then return true end
	local protected = {this.locomotive, this.locomotive_cargo}
	for i = 1, #protected do
    if protected[i] == entity then
      return true
    end
  end
	return false
end

local function protect_train(event)
	local this = Scrap_table.get_table()
	if event.entity.force.index ~= 1 then return end --Player Force
	if is_protected(event.entity) then
		if event.entity == this.locomotive_cargo or event.entity == this.locomotive then
			if event.cause then
				if event.cause.force.index == 2 or event.cause.force.name == "scrap_defense" or event.cause.force.name == "scrap" then
				if this.locomotive_health <= 0 then goto continue end
					set_objective_health(event.entity, event.final_damage_amount)
				end
			end
			::continue::
		end
		if not event.entity.valid then return end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end


local function change_tile(surface, pos, steps)
	return surface.set_tiles{{name = colors[math_floor(steps * 0.5) % 7 + 1], position=pos}}
end

local function on_player_changed_position(event)
	local this = Scrap_table.get_table()
	local player = game.players[event.player_index]
	if string.sub(player.surface.name, 0, 9) ~= "scrapyard" then return end
	local position = player.position
	local surface = game.surfaces[this.active_surface_index]
	if position.x >= Terrain.level_depth * 0.5 then return end
	if position.x < Terrain.level_depth * -0.5 then return end
	if position.y < 5 then
		if not this.players[player.index].tiles_enabled then goto continue end
		--for x = -1,1 do
			--for y = -1,1 do
		    --local _pos = {position.x+x,position.y+y}
			local steps = this.players[player.index].steps
			local shallow, deepwater, oom = surface.get_tile(position).name == "water-shallow", surface.get_tile(position).name == "deepwater-green", surface.get_tile(position).name == "out-of-map"
			if shallow or deepwater or oom then goto continue end
			change_tile(surface, position, steps)
			if this.players[player.index].steps > 5000 then
				this.players[player.index].steps = 0
			end
			this.players[player.index].steps = this.players[player.index].steps + 1
			--end
		--end
	end
	::continue::
	if position.y < 5 then Terrain.reveal(player) end
	if position.y >= 190 then
		player.teleport({position.x, position.y - 1}, surface)
		player.print("[color=blue]Grandmaster:[/color] Forcefield does not approve.",{r=0.98, g=0.66, b=0.22})
		if player.character then
			player.character.health = player.character.health - 5
			player.character.surface.create_entity({name = "water-splash", position = position})
			if player.character.health <= 0 then player.character.die("enemy") end
		end
	end
end

local function on_player_left_game()
	set_difficulty()
end

local function on_player_joined_game(event)
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	local player = game.players[event.player_index]

	set_difficulty(event)

	if not this.players[player.index] then this.players[player.index] = {
		tiles_enabled = true,
		steps = 0,
		first_join = false
		}
	end

	if not this.players[player.index].first_join then
		 player.print("[color=blue]Grandmaster:[/color] Greetings, newly joined " .. player.name .. "!", {r = 1, g = 0.5, b = 0.1})
		 player.print("[color=blue]Grandmaster:[/color] Please read the map info.", {r = 1, g = 0.5, b = 0.1})
		 player.print("[color=blue]Grandmaster:[/color] Guide the choo through the black mist.", {r = 1, g = 0.5, b = 0.1})
		 player.print("[color=blue]Grandmaster:[/color] To disable rainbow mode, type in console: /rainbow_mode", Color.info)
		this.players[player.index].first_join = true
	end

	if player.surface.index ~= this.active_surface_index then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 3, 0,5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end
end

local function hidden_biter(entity)
	BiterRolls.wave_defense_set_unit_raffle(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.25)
	if math.random(1,3) == 1 then
		entity.surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = entity.position})
	else
		entity.surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = entity.position})
	end
end

local function hidden_worm(entity)
	BiterRolls.wave_defense_set_worm_raffle(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.25)
	entity.surface.create_entity({name = BiterRolls.wave_defense_roll_worm_name(), position = entity.position})
end

local function hidden_biter_pet(event)
	if math.random(1, 2048) ~= 1 then return end
	BiterRolls.wave_defense_set_unit_raffle(math.sqrt(event.entity.position.x ^ 2 + event.entity.position.y ^ 2) * 0.25)
	local unit
	if math.random(1,3) == 1 then
		unit = event.entity.surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = event.entity.position})
	else
		unit = event.entity.surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = event.entity.position})
	end
	Pets.biter_pets_tame_unit(game.players[event.player_index], unit, true)
end

local function hidden_treasure(event)
	local player = game.players[event.player_index]
	local rpg_t = RPG.get_table()
	local magic = rpg_t[player.index].magic
	if math.random(1, 320) ~= 1 then return end
	if magic > 50 then
		player.print(rare_treasure_chest_messages[math.random(1, #rare_treasure_chest_messages)], {r=0.98, g=0.66, b=0.22})
		Loot.add(event.entity.surface, event.entity.position, "wooden-chest", magic)
		return
	end
	player.print(treasure_chest_messages[math.random(1, #treasure_chest_messages)], {r=0.98, g=0.66, b=0.22})
	Loot.add(event.entity.surface, event.entity.position, "wooden-chest")
end

local function biters_chew_rocks_faster(event)
	if event.entity.force.index ~= 3 then return end --Neutral Force
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index ~= 2 then return end --Enemy Force

	event.entity.health = event.entity.health - event.final_damage_amount * 2.5
end

local function give_coin(player)
	player.insert({name = "coin", count = 1})
end

local function on_player_mined_entity(event)
	local entity = event.entity
	local player = game.players[event.player_index]
	if not player.valid then
	    return
	end
	if not entity.valid then
		return
	end

	if entity.type == "unit" or entity.type == "unit-spawner" then
		if math_random(1,160) == 1 then
			tick_tack_trap(entity.surface, entity.position)
			return
		end
		if math.random(1,32) == 1 then
			hidden_biter(event.entity)
			return
		end
	end

	if entity.name == "mineable-wreckage" then
		give_coin(player)

		if math.random(1,32) == 1 then
			hidden_biter(event.entity)
			return
		end
		if math.random(1,512) == 1 then
			hidden_worm(event.entity)
			return
		end
		hidden_biter_pet(event)
		hidden_treasure(event)
		if math_random(1,160) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	end

	if entity.force.name ~= "scrap" then return end
	local positions = {}
	local r = math.ceil(entity.prototype.max_health / 32)
	for x = r * -1, r, 1 do
		for y = r * -1, r, 1 do
			positions[#positions + 1] = {x = entity.position.x + x, y = entity.position.y + y}
		end
	end
	positions = shuffle(positions)
	for i = 1, math.ceil(entity.prototype.max_health / 32), 1 do
		if not positions[i] then return end
		if math_random(1,3) ~= 1 then
			unearthing_biters(entity.surface, positions[i], math_random(5,10))
		else
			unearthing_worm(entity.surface, positions[i])
		end
	end
end

local function on_entity_damaged(event)
	if not event.entity then return end
	if not event.entity.valid then return end
	if not event.entity.health then return end
	protect_train(event)
	biters_chew_rocks_faster(event)
end

local function on_player_repaired_entity(event)
	local this = Scrap_table.get_table()
	if not event.entity then return end
	if not event.entity.valid then return end
	if not event.entity.health then return end
	local entity = event.entity
	if entity == this.locomotive_cargo or entity == this.locomotive then
		set_objective_health(entity, -4)
	end
end

function Public.loco_died()
  local this = Scrap_table.get_table()
  local surface = game.surfaces[this.active_surface_index]
  local wave_defense_table = WD.get_table()
  if not this.locomotive.valid then
    wave_defense_table.game_lost = true
    wave_defense_table.target = nil
    game.print("[color=blue]Grandmaster:[/color] Oh noooeeeew, the void destroyed my train!", {r = 1, g = 0.5, b = 0.1})
    game.print("[color=blue]Grandmaster:[/color] Better luck next time.", {r = 1, g = 0.5, b = 0.1})
    Public.reset_map()
    return
  end
  this.locomotive_health = 0
  this.locomotive.color = {0.49, 0, 255, 1}
  rendering.set_text(this.health_text, "HP: " .. this.locomotive_health .. " / " .. this.locomotive_max_health)
  wave_defense_table.game_lost = true
  wave_defense_table.target = nil
  game.print("[color=blue]Grandmaster:[/color] Oh noooeeeew, they destroyed my train!", {r = 1, g = 0.5, b = 0.1})
  game.print("[color=blue]Grandmaster:[/color] Better luck next time.", {r = 1, g = 0.5, b = 0.1})
  game.print("[color=blue]Grandmaster:[/color] Game will soft-reset shortly.", {r = 1, g = 0.5, b = 0.1})

  local fake_shooter = surface.create_entity({name = "character", position = this.locomotive.position, force = "enemy"})
  surface.create_entity({name = "atomic-rocket", position = this.locomotive.position, force = "enemy", speed = 1, max_range = 800, target = this.locomotive, source = fake_shooter})

  surface.spill_item_stack(this.locomotive.position,{name = "coin", count = 512}, false)
  surface.spill_item_stack(this.locomotive_cargo.position,{name = "coin", count = 512}, false)
  this.game_reset_tick = game.tick + 1800
  for _, player in pairs(game.connected_players) do
    player.play_sound{path="utility/game_lost", volume_modifier=0.75}
  end

end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then
		return
	end
	if entity.type == "unit" or entity.type == "unit-spawner" then
		if math_random(1,160) == 1 then
			tick_tack_trap(entity.surface, entity.position)
			return
		end
		if math.random(1,32) == 1 then
			hidden_biter(event.entity)
			return
		end
	end

	if entity.name == "mineable-wreckage" then
		if math.random(1,32) == 1 then
			hidden_biter(event.entity)
			return
		end
		if math.random(1,512) == 1 then
			hidden_worm(event.entity)
			return
		end
		if math_random(1,160) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	end
	if entity.force.name ~= "scrap" then return end
	local positions = {}
	local r = math.ceil(entity.prototype.max_health / 32)
	for x = r * -1, r, 1 do
		for y = r * -1, r, 1 do
			positions[#positions + 1] = {x = entity.position.x + x, y = entity.position.y + y}
		end
	end
	positions = shuffle(positions)
	for i = 1, math.ceil(entity.prototype.max_health / 32), 1 do
		if not positions[i] then return end
		if math_random(1,3) ~= 1 then
			unearthing_biters(entity.surface, positions[i], math_random(5,10))
		else
			unearthing_worm(entity.surface, positions[i])
		end
	end
end


local function on_built_entity(event)
	if string.sub(event.created_entity.surface.name, 0, 9) ~= "scrapyard" then return end
	local player = game.players[event.player_index]
	local y = event.created_entity.position.y
	local ent = event.created_entity
	if y >= 150 then
		player.print("[color=blue]Grandmaster:[/color] I do not approve, " .. ent.name .. " was obliterated.", {r = 1, g = 0.5, b = 0.1})
		ent.die()
		return
	else
		for _, e in pairs(disabled_entities) do
			if e == event.created_entity.name then
				if y >= 0 then
					ent.active = false
					if event.player_index then
						player.print("[color=blue]Grandmaster:[/color] Can't build here. I disabled your " .. ent.name ..".", {r = 1, g = 0.5, b = 0.1})
						return
					end
				end
			end
		end
	end
end

local function on_research_finished(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 50 -- +5 Slots / level
	local mining_speed_bonus = game.forces.player.mining_drill_productivity_bonus * 5 -- +50% speed / level
	if event.research.force.technologies["steel-axe"].researched then mining_speed_bonus = mining_speed_bonus + 0.5 end -- +50% speed for steel-axe research
	event.research.force.manual_mining_speed_modifier = mining_speed_bonus
end

local function on_robot_built_entity(event)
	if string.sub(event.created_entity.surface.name, 0, 9) ~= "scrapyard" then return end
	local y = event.created_entity.position.y
	local ent = event.created_entity
	if y >= 150 then
		game.print("[color=blue]Grandmaster:[/color] I do not approve, " .. ent.name .. " was obliterated.", {r = 1, g = 0.5, b = 0.1})
		ent.die()
		return
	else
		for _, e in pairs(disabled_entities) do
			if e == event.created_entity.name then
				if y >= 0 then
					ent.active = false
					if event.player_index then
						game.print("[color=blue]Grandmaster:[/color] Can't build here. I disabled your " .. ent.name ..".", {r = 1, g = 0.5, b = 0.1})
						return
					end
				end
			end
		end
	end
end

local on_init = function()
	game.create_force("scrap")
	game.create_force("scrap_defense")
	game.forces.player.set_friend('scrap', true)
	game.forces.enemy.set_friend('scrap', true)
	game.forces.scrap.set_friend('player', true)
	game.forces.scrap.set_friend('enemy', true)
	game.forces.scrap.share_chart = false
	global.rocks_yield_ore_maximum_amount = 999
	global.rocks_yield_ore_base_amount = 50
	global.rocks_yield_ore_distance_modifier = 0.025
	Public.reset_map()
	local T = Map.Pop_info()
		T.main_caption = "R a i n b o w   S c r a p y a r d"
		T.sub_caption =  "    ---defend the choo---"
		T.text = table.concat({
		"The biters have catched the scent of fish in the cargo wagon.\n",
		"Guide the choo through the black mist and protect it for as long as possible!\n",
		"This will not be an easy task however,\n",
		"since their strength and numbers increase over time.\n",
		"\n",
		"Delve deep for greater treasures, but also face increased dangers.\n",
		"Mining productivity research, will overhaul your mining equipment,\n",
		"reinforcing your pickaxe as well as increasing the size of your backpack.\n",
		"\n",
		"Scrap randomness seems to occur frequently, sometimes mining scrap\n",
		"does not output scrap, weird...\n",
		"\n",
		"We've also noticed that solar eclipse occuring, \n",
		"we have yet to solve this mystery\n",
		"\n",
		"Good luck, over and out!"
		})
		T.main_caption_color = {r = 150, g = 150, b = 0}
		T.sub_caption_color = {r = 0, g = 150, b = 0}

	local mgs = game.surfaces["nauvis"].map_gen_settings
	mgs.width = 16
	mgs.height = 16
	game.surfaces["nauvis"].map_gen_settings = mgs
	game.surfaces["nauvis"].clear()

	global.explosion_cells_destructible_tiles = {
		["out-of-map"] = 1500,
		["water"] = 1000,
		["water-green"] = 1000,
		["deepwater-green"] = 1000,
		["deepwater"] = 1000,
		["water-shallow"] = 1000,
	}
end

local function darkness(data)
	local rnd = math.random
	local surface = data.surface
	if rnd(1, 64) == 1 then
		if surface.freeze_daytime then return end
		game.print("[color=blue]Grandmaster:[/color] Darkness has surrounded us!", {r = 1, g = 0.5, b = 0.1})
		game.print("[color=blue]Grandmaster:[/color] Builds some lamps!", {r = 1, g = 0.5, b = 0.1})
		surface.min_brightness = 0
		surface.brightness_visual_weights = {0.90, 0.90, 0.90}
		surface.daytime = 0.42
		surface.freeze_daytime = true
		surface.solar_power_multiplier = 0
		return
	elseif rnd(1, 32) == 1 then
		if not surface.freeze_daytime then return end
		game.print("[color=blue]Grandmaster:[/color] Sunlight, finally!", {r = 1, g = 0.5, b = 0.1})
		surface.min_brightness = 1
		surface.brightness_visual_weights = {1, 0, 0, 0}
		surface.daytime = 0.7
		surface.freeze_daytime = false
		surface.solar_power_multiplier = 1
		return
	end
end


local function scrap_randomness(data)
	local this = data.this
	local rnd = math.random
	if rnd(1, 64) == 1 then
		if not this.scrap_enabled then return end
		this.scrap_enabled = false
		game.print("[color=blue]Grandmaster:[/color] It seems that the scrap is temporarily gone.", {r = 1, g = 0.5, b = 0.1})
		game.print("[color=blue]Grandmaster:[/color] Output from scrap is now only ores.", {r = 1, g = 0.5, b = 0.1})
		return
	elseif rnd(1, 32) == 1 then
		if this.scrap_enabled then return end
		this.scrap_enabled = true
		game.print("[color=blue]Grandmaster:[/color] Scrap is back!", {r = 1, g = 0.5, b = 0.1})
		game.print("[color=blue]Grandmaster:[/color] Output from scrap is now randomized.", {r = 1, g = 0.5, b = 0.1})
		return
	end
end

local function transfer_pollution(data)
	local surface = data.surface
	local this = data.this
	if not surface then return end
	local pollution = surface.get_total_pollution() * (3 / (4 / 3 + 1)) * global.difficulty_vote_value
	game.surfaces[this.active_surface_index].pollute(this.locomotive.position, pollution)
	surface.clear_pollution()
end

local tick_minute_functions = {
	[300 * 2] = scrap_randomness,
	[300 * 3 + 30 * 0] = darkness,
	[300 * 3 + 30 * 1] = transfer_pollution,
}

local on_tick = function()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	local wave_defense_table = WD.get_table()
	local tick = game.tick
	local key = tick % 3600
	local data = {
		this = this,
		surface = surface
	}
	if not this.locomotive.valid then
		Public.loco_died()
	end
	if Collapse.start_now() == true then goto continue end
	if this.left_top.y % Terrain.level_depth == 0 and this.left_top.y < 0 and this.left_top.y > Terrain.level_depth * -10 then
		if not Collapse.start_now() then
			this.o_left_top = this.left_top
			Collapse.start_now(true)
		end
	end
	::continue::
	if game.tick % 30 == 0 then
		if game.tick % 1800 == 0 then
			local position = surface.find_non_colliding_position("stone-furnace", Collapse.get_position(), 128, 1)
			if position then
				wave_defense_table.spawn_position = position
			end
		end
	end
	if tick_minute_functions[key] then tick_minute_functions[key](data) end
	if this.randomness_tick then
		if this.randomness_tick < game.tick then
			this.randomness_tick = game.tick + 1800
			scrap_randomness(this)
			darkness(this)
		end
	end

	if this.game_reset_tick then
		if this.game_reset_tick < game.tick then
			this.game_reset_tick = nil
			Public.reset_map()
		end
		return
	end
end

commands.add_command(
    'rainbow_mode',
    'This will prevent new tiles from spawning when walking',
    function()
    local player = game.player
    local this = Scrap_table.get_table()
    if player and player.valid then
		if this.players[player.index].tiles_enabled == false then
			this.players[player.index].tiles_enabled = true
			player.print("Rainbow mode: ON", Color.green)
			return
		end
		if this.players[player.index].tiles_enabled == true then
			this.players[player.index].tiles_enabled = false
			player.print("Rainbow mode: OFF", Color.warning)
			return
		end
	end
end)

if _DEBUG then
commands.add_command(
    'reset_game',
    'Debug only, reset the game!',
    function()
    local player = game.player

    if player then
        if player ~= nil then
            if not player.admin then
                return
            end
        end
    end
    Public.reset_map()
	end)
end

Event.on_nth_tick(10, on_tick)
Event.on_init(on_init)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_research_finished, on_research_finished)

require "maps.scrapyard.mineable_wreckage_yields_scrap"
require "maps.scrapyard.balance"

return Public