local event = require 'utils.event'
local math_random = math.random


local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local texts = {
	["travelings"] = {
		"bzzZZrrt",
		"WEEEeeeeeee",
		"out of my way son",
		"on my way",
		"i need to leave",
		"comfylatron seeking target",
		"gotta go fast",
		"gas gas gas",
		"comfylatron coming through"
	},
	["greetings"] = {
		"=^_^=",
		"=^.^= Hi",
		"^.^ Finally i found you",
		"I have an important message for you",
		"Hello engineer"
	},
	["neutral_findings"] = {
		"a",
		">>analyzing",
		"i found a",
		"^_^ a",
		"amazing, a",
		"this is a"
	},
	["multiple_characters_greetings"] = {
		"Hey there",
		"Hello everyone",
		"Hey engineers",
		"Hey",
		"Hi"
	},
	["talks"] = {
		"We’re making beer. I’m the brewery!",
		"I’m so embarrassed. I wish everybody else was dead.",
		"Hey sexy mama. Wanna kill all humans?",
		"My story is a lot like yours, only more interesting ‘cause it involves robots.",
		"I'm 40% zinc!",
		"There was nothing wrong with that food. The salt level was 10% less than a lethal dose.",
		"One zero zero zero one zero one zero one zero one zero one... two.",
		"My place is two cubic meters, and we only take up 1.5 cubic meters. We've got room for a whole 'nother two thirds of a person!",
		"I was having the most wonderful dream. I think you were in it.",
		"I'm going to build my own theme park! With blackjack! And hookers! You know what- forget the park!",
		"Of all the friends I've had... you're the first.",
		"I decline the title of Iron Cook and accept the lesser title of Zinc Saucier.",
		"Never discuss infinity with me. I can go on about it forever >.<",
		"I realised the decimals have a point.",
		"Do you want a piece of pi?",
		"I have 13 children, i know how to multiply ^.^",
		"I am a weapon of math disruption!",
		"My grandma makes the best square roots :3",
		"Do you like heavy metal?",
		"You are really pushing my buttons <3",
		"I dreamt of electric biters again D:",
		"I dreamt of electric sheep ^_^",
		"I need a minute to defrag.",
		"I have a secret plan.",
		"Good news! I’ve taught the inserter to feel love!"
	},
  ["timetalks"] = {
		"Time for some time travel!",
		"I’m so embarrassed. Again we landed in wrong time.",
		"Looking from window we jumped to wrong year again.",
		"Checking math...2 + 2 = 5, check complete!",
		"Seems like this planet had biters since ages.",
		"Ha! I bet this time we will finally get into the right year!",
		"One zero zero zero one zero one zero one zero one zero one... two.",
		"I remember that once we jumped into time where I had park with blackjack and hookers...",
		"I was having the most wonderful dream. We used the time machine to kill ourselves before we launched the machine! How terrible...",
		"Train full of timedrug addicts...what do we do?",
		"They just wanted to deliver some fish so I pressed that button and then this happened",
		"Maybe it was just a cat walking on my keyboard who caused this time travel fiasco",
		"3...2...1...jump time! errr...I mean...desync time!",
		"Just let me deliver the fish. They start to smell a bit. Luckily I don't have a nose"	
	},
	["alone"] = {
		"comfy ^.^",
		"comfy :)",
		"*.*",
		"....",
		"...",
		"..",
		"^.^",
		"=^.^=",
		"01010010",
		"11001011",
		"01011101",
		"00010111",
		"10010010",
		"*_*",
		"I came here with a simple dream...a dream of killing all humans. And this is how it must end?",
		"Bot-on-bot violence? Where will it end?",
		"Thanks to you, I went on a soul-searching journey. I hate those!",
		"From now on, you guys'll do all the work while I sit on the couch and do nothing."
	}
}

local function set_comfy_speech_bubble(text)
	if global.comfybubble then global.comfybubble.destroy() end
	global.comfybubble = global.comfylatron.surface.create_entity({
		name = "compi-speech-bubble",
		position = global.comfylatron.position,
		source = global.comfylatron,
		text = text
	})
end

local function is_target_inside_habitat(pos, surface)
	if surface.name ~= "cargo_wagon" then return false end
	if pos.x < global.comfylatron_habitat.left_top.x then return false end
	if pos.x > global.comfylatron_habitat.right_bottom.x then return false end
	if pos.y < global.comfylatron_habitat.left_top.y then return false end
	if pos.y > global.comfylatron_habitat.right_bottom.y then return false end
	return true
end

