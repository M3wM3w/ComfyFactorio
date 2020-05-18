-- luacheck: ignore
--antigrief things made by mewmew
--modified by gerkiz--
--as an admin, write either /trust or /untrust and the players name in the chat to grant/revoke immunity from protection

local event = require 'utils.event'
local session = require 'utils.session_data'
local Server = require 'utils.server'

--[[
local function create_admin_button(player)
	if player.gui.top["admin_button"] then return end
	local b = player.gui.top.add({type = "button", caption = "Admin", name = "admin_button", tooltip = "Use your powers wisely"})
	b.style.font_color = {r = 0.1, g = 0.1, b = 0.1}
	b.style.font = "default-bold"
	b.style.minimal_height = 38
	b.style.minimal_width = 54
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.admin == true then
		create_admin_button(player)
	end
end

local function on_player_promoted(event)
	local player = game.players[event.player_index]
	create_admin_button(player)
end

local function on_player_demoted(event)
	local player = game.players[event.player_index]
	if player.gui.top["admin_button"] then player.gui.top["admin_button"].destroy() end
	if player.gui.left["admin_panel"] then player.gui.left["admin_panel"].destroy() end
end
]]

local function on_marked_for_deconstruction(event)
	local tracker = session.get_session_table()
	local trusted = session.get_trusted_table()
	if not event.player_index then return end
	local player = game.players[event.player_index]
	if player.admin == true then return end
	if trusted[player.name] == true then return end

	local playtime = player.online_time
		if tracker[player.name] then
			playtime = player.online_time + tracker[player.name]
		end
	if playtime < 2592000 then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)	
		player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
	end
end

local function on_player_ammo_inventory_changed(event)
	local tracker = session.get_session_table()
	local trusted = session.get_trusted_table()
	local player = game.players[event.player_index]
	if player.admin == true then return end
	if trusted[player.name] == true then return end

	local playtime = player.online_time
	if tracker[player.name] then
		playtime = player.online_time + tracker[player.name]
	end
	if playtime < 1296000 then
		local nukes = player.remove_item({name="atomic-bomb", count=1000})
		if nukes > 0 then
			player.surface.spill_item_stack(player.position, {name = "atomic-bomb", count = nukes}, false)
			player.print("You have not grown accustomed to this technology yet.", {r=0.22, g=0.99, b=0.99})
			Server.to_discord_bold(table.concat{'[Nuke] ' .. player.name .. ' tried to equip nukes but was not trusted.'})
			player.character.health = 0
		end
	end
end

