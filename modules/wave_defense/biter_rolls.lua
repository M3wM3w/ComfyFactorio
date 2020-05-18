local WD = require "modules.wave_defense.table"

local Public = {}

function Public.wave_defense_roll_biter_name()
	local wave_defense_table = WD.get_table()
	local max_chance = 0
	for k, v in pairs(wave_defense_table.biter_raffle) do
		max_chance = max_chance + v
	end
	local r = math.random(0, math.floor(max_chance))	
	local current_chance = 0
	for k, v in pairs(wave_defense_table.biter_raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function Public.wave_defense_roll_spitter_name()
	local wave_defense_table = WD.get_table()
	local max_chance = 0
	for k, v in pairs(wave_defense_table.spitter_raffle) do
		max_chance = max_chance + v
	end
	local r = math.random(0, math.floor(max_chance))
	local current_chance = 0
	for k, v in pairs(wave_defense_table.spitter_raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function Public.wave_defense_set_unit_raffle(level)
	local wave_defense_table = WD.get_table()
	wave_defense_table.biter_raffle = {
		["small-biter"] = 1000 - level * 1.75,		
		["medium-biter"] = level,		
		["big-biter"] = 0,		
		["behemoth-biter"] = 0,
	}
	wave_defense_table.spitter_raffle = {		
		["small-spitter"] = 1000 - level * 1.75,
		["medium-spitter"] = level,
		["big-spitter"] = 0,
		["behemoth-spitter"] = 0,
	}
	if level > 500 then
		wave_defense_table.biter_raffle["medium-biter"] = 500 - (level - 500)
		wave_defense_table.spitter_raffle["medium-spitter"] = 500 - (level - 500)
		wave_defense_table.biter_raffle["big-biter"] = (level - 500) * 2
		wave_defense_table.spitter_raffle["big-spitter"] = (level - 500) * 2
	end
	if level > 800 then
		wave_defense_table.biter_raffle["behemoth-biter"] = (level - 800) * 2.75
		wave_defense_table.spitter_raffle["behemoth-spitter"] = (level - 800) * 2.75
	end
	for k, v in pairs(wave_defense_table.biter_raffle) do
		if wave_defense_table.biter_raffle[k] < 0 then wave_defense_table.biter_raffle[k] = 0 end
	end
	for k, v in pairs(wave_defense_table.spitter_raffle) do
		if wave_defense_table.spitter_raffle[k] < 0 then wave_defense_table.spitter_raffle[k] = 0 end
	end	
end

function Public.wave_defense_roll_worm_name()
	local wave_defense_table = WD.get_table()
	local max_chance = 0
	for k, v in pairs(wave_defense_table.worm_raffle) do
		max_chance = max_chance + v
	end
	local r = math.random(0, math.floor(max_chance))
	local current_chance = 0
	for k, v in pairs(wave_defense_table.worm_raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function Public.wave_defense_set_worm_raffle(level)
	local wave_defense_table = WD.get_table()
	wave_defense_table.worm_raffle = {
		["small-worm-turret"] = 1000 - level * 1.75,
		["medium-worm-turret"] = level,		
		["big-worm-turret"] = 0,		
		["behemoth-worm-turret"] = 0,		
	}
	if level > 500 then
		wave_defense_table.worm_raffle["medium-worm-turret"] = 500 - (level - 500)
		wave_defense_table.worm_raffle["big-worm-turret"] = (level - 500) * 2		
	end
	if level > 800 then
		wave_defense_table.worm_raffle["behemoth-worm-turret"] = (level - 800) * 3		
	end
	for k, v in pairs(wave_defense_table.worm_raffle) do
		if wave_defense_table.worm_raffle[k] < 0 then wave_defense_table.worm_raffle[k] = 0 end
	end
end

function Public.wave_defense_print_chances(tbl)
	for k, v in pairs(tbl) do
		game.print(k .. " chance = " .. v)
	end
end

return Public