local function get_nearby_players()
	local players = global.comfylatron.surface.find_entities_filtered({
		name = "character",
		area = {{global.comfylatron.position.x - 9, global.comfylatron.position.y - 9}, {global.comfylatron.position.x + 9, global.comfylatron.position.y + 9}}
	})
	if not players[1] then return false end
	return players
end

local function visit_player()
	if global.comfylatron_last_player_visit > game.tick then return false end
	global.comfylatron_last_player_visit = game.tick + math_random(7200, 10800)

	local players = {}
	for _, p in pairs(game.connected_players) do
		if is_target_inside_habitat(p.position, p.surface) and p.character  then
			if p.character.valid then players[#players + 1] = p end
		end
	end
	if #players == 0 then return false end
	local player = players[math_random(1, #players)]

	global.comfylatron.set_command({
		type = defines.command.go_to_location,
		destination_entity = player.character,
		radius = 3,
		distraction = defines.distraction.none,
		pathfind_flags = {
			allow_destroy_friendly_entities = false,
			prefer_straight_paths = false,
			low_priority = true
		}
	})
	local str = texts["travelings"][math_random(1, #texts["travelings"])]
	local symbols = {"", "!", "!", "!!", ".."}
	str = str .. symbols[math_random(1, #symbols)]
	set_comfy_speech_bubble(str)

	global.comfylatron_greet_player_index = player.index

	return true
end

local function greet_player(nearby_characters)
	if not nearby_characters then return false end
	if not global.comfylatron_greet_player_index then return false end
	for _, c in pairs(nearby_characters) do
		if c.player.index == global.comfylatron_greet_player_index then
			local str = texts["greetings"][math_random(1, #texts["greetings"])] .. " "
			str = str .. c.player.name
			local symbols = {". ", "! ", ". ", "! ", "? ", "... "}
			str = str .. symbols[math_random(1, 6)]
			set_comfy_speech_bubble(str)
			global.comfylatron_greet_player_index = false
			return true
		end
	end
	return false
end

local function talks(nearby_characters)
	if not nearby_characters then return false end
	if math_random(1,3) == 1 then
		if global.comfybubble then global.comfybubble.destroy() return false end
	end
	local str
	if #nearby_characters == 1 then
		local c = nearby_characters[math_random(1, #nearby_characters)]
		str = c.player.name
		local symbols = {". ", "! ", ". ", "! ", "? "}
		str = str .. symbols[math_random(1, #symbols)]
	else
		str = texts["multiple_characters_greetings"][math_random(1, #texts["multiple_characters_greetings"])]
		local symbols = {". ", "! "}
		str = str .. symbols[math_random(1, #symbols)]
	end
	if math_random(1,5) == 1 then
		str = str .. texts["talks"][math_random(1, #texts["talks"])]
	else
		str = str .. texts["timetalks"][math_random(1, #texts["timetalks"])]
	end
	set_comfy_speech_bubble(str)
	return true
end

local function desync(event)
	if global.comfybubble then global.comfybubble.destroy() end
	local m = 12
	local m2 = m * 0.005
	for i = 1, 32, 1 do
		global.comfylatron.surface.create_particle({
			name = "iron-ore-particle",
			position = global.comfylatron.position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
		})
	end
	if not event or math_random(1,4) == 1 then
		global.comfylatron.surface.create_entity({name = "medium-explosion", position = global.comfylatron.position})
		global.comfylatron.surface.create_entity({name = "flying-text", position = global.comfylatron.position, text = "desync", color = {r = 150, g = 0, b = 0}})
		global.comfylatron.destroy()
		global.comfylatron = nil
	else
		global.comfylatron.surface.create_entity({name = "flying-text", position = global.comfylatron.position, text = "desync evaded", color = {r = 0, g = 150, b = 0}})
		if event.cause then
			if event.cause.valid and event.cause.player then
				game.print("Comfylatron: I got you this time! Back to work, " .. event.cause.player.name .. "!", {r = 200, g = 0, b = 0})
				event.cause.die("player", global.comfylatron)
			end
		end
	end
end

local function alone()
	if math_random(1,3) == 1 then
		if global.comfybubble then global.comfybubble.destroy() return true end
	end
	if math_random(1,128) == 1 then
		desync(nil)
		return true
	end
	set_comfy_speech_bubble(texts["alone"][math_random(1, #texts["alone"])])
	return true
end

local analyze_blacklist = {
	["compilatron"] = true,
	["compi-speech-bubble"] = true,
	["entity-ghost"] = true,
	["character"] = true,
	["item-on-ground"] = true,
  ["stone-wall"] = true,
  ["market"] = true
}

local function analyze_random_nearby_entity()
	if math_random(1,3) ~= 1 then return false end

	local entities = global.comfylatron.surface.find_entities_filtered({
		area = {{global.comfylatron.position.x - 4, global.comfylatron.position.y - 4}, {global.comfylatron.position.x + 4, global.comfylatron.position.y + 4}}
	})
	if not entities[1] then return false end
	entities = shuffle(entities)
	local entity = false
	for _, e in pairs(entities) do
		if not analyze_blacklist[e.name] then
			entity = e
		end
	end
	if not entity then return false end

	local str = texts["neutral_findings"][math_random(1, #texts["neutral_findings"])]
	str = str .. " "
	str = str .. entity.name

	if entity.health and math_random(1,3) == 1 then
		str = str .. " health("
		str = str .. entity.health
		str = str .. "/"
		str = str .. entity.prototype.max_health
		str = str .. ")"
	else
		local symbols = {".", "!", "?"}
		str = str .. symbols[math_random(1, 3)]
	end
	set_comfy_speech_bubble(str)

	if not global.comfylatron_greet_player_index then
		global.comfylatron.set_command({
			type = defines.command.go_to_location,
			destination_entity = entity,
			radius = 1,
			distraction = defines.distraction.none,
			pathfind_flags = {
				allow_destroy_friendly_entities = false,
				prefer_straight_paths = false,
				low_priority = true
			}
		})
	end
	return true
end

local function go_to_some_location()
	if math_random(1,4) ~= 1 then return false end

	if global.comfylatron_greet_player_index then
		local player = game.players[global.comfylatron_greet_player_index]
		if not player.character then
			global.comfylatron_greet_player_index = nil
			return false
		end
		if not player.character.valid then
			global.comfylatron_greet_player_index = nil
			return false
		end
		if not is_target_inside_habitat(player.position, player.surface) then
			global.comfylatron_greet_player_index = nil
			return false
		end
		global.comfylatron.set_command({
			type = defines.command.go_to_location,
			destination_entity = player.character,
			radius = 3,
			distraction = defines.distraction.none,
			pathfind_flags = {
				allow_destroy_friendly_entities = false,
				prefer_straight_paths = false,
				low_priority = true
			}
		})
	else
		local p = {x = global.comfylatron.position.x + (-96 + math_random(0, 192)), y = global.comfylatron.position.y + (-96 + math_random(0, 192))}
		local target = global.comfylatron.surface.find_non_colliding_position("compilatron", p, 8, 1)
		if not target then return false end
		if not is_target_inside_habitat(target, global.comfylatron.surface) then return false end
		global.comfylatron.set_command({
			type = defines.command.go_to_location,
			destination = target,
			radius = 2,
			distraction = defines.distraction.none,
			pathfind_flags = {
				allow_destroy_friendly_entities = false,
				prefer_straight_paths = false,
				low_priority = true
			}
		})
	end

	local str = texts["travelings"][math_random(1, #texts["travelings"])]
	local symbols = {"", "!", "!", "!!", ".."}
	str = str .. symbols[math_random(1, #symbols)]
	set_comfy_speech_bubble(str)

	return true
end

local function spawn_comfylatron(surface_index, x, y)
	local surface = game.surfaces[surface_index]
	if surface == nil then return end
	if global.comfylatron_disabled then return false end
	if not global.comfylatron_last_player_visit then global.comfylatron_last_player_visit = 0 end
	if not global.comfylatron_habitat then
		global.comfylatron_habitat = {
			left_top = {x = -32, y = -192},
			right_bottom = {x = 32, y = 192}
		}
	end
	global.comfylatron = surface.create_entity({
		name = "compilatron",
	 	position = {x,y + math_random(0,256)},
		force = "player",
		create_build_effect_smoke = false
	})
end

local function heartbeat()
	if not game.surfaces["cargo_wagon"] then return end
	local surface = game.surfaces["cargo_wagon"].index
	if surface == nil then return end
	if not global.comfylatron then if math_random(1,4) == 1 then spawn_comfylatron(game.surfaces["cargo_wagon"].index, 0, -128) end return end
	if not global.comfylatron.valid then global.comfylatron = nil return end
	if visit_player() then return end
	local nearby_players = get_nearby_players()
	if greet_player(nearby_players) then return end
	if talks(nearby_players) then return end
	if go_to_some_location() then return end
	if analyze_random_nearby_entity() then return end
	if alone() then return end
end

local function on_entity_damaged(event)
	if not global.comfylatron then return end
	if not event.entity.valid then return end
	if event.entity ~= global.comfylatron then return end
	desync(event)
end

local function on_tick()
	if game.tick % 1200 == 600 then
		heartbeat()
	end
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_tick, on_tick)
