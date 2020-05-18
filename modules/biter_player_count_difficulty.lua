-- biters gain strength scaling with player amount in the game -- by mewmew

local event = require 'utils.event'

local function refresh_difficulty()
	global.connected_players = #game.connected_players
	if global.connected_players > 75 then global.connected_players = 75 end
	
	local f = game.forces.enemy
	local m = #game.connected_players * 0.05
	
	f.set_ammo_damage_modifier("melee", m)
	f.set_ammo_damage_modifier("biological", m * 0.5)
	f.set_ammo_damage_modifier("artillery-shell", m * 0.5)
	f.set_ammo_damage_modifier("flamethrower", m * 0.5)
	f.set_ammo_damage_modifier("laser-turret", m * 0.5)
end

local function on_entity_damaged(event)
	if not event.entity.valid then return end
	if event.entity.type ~= "unit" then return end
	if math.random(1,100) >= global.connected_players then return end
	if event.final_damage_amount > event.entity.prototype.max_health then return end
	event.entity.health = event.entity.health + event.final_damage_amount			
end

local function on_player_joined_game(event)
	refresh_difficulty()	
end

local function on_player_left_game(event)
	refresh_difficulty()	
end

event.add(defines.events.on_player_left_game, on_player_left_game)	
event.add(defines.events.on_player_joined_game, on_player_joined_game)	
event.add(defines.events.on_entity_damaged, on_entity_damaged)