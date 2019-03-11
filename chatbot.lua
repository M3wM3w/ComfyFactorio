local event = require 'utils.event'
local message_color = {r = 0.5, g = 0.3, b = 1}

local brain = {
	[1] = {"Our Discord server is at https://comfyplay.net/discord"},
	[2] = {"Need an admin? Type @Mods in game chat to notify moderators,", "or put a message in the discord help channel."}
}

local links = {
	["discord"] = brain[1],
	["admin"] = brain[2],
	["administrator"] = brain[2],
	["mod"] = brain[2],
	["moderator"] = brain[2],
	["grief"] = brain[2],
	["troll"] = brain[2],
	["trolling"] = brain[2],
	["stealing"] = brain[2],
	["stole"] = brain[2],
	["griefer"] = brain[2],
	["greifer"] = brain[2]
}

local function on_player_created(event)
	local player = game.players[event.player_index]
	player.print("Join the comfy discord >> comfyplay.net/discord", message_color)
end

local function process_custom_commands(event)	
	local player = game.players[event.player_index]
	if player.admin == false then return end 
	for word in string.gmatch(string.lower(event.message), "%g+") do
		if word == "trust" or word == "regular" then
			for word in string.gmatch(event.message, "%g+") do
				if game.players[word] then
					global.trusted_players[word] = true
					game.print(word .. " is now a trusted player.", {r=0.22, g=0.99, b=0.99}) 					
				end
			end
			return
		end
		if word == "untrust" then
			for word in string.gmatch(event.message, "%g+") do
				if game.players[word] then
					global.trusted_players[word] = false
					game.print(word .. " is no longer a trusted player.", {r=0.22, g=0.99, b=0.99}) 					
				end
			end
			return
		end
	end
end

local function process_bot_answers(event)
	local player = game.players[event.player_index]
	if player.admin == true then return end 
	local message = event.message
	message = string.lower(message)
	for word in string.gmatch(message, "%g+") do
		if links[word] then
			local player = game.players[event.player_index]
			for _, bot_answer in pairs(links[word]) do
				player.print(bot_answer, message_color)
			end
			return
		end
	end
end

local function on_console_chat(event)
	if not event.player_index then return end
	process_custom_commands(event)
	process_bot_answers(event)	
end

--share vision of silent-commands with other admins
local function on_console_command(event)		
	if event.command ~= "silent-command" then return end
	if not event.player_index then return end
	local player = game.players[event.player_index]	
	for _, p in pairs(game.connected_players) do
		if p.admin == true and p.name ~= player.name then
			p.print(player.name .. " did a silent-command: " .. event.parameters, {r=0.22, g=0.99, b=0.99})
			log(player.name .. " did a silent-command: " .. event.parameters)
		end
	end		
end

event.add(defines.events.on_player_created, on_player_created)
event.add(defines.events.on_console_chat, on_console_chat)
event.add(defines.events.on_console_command, on_console_command)
