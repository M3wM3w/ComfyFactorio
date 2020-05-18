local difficulties_votes = {
    [1] = {amount_modifier = 0.52, strength_modifier = 0.40, boss_modifier = 0.7},
    [2] = {amount_modifier = 0.76, strength_modifier = 0.65, boss_modifier = 0.8},
    [3] = {amount_modifier = 0.92, strength_modifier = 0.85, boss_modifier = 0.9},
    [4] = {amount_modifier = 1.00, strength_modifier = 1.00, boss_modifier = 1.0},
    [5] = {amount_modifier = 1.16, strength_modifier = 1.25, boss_modifier = 1.1},
    [6] = {amount_modifier = 1.48, strength_modifier = 1.75, boss_modifier = 1.2},
    [7] = {amount_modifier = 2.12, strength_modifier = 2.50, boss_modifier = 1.3}
}

function get_biter()	
	local max_chance = 0
	for k, v in pairs(global.biter_chances) do
		max_chance = max_chance + v
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for k, v in pairs(global.biter_chances) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function get_worm()
	local max_chance = 0
	for k, v in pairs(global.worm_chances) do
		max_chance = max_chance + v
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for k, v in pairs(global.worm_chances) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function set_biter_chances(level)
	global.biter_chances = {
		["small-biter"] = 500 - level * 10,
		["small-spitter"] = 500 - level * 10,
		["medium-biter"] = level * 10,
		["medium-spitter"] = level * 10,
		["big-biter"] = 0,
		["big-spitter"] = 0,
		["behemoth-biter"] = 0,
		["behemoth-spitter"] = 0,
	}
	if level > 25 then
		global.biter_chances["big-biter"] = (level - 25) * 25
		global.biter_chances["big-spitter"] = (level - 25) * 25
	end
	if level > 50 then
		global.biter_chances["behemoth-biter"] = (level - 50) * 50
		global.biter_chances["behemoth-spitter"] = (level - 50) * 50
	end
	for k, v in pairs(global.biter_chances) do
		if global.biter_chances[k] < 0 then global.biter_chances[k] = 0 end
	end
end

function set_worm_chances(level)
	global.worm_chances = {
		["small-worm-turret"] = 500 - level * 10,
		["medium-worm-turret"] = level * 10,
		["big-worm-turret"] = 0,
		["behemoth-worm-turret"] = 0,
	}
	if level > 25 then
		global.worm_chances["big-worm-turret"] = (level - 25) * 25
		global.worm_chances["big-worm-turret"] = (level - 25) * 25
	end
	if level > 50 then
		global.worm_chances["behemoth-worm-turret"] = (level - 50) * 50
		global.worm_chances["behemoth-worm-turret"] = (level - 50) * 50
	end
	for k, v in pairs(global.worm_chances) do
		if global.worm_chances[k] < 0 then global.worm_chances[k] = 0 end
	end
end


local function is_boss_stage()	
	if global.current_stage == 1 then return false end
	if global.current_stage == #global.stages - 1 then return true end
	if #global.stages < 6 then return false end
	if global.current_stage == math.floor(#global.stages * 0.5) then return true end
end

function add_enemies(surface, tiles)
	table.shuffle_table(tiles)
	
	if is_boss_stage() then
		set_biter_chances(math.floor((global.current_level * difficulties_votes[global.difficulty_vote_index].strength_modifier) + 15))
		local boss_count = math.random(1, math.floor(global.current_level * 0.5) + 1)
		if boss_count > 16 then boss_count = 16 end
		for k, tile in pairs(tiles) do
			if surface.can_place_entity({name = "small-biter", position = tile.position, force = "enemy"}) then
				local unit = surface.create_entity({name = get_biter(), position = tile.position, force = "enemy"})
				unit.ai_settings.allow_destroy_when_commands_fail = false
				unit.ai_settings.allow_try_return_to_spawner = false
				add_boss_unit(unit, (3 + global.current_level * 0.2) * difficulties_votes[global.difficulty_vote_index].boss_modifier, 0.55)
				global.alive_boss_enemy_count = global.alive_boss_enemy_count + 1
				global.alive_boss_enemy_entities[unit.unit_number] = unit
				global.alive_enemies = global.alive_enemies + 1
				boss_count = boss_count - 1
				if boss_count == 0 then break end
			end
		end
	end
	
	if global.current_level > 2 then
		if math.random(1, 5) == 1 or is_boss_stage() then
			local evolution = (global.current_level * 2 * difficulties_votes[global.difficulty_vote_index].strength_modifier) * 0.01
			if evolution > 1 then evolution = 1 end
			game.forces.enemy_spawners.evolution_factor = evolution
			local count = math.random(1, math.ceil(global.current_level * 0.10))
			if count > 5 then count = 5 end
			for k, tile in pairs(tiles) do
				if surface.can_place_entity({name = "biter-spawner", position = tile.position, force = "enemy_spawners"}) then
					surface.create_entity({name = "biter-spawner", position = tile.position, force = "enemy_spawners"})
					global.alive_enemies = global.alive_enemies + 1
					count = count - 1
					if count == 0 then break end
				end
			end
		end
	end
	
	if math.random(1, 4) == 1 or is_boss_stage() then
		set_worm_chances(global.current_level)
		local worm_count = math.random(1, math.ceil(global.current_level * 0.5))
		if worm_count > 32 then worm_count = 32 end
		for k, tile in pairs(tiles) do
			if surface.can_place_entity({name = "big-worm-turret", position = tile.position, force = "enemy"}) then
				surface.create_entity({name = get_worm(), position = tile.position, force = "enemy"})
				global.alive_enemies = global.alive_enemies + 1
				worm_count = worm_count - 1
				if worm_count == 0 then break end
			end
		end
	end
		
	set_biter_chances(math.floor(global.current_level * difficulties_votes[global.difficulty_vote_index].strength_modifier) + 1)
	local amount = ((global.current_level * 25) / #global.stages) * global.current_stage
	amount = amount * difficulties_votes[global.difficulty_vote_index].amount_modifier
	for k, tile in pairs(tiles) do
		if surface.can_place_entity({name = "small-biter", position = tile.position, force = "enemy"}) then			
			local unit = surface.create_entity({name = get_biter(), position = tile.position, force = "enemy"})
			unit.ai_settings.allow_destroy_when_commands_fail = false
			unit.ai_settings.allow_try_return_to_spawner = false
			global.alive_enemies = global.alive_enemies + 1
			amount = amount - 1
		end
		if amount <= 0 then break end
	end
	
	update_stage_gui()
end