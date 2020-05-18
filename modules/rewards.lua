-- Rewards Module
-- Made by: skudd3r for ComfyPlay
-- This module sets the rewards based on the killscore(score module)

local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Score = require "comfy_panel.score"
local floor = math.floor
local sqrt = math.sqrt
local insert = table.insert

local rewards_loot = {
	[1] = {{name = "submachine-gun", count = 1, text = " Submachine Gun"}, {name = "firearm-magazine", count = 50, text = " SMG Rounds"}},
	[2] = {{name = "heavy-armor", count = 1, text = " Heavy Armor"}, {name = "defender-capsule", count = 20, text = " Defender-Bots"}},
	[3] = {{name = "firearm-magazine", count = 50, text = " SMG Rounds"}, {name = "grenade", count = 10, text = " Grenades"}},
	[4] = {{name = "land-mine", count = 20, text = " Landmines"}, {name = "firearm-magazine", count = 100, text = " SMG Rounds"}},
	[5] = {{name = "slowdown-capsule", count = 20, text = " Slowdown Capsules"}, {name = "poison-capsule", count = 20, text = " Poison Capsules"}},
	[6] = {{name = "land-mine", count = 30, text = " Landmines"}, {name = "raw-fish", count = 30, text = " Fish Food"}},
	[7] = {{name = "piercing-rounds-magazine", count = 50, text = " SMG AP Rounds"}, {name = "distractor-capsule", count = 20, text = " Distractor Capsules"}},
	[8] = {{name = "combat-shotgun", count = 1, text = " Combat Shotgun"}, {name = "piercing-shotgun-shell", count = 50, text = " AP Shotgun Shells"}},
	[9] = {{name = "poison-capsule", count = 40, text = " Poison Capsule"}, {name = "piercing-rounds-magazine", count = 100, text = " SMG AP Rounds"}},
	[10] = {{name = "computer", count = 1, text = " Teleporter Computer"}, {name = "modular-armor", count = 1, text = " Modular Armor"}},
	[11] = {{name = "solar-panel-equipment", count = 2, text = " Portable Solar Panel"}, {name = "battery-equipment", count = 1, text = " MK1 Battery"}, {name = "night-vision-equipment", count = 1, text = " Night Vision Goggles"}},
	[12] = {{name = "cluster-grenade", count = 20, text = " Cluster Grenades"}, {name = "piercing-shotgun-shell", count = 100, text = " AP Shotgun Shells"}},
	[13] = {{name = "flamethrower", count = 1, text = " Flamethrower"}, {name = "flamethrower-ammo", count = 50, text = " Flamethrower Rounds"}},
	[14] = {{name = "slowdown-capsule", count = 30, text = " Slowdown Capsule"}, {name = "piercing-rounds-magazine", count = 200, text = " SMG Rounds"}},
	[15] = {{name = "battery-equipment", count = 2, text = " MK1 Battery"}, {name = "solar-panel-equipment", count = 4, text = " Portable Solar Panel"}},
	[16] = {{name = "energy-shield-equipment", count = 1, text = " Energy Shield MK1"}, {name = "cluster-grenade", count = 20, text = " Cluster Grenades"}, {name = "flamethrower-ammo", count = 50, text = " Flamethrower Rounds"}},
	[17] = {{name = "energy-shield-equipment", count = 1, text = " Energy Shield MK1"}, {name = "land-mine", count = 50, text = " Landmines"}, {name = "piercing-rounds-magazine", count = 200, text = " SMG Rounds"}},
	[18] = {{name = "exoskeleton-equipment", count = 1, text = " Exoskelet"}, {name = "raw-fish", count = 50, text = " Fish Food"}},
	[19] = {{name = "battery-mk2-equipment", count = 1, text = " Armor Battery Mk2"}, {name = "rocket-launcher", count = 1, text = " Rocket Launcher"}, {name = "rocket", count = 10, text = " Rockets"}},
	[20] = {{name = "power-armor", count = 1, text = " Power Armor MK1"}, {name = "computer", count = 1, text = " Teleporter Computer"}},
	[21] = {{name = "personal-roboport-equipment", count = 1, text = " Armor Roboport MK1"}, {name = "construction-robot", count = 10, text = " Construction-Bots"}},
	[22] = {{name = "personal-laser-defense-equipment", count = 1, text = " Personal Laser Defense"}, {name = "flamethrower-ammo", count = 100, text = " Flamethrower Rounds"}},
	[23] = {{name = "rocket", count = 40, text = " Rockets"}, {name = "cluster-grenade", count = 20, text = " Cluster-Grenades"}},
	[24] = {{name = "explosive-rocket", count = 40, text = " Explosive Rockets"}, {name = "piercing-rounds-magazine", count = 200, text = " SMG Rounds"}},
	[25] = {{name = "land-mine", count = 50, text = " Landmines"}, {name = "solar-panel-equipment", count = 2, text = " Portable Solar Panel"}},
	[26] = {{name = "uranium-rounds-magazine", count = 100, text = " Uranium Rounds"}},
	[27] = {{name = "energy-shield-equipment", count = 2, text = " Energy Shield MK1"}, {name = "poison-capsule", count = 50, text = " Poison-Capsule"}},
	[28] = {{name = "exoskeleton-equipment", count = 1, text = " Exoskelet"}, {name = "battery-mk2-equipment", count = 1, text = " Armor Battery Mk2"}},
	[29] = {{name = "distractor-capsule", count = 40, text = " Distractor Bots"}, {name = "personal-laser-defense-equipment", count = 2, text = " Personal Laser Defense"}},
	[30] = {{name = "fusion-reactor-equipment", count = 1, text = " Fusion Reactor"}, {name = "computer", count = 1, text = " Teleporter Computer"}},
	[31] = {{name = "uranium-rounds-magazine", count = 200, text = " Uranium Rounds"}, {name = "destroyer-capsule", count = 40, text = " Destroyer Capsules"}},
	[32] = {{name = "destroyer-capsule", count = 50, text = " Destroyer Bots"}},
	[33] = {{name = "power-armor-mk2", count = 1, text = " Power Armor MK2"}},
	[34] = {{name = "exoskeleton-equipment", count = 1, text = " Exoskeleton"}, {name = "uranium-rounds-magazine", count = 200, text = " Uranium Rounds"}},
	[35] = {{name = "energy-shield-mk2-equipment", count = 1, text = " Energy Shield MK2"}},
	[36] = {{name = "personal-roboport-mk2-equipment", count = 1, text = " Personal Roboport MK2"}},
	[37] = {{name = "personal-laser-defense-equipment", count = 2, text = " Personal Laser Defense"}},
	[38] = {{name = "fusion-reactor-equipment", count = 2, text = " Fusion Reactor"}, {name = "uranium-rounds-magazine", count = 400, text = " Uranium Rounds"}},
	[39] = {{name = "atomic-bomb", count = 10, text = " Atomic Rockets"}},
	[40] = {{name = "computer", count = 2, text = " Teleporter Computer"}, {name = "uranium-rounds-magazine", count = 500, text = " Uranium Rounds"}}
	}

