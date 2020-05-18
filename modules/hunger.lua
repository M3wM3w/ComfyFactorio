-- hunger module by mewmew --

require "player_modifiers"

local math_random = math.random
local P = require "player_modifiers"

local starve_messages = {" ran out of foodstamps.", " starved.", " should not have skipped breakfast today."}

local overfeed_messages = {" ate too much and exploded.", " needs to work on their bad eating habbits.", " should have skipped dinner today.", " forgot to count them calories."}

local player_hunger_fish_food_value = 10
local player_hunger_spawn_value = 80				
local player_hunger_stages = {}
for x = 1, 200, 1 do
	if x <= 200 then player_hunger_stages[x] = "Obese" end						
	if x <= 179 then player_hunger_stages[x] = "Stuffed" end
	if x <= 150 then player_hunger_stages[x] = "Bloated" end
	if x <= 130 then player_hunger_stages[x] = "Sated" end
	if x <= 110 then player_hunger_stages[x] = "Well Fed" end
	if x <= 89 then player_hunger_stages[x] = "Nourished" end			
	if x <= 70 then player_hunger_stages[x] = "Hungry" end
	if x <= 35 then player_hunger_stages[x] = "Starving" end			
end	

local player_hunger_color_list = {}
for x = 1, 50, 1 do
	player_hunger_color_list[x] = 		{r = 0.5 + x*0.01, g = x*0.01, b = x*0.005}
	player_hunger_color_list[50+x] = {r = 1 - x*0.02, g = 0.5 + x*0.01, b = 0.25}
	player_hunger_color_list[100+x] = {r = 0 + x*0.02, g = 1 - x*0.01, b = 0.25}
	player_hunger_color_list[150+x] = {r = 1 - x*0.01, g = 0.5 - x*0.01, b = 0.25 - x*0.005}
end

local player_hunger_buff = {}
local max_buff = 0.50
local max_buff_high = 110
local max_buff_low = 89
local max_debuff = -0.85
local max_debuff_high = 180
local max_debuff_low = 20

for x = 1, max_debuff_low, 1 do
	player_hunger_buff[x] = max_debuff
end
for x = max_debuff_high, 200, 1 do
	player_hunger_buff[x] = max_debuff
end
for x = max_buff_low, max_buff_high, 1 do
	player_hunger_buff[x] = max_buff
end

for x = max_debuff_low, max_buff_low, 1 do
	local step = (max_buff - max_debuff) / (max_buff_low - max_debuff_low)
	player_hunger_buff[x] = math.round(max_debuff + (x - max_debuff_low) * step, 2)
end

for x = max_buff_high, max_debuff_high, 1 do
	local step = (max_buff - max_debuff) / (max_debuff_high - max_buff_high)
	player_hunger_buff[x] = math.round(max_buff - (x - max_buff_high) * step, 2)
end

local function create_hunger_gui(player)
	if player.gui.top["hunger_frame"] then player.gui.top["hunger_frame"].destroy() end
	local element = player.gui.top.add { type = "sprite-button", name = "hunger_frame", caption = " "}
	element.style.font = "default-bold"
	element.style.minimal_height = 38
	element.style.minimal_width = 128
	element.style.maximal_height = 38
	element.style.padding = 0
	element.style.margin = 0
	element.style.vertical_align = "center"
	element.style.horizontal_align = "center"
end

local function update_hunger_gui(player)
	if not player.gui.top["hunger_frame"] then create_hunger_gui(player) end
	local str = tostring(global.player_hunger[player.name])
	str = str .. "% "
	str = str .. player_hunger_stages[global.player_hunger[player.name]]
	player.gui.top["hunger_frame"].caption = str
	player.gui.top["hunger_frame"].style.font_color = player_hunger_color_list[global.player_hunger[player.name]]
end

function hunger_update(player, food_value)
	local player_modifiers = P.get_table()
	if not player.character then return end
	if food_value == -1 and player.character.driving == true then return end
	
	local past_hunger = global.player_hunger[player.name]	
	global.player_hunger[player.name] = global.player_hunger[player.name] + food_value
	if global.player_hunger[player.name] > 200 then global.player_hunger[player.name] = 200 end
			
	if past_hunger == 200 and global.player_hunger[player.name] + food_value > 200 then
		global.player_hunger[player.name] = player_hunger_spawn_value
		player.surface.create_entity({name = "big-artillery-explosion", position = player.character.position})
		player.character.die("player")
		game.print(player.name .. overfeed_messages[math.random(1,#overfeed_messages)], { r=0.75, g=0.0, b=0.0})				
	end	
	
	if global.player_hunger[player.name] < 1 then
		global.player_hunger[player.name] = player_hunger_spawn_value		
		player.character.die("player")
		game.print(player.name .. starve_messages[math.random(1,#starve_messages)], { r=0.75, g=0.0, b=0.0})	
	end
	
	if player.character then
		if player_hunger_stages[global.player_hunger[player.name]] ~= player_hunger_stages[past_hunger] then
			local print_message = "You are " .. player_hunger_stages[global.player_hunger[player.name]] .. "."
			if player_hunger_stages[global.player_hunger[player.name]] == "Obese" then
				print_message = "You have become " .. player_hunger_stages[global.player_hunger[player.name]]  .. "."					
			end
			if player_hunger_stages[global.player_hunger[player.name]] == "Starving" then
				print_message = "You are starving!"
				game.print(player.name .. " is starving!", player_hunger_color_list[global.player_hunger[player.name]])
			end
			player.print(print_message, player_hunger_color_list[global.player_hunger[player.name]])
		end
	end
	
	if not player.character then return end
	
	if player_hunger_buff[global.player_hunger[player.name]] < 0 then
		player_modifiers[player.index].character_running_speed_modifier["hunger"] = player_hunger_buff[global.player_hunger[player.name]] * 0.75
	else
		player_modifiers[player.index].character_running_speed_modifier["hunger"] = player_hunger_buff[global.player_hunger[player.name]] * 0.15
	end
	player_modifiers[player.index].character_mining_speed_modifier["hunger"] = player_hunger_buff[global.player_hunger[player.name]]
	P.update_player_modifiers(player)
	
	update_hunger_gui(player)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.player_hunger then global.player_hunger = {} end
	if player.online_time == 0 then		
		global.player_hunger[player.name] = player_hunger_spawn_value
		hunger_update(player, 0)
	end
	update_hunger_gui(player)
end

local function on_player_used_capsule(event)
	if event.item.name == "raw-fish" then		
		local player = game.players[event.player_index]
		if player.character.health < player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus then return end		
		hunger_update(player, player_hunger_fish_food_value)		
		player.play_sound{path="utility/armor_insert", volume_modifier=0.9}				
	end
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]
	global.player_hunger[player.name] = player_hunger_spawn_value
	hunger_update(player, 0)
end

local function on_tick()		
	for _, player in pairs(game.connected_players) do
		if player.afk_time < 18000 then hunger_update(player, -1) end
	end
end

local event = require 'utils.event'
event.on_nth_tick(3600, on_tick)
event.add(defines.events.on_player_respawned, on_player_respawned)
event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
event.add(defines.events.on_player_joined_game, on_player_joined_game)