local function on_player_built_tile(event)
	local tracker = session.get_session_table()
	local trusted = session.get_trusted_table()
	local placed_tiles = event.tiles
	if placed_tiles[1].old_tile.name ~= "deepwater" and placed_tiles[1].old_tile.name ~= "water" and placed_tiles[1].old_tile.name ~= "water-green" then return end
	local player = game.players[event.player_index]

	--[[
	if not player.admin and not trusted[player.name] then
		local playtime = player.online_time
		if tracker[player.name] then
			playtime = player.online_time + tracker[player.name][1]
		end
		if playtime < 648000 then
			local tiles = {}
			for _, t in pairs(placed_tiles) do
				table.insert(tiles, {name = t.old_tile.name, position = t.position})
			end
			player.insert({name = "landfill", count = #placed_tiles})
			player.surface.set_tiles(tiles, true)
			player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
		end
	end]]

	--landfill history--
	if not global.landfill_history then global.landfill_history = {} end
	if #global.landfill_history > 999 then global.landfill_history = {} end
	local str = player.name .. " at X:"
	str = str .. placed_tiles[1].position.x
	str = str .. " Y:"
	str = str .. placed_tiles[1].position.y
	table.insert(global.landfill_history, str)				
end

local function on_built_entity(event)
	local tracker = session.get_session_table()
	local trusted = session.get_trusted_table()
	if game.tick < 1296000 then return end
	
	if event.created_entity.type == "entity-ghost" then
		local player = game.players[event.player_index]
		
		if player.admin == true then return end
		if trusted[player.name] == true then return end
		
		local playtime = player.online_time
		if tracker[player.name] then
			playtime = player.online_time + tracker[player.name]
		end
		
		if playtime < 432000 then
			event.created_entity.destroy()
			player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
		end		
	end
end

--Artillery History and Antigrief
local function on_player_used_capsule(event)
	local tracker = session.get_session_table()
	local trusted = session.get_trusted_table()
	local player = game.players[event.player_index]
	local position = event.position
	local used_item = event.item			
	if used_item.name ~= "artillery-targeting-remote" then return end	
	
	local playtime = player.online_time
	if tracker[player.name] then
		playtime = player.online_time + tracker[player.name]
	end
	if playtime < 1296000 and player.admin == false and trusted[player.name] == false then	
		player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
		local area = {{position.x - 1, position.y - 1},{position.x + 1, position.y + 1}}
		local entities = player.surface.find_entities_filtered({area = area, name = "artillery-flare"})
		for _, e in pairs(entities) do			
			e.destroy()		
		end
		return
	end	
	
	if not global.artillery_history then global.artillery_history = {} end
	if #global.artillery_history > 999 then global.artillery_history = {} end
	local str = player.name .. " at X:"
	str = str .. math.floor(position.x)
	str = str .. " Y:"
	str = str .. math.floor(position.y)
	table.insert(global.artillery_history, str)	
end

local blacklisted_types = {
	["transport-belt"] = true,
	["wall"] = true,
	["underground-belt"] = true,
	["inserter"] = true,
	["land-mine"] = true,
	["gate"] = true,
	["lamp"] = true,
	["mining-drill"] = true,
	["splitter"] = true	
}

--Friendly Fire History
local function on_entity_died(event)
	if not event.cause then return end
	if event.cause.name ~= "character" then return end	
	if event.cause.force.name ~= event.entity.force.name then return end
	if blacklisted_types[event.entity.type] then return end
	local player = event.cause.player		
	if not global.friendly_fire_history then global.friendly_fire_history = {} end
	if #global.friendly_fire_history > 999 then global.friendly_fire_history = {} end
	if not player then return end
	local str = player.name .. " destroyed "
	str = str .. event.entity.name
	str = str .. " at X:"	
	str = str .. math.floor(event.entity.position.x)
	str = str .. " Y:"
	str = str .. math.floor(event.entity.position.y)
	
	global.friendly_fire_history[#global.friendly_fire_history + 1] = str	
end

local chest_types = {
	["container"] = true,
	["logistic-container"] = true
}

--Bad Fire History
local function on_entity_died_do_actual_usefull_logging(event)
	if not event.cause then return end
	if event.cause.name ~= "character" then return end
	local player = event.cause.player
	if not player then return end
	if not chest_types[event.entity.type] then return end

	if event.entity.get_item_count("explosives") < 100 then return end

	if not global.bad_fire_history then global.bad_fire_history = {} end
	if #global.bad_fire_history > 999 then global.bad_fire_history = {} end

	local str = player.name .. " destroyed container with explosives amount: " .. event.entity.get_item_count("explosives") .. ", at location: "
	str = str .. " at X:" .. event.entity.position.x .. " Y:" .. event.entity.position.y

	global.bad_fire_history[#global.bad_fire_history + 1] = str
end

--Mining Thieves History
local function on_player_mined_entity(event)
	if not event.entity.last_user then return end
	local player = game.players[event.player_index]
	if event.entity.last_user.name == player.name then return end
	if event.entity.force.name ~= player.force.name then return end
	if blacklisted_types[event.entity.type] then return end
		 	
	if not global.mining_history then global.mining_history = {} end
	if #global.mining_history > 999 then global.mining_history = {} end
	
	local str = player.name .. " mined "
	str = str .. event.entity.name
	str = str .. " at X:"	
	str = str .. math.floor(event.entity.position.x)
	str = str .. " Y:"
	str = str .. math.floor(event.entity.position.y)
	
	global.mining_history[#global.mining_history + 1] = str	
end

local function on_gui_opened(event)
	if not event.entity then return end
	if event.entity.name ~= "character-corpse" then return end
	local player = game.players[event.player_index]
	local corpse_owner = game.players[event.entity.character_corpse_player_index]
	if not corpse_owner then return end
	if corpse_owner.force.name ~= player.force.name then return end
	if player.name ~= corpse_owner.name then
		game.print(player.name .. " is looting " .. corpse_owner.name .. "´s body.", { r=0.85, g=0.85, b=0.85})
		Server.to_discord_bold(table.concat{'[Corpse] ' .. player.name .. " is looting " .. corpse_owner.name .. "´s body."})
	end
end

local function on_pre_player_mined_item(event)
	if event.entity.name ~= "character-corpse" then return end
	local player = game.players[event.player_index]
	local corpse_owner = game.players[event.entity.character_corpse_player_index]
	if not corpse_owner then return end
	if corpse_owner.force.name ~= player.force.name then return end
	if player.name ~= corpse_owner.name then
		game.print(player.name .. " has looted " .. corpse_owner.name .. "´s body.", { r=0.85, g=0.85, b=0.85})
		Server.to_discord_bold(table.concat{'[Corpse] ' .. player.name .. " has looted " .. corpse_owner.name .. "´s body."})
	end
end

event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_entity_died, on_entity_died_do_actual_usefull_logging)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_gui_opened, on_gui_opened)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
--event.add(defines.events.on_player_demoted, on_player_demoted)
--event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
--event.add(defines.events.on_player_promoted, on_player_promoted)
event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