local function create_reward_button(player)		
	if not player.gui.top.rewards then
		local b = player.gui.top.add({ type = "sprite-button", name = "rewards", sprite = "item/submachine-gun" })
		b.style.minimal_height = 38
		b.style.minimal_width = 38
		b.style.top_padding = 2
		b.style.left_padding = 4
		b.style.right_padding = 4
		b.style.bottom_padding = 2
	end
end

local function show_rewards(player)
	local get_score = Score.get_table().score_table
	if player.gui.left["rewards_panel"] then player.gui.left["rewards_panel"].destroy() end
	local frame = player.gui.left.add { type = "frame", name = "rewards_panel", direction = "vertical" }
	
	local current_level = global.rewards[player.name].level
	local next_level = current_level + 1
	local kill_score = get_score[player.force.name].players[player.name].killscore
	
	local next_level_score = ((3.5 + next_level)^2.7 / 10) * 100
	local min_score = ((3.5 + current_level)^2.7 / 10) * 100
	
	local t = frame.add { type = "table", column_count = 2}
	
	local l = t.add { type = "label", caption = "Combat Level: "}	
	l.style.font = "default-bold"			
	l.style.font_color = {r = 244, g = 212, b = 66}
	l.style.minimal_width = 100
	
	local str = "0"
	if global.rewards[player.name].level then str = tostring(current_level) end
	local l = t.add { type = "label", caption = str}
	l.style.font = "default-bold"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 123
	
	local t = frame.add { type = "table", column_count = 1}
	
	local l = t.add { type = "label", caption = "Progress to Next Level: "}
	l.style.font = "default-bold"			
	l.style.font_color = {r = 244, g = 212, b = 66}
	l.style.minimal_width = 123
	
	local t = frame.add { type = "table", column_count = 1}
	
	if kill_score then value = ((kill_score - min_score)/(floor(next_level_score)-min_score)) end
	local l = t.add { type = "progressbar", value = value}
	l.style.font = "default-bold"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 123
	
	local t = frame.add { type = "table", column_count = 1}
	
	local l = t.add { type = "label", caption = "Next Reward: "}
	l.style.font = "default-bold"			
	l.style.font_color = {r = 244, g = 212, b = 66}
	l.style.minimal_width = 123
	
	local t = frame.add { type = "table", column_count = 1}
	
	local leveled_list = {}
	for _, v in pairs(rewards_loot[next_level]) do
		local str = "0"
		if global.rewards[player.name].level then str = tostring(v.count .. " " .. v.text) end
		local l = t.add { type = "label", caption = str}
		l.style.font = "default-bold"
		l.style.font_color = { r=0.9, g=0.9, b=0.9}
		l.style.minimal_width = 123
	end


end

local function rewards_gui(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	
	local player = game.players[event.element.player_index]
	local name = event.element.name		
	
	if name == "rewards" then
		if player.gui.left["rewards_panel"] then
			player.gui.left["rewards_panel"].destroy()
		else
			show_rewards(player)
		end
		return
	end
end
	
-- Callback to trigger the player level
local callback =
    Token.register(
    function(data)
        if #data.pos_list < 1 then return end
		for i=1, #data.pos_list, 1 do
			if data.pos_list[i].distance >= data.run then
				local splash = data.surface.create_entity({name = "water-splash", position = data.pos_list[i].position})
			end
		end
    end
)

local function reward_messages(data)
	local player = data.player
	local item_rewards = data.rewards
	-- Check that the table isn't empty
	if #item_rewards < 1 then return end
	local print_text = ""
	local text_effect = player.surface.create_entity({name = "flying-text", position = {player.position.x, player.position.y}, text = "Reached Combat Level: " .. data.next_level, color = {r=0.2, g=1.0, b=0.1}})
	-- Loop through all of the rewards for this level and print out flying text
	for i=1, #item_rewards, 1 do
		local text_effect = player.surface.create_entity({name = "flying-text", position = {player.position.x, player.position.y + ((i*0.5))}, text = item_rewards[i].text, color = {r=1.0, g=1.0, b=1.0}})
		if i > 1 then
			print_text = item_rewards[i].text .. " " .. print_text
		else
			print_text = item_rewards[i].text
		end
	end
	player.print("[INFO] Kill Score Level " .. data.next_level .. " Achieved! Rewards: " .. print_text, { r=1.0, g=0.84, b=0.36})
end

local function kill_rewards(event)
	local get_score = Score.get_table().score_table
	if not event.cause then return end
	local player = event.cause.player
	local pinsert = player.insert
	local score = get_score[player.force.name]
	local kill_score = score.players[player.name].killscore
	
	-- If kill score isn't found don't run the other stuff
	if not kill_score then return end
	local surface = player.surface
	local center_position = surface.get_tile(player.position).position
	local current_level = global.rewards[player.name].level
	local next_level_score = ((3.5 + current_level+1)^2.7 / 10) * 100
	if kill_score >= next_level_score then
		local next_level = current_level + 1
		global.rewards[player.name].level = next_level
		-- Get item rewards for this level
		local leveled_list = {}
		for _, v in pairs(rewards_loot[next_level]) do
			insert(leveled_list, {text = "+" .. v.count .. v.text})
		end
		reward_messages({player = player, rewards = leveled_list, next_level = next_level})
		-- Insert Item rewards into players inventory
		for k, item in pairs(rewards_loot[next_level]) do
			local inserted_count = pinsert{name = item.name, count = item.count}
			-- Check if player inventory is full, store remaining rewards in table
			if (item.count - inserted_count) > 0 then
				local queue_pos = #global.inventory_queue[player.name].items
				surface.spill_item_stack(center_position,{name = item.name, count = (item.count - inserted_count)},true)
				player.print("[WARNING] Inventory Full, Rewards Dropped", { r=1.0, g=0.0, b=0.0})
			end
		end
		-- Creates the level up effect in a radius
		for i = 1, 5, 1 do
			local area = {}
			local pos_list = {}
			area = {left_top = {x = (center_position.x - i), y = (center_position.y - i)}, right_bottom = {x = (center_position.x + i + 1), y = (center_position.y + i + 1)}}
			for _, t in pairs(surface.find_tiles_filtered{area = area}) do
				local distance = floor(sqrt((center_position.x - t.position.x)^2 + (center_position.y - t.position.y)^2))
				if (distance <= i) then
					insert(pos_list, {position = {t.position.x+1, t.position.y+1}, distance = distance})
				end
			end
		-- Sets each new timer for each tile expansions loop
		Task.set_timeout_in_ticks(10+i*10, callback, {pos_list = pos_list, surface = surface, run = i})
		end
	end
	
	-- Refresh GUI
	if event.cause then
		if event.cause.player then
			if event.cause.player.gui.left["rewards_panel"] then
				show_rewards(event.cause.player)
			end
		end
	end
end

local function check_data(event)
	local player = game.players[event.player_index]
	if not global.rewards then global.rewards = {} end
	if not global.rewards[player.name] then global.rewards[player.name] = {level = 0} end
	if not global.inventory_queue then global.inventory_queue = {} end
	if not global.inventory_queue[player.name] then global.inventory_queue[player.name] = {items = {}} end
	
	create_reward_button(player)
end

Event.add(defines.events.on_entity_died, kill_rewards)
Event.add(defines.events.on_player_joined_game, check_data)
Event.add(defines.events.on_gui_click, rewards_gui)
