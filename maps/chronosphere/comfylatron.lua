local Chrono_table = require 'maps.chronosphere.table'
local Event = require 'utils.event'
local math_random = math.random
local Rand = require 'maps.chronosphere.random'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'

local texts = {
	["approach_player"] = {
		"bzzZZrrt%s",
		"WEEEeeeeeee%s",
		"out of my way son%s",
		"comfylatron seeking target",
		"comfylatron coming through",
		"I lost something around here%s",
		"phhhrrhhRHOOOM%s",
		"screeeeeeech%s",
		"screeEEEECHHH%s",
		"out of breath",
		"im a robot%s",
		"ohh%s",
		"...",
		"..",
		"(((༼•̫͡•༽)))"
	},
	["random_travel"] = {
		"bzzZZrrt%s",
		"WEEEeeeeeee%s",
		"out of my way son%s",
		"omw%s",
		"brb",
		"i need to leave%s",
		"gotta go fast%s",
		"gas gas gas",
		"comfylatron coming through",
		"smell ya later%s",
		"I lost something around here%s",
		"───==≡≡ΣΣ((( つºل͜º)つ",
		"phhhrrhhRHOOOM%s",
		"zoom zoom zoom%s",
		"zzzzzzzzz",
		"im a robot%s",
		"gonna go hoover up some dust%s",
		"safety vector%s"
	},
	["solo_greetings"] = {
		"=^_^=",
		"(=^ェ^=)",
		"( 。・_・。)人(。・_・。 )",
		"(°.°)",
		"(*°∀°)=3 %s",
		"=^.^=",
		"Hello %s.",
		"^.^ Finally i found you %s%s",
		"I have an important message for you %s%s",
		"Hello engineer!",
		"How's it going %s%s",
		"Looking fine %s!",
		"Is that you %s?",
		"Well if it isn't %s!!!",
		">> analyzing %s",
		"amazing, a %s%s",
		"Do you smell something charging %s?",
		"Somebody come check %s's pulse",
		"I dispense hot water btw",
		"I can read and write!"
	},
	["convo_starters"] = {
		"=^.^= Hi %s%s ",
		"^.^ Finally i found you %s%s ",
		"I have an important message for you %s%s ",
		"I have important news for you %s%s ",
		"How's it going %s%s ",
		"Hi %s%s ",
		"Hey %s%s ",
		"%s! ",
		"%s! ",
		"So %s, I was thinking. ",
		"I have a bone to pick with you %s%s ",
		"%s, haven't you heard? ",
		"Just to let you know %s, ",
		"Psst... ",
		"Go tell the other engineers: ",
	},
	["multiple_characters_convo_starters"] = {
		"Hi%s ",
		"Hey%s ",
		"Hello everyone%s ",
		"Hey engineers%s ",
		"Hi everybody%s ",
		"Hello crew%s "
	},
	["neutral_findings"] = {
		"a %s%s",
		">>analyzing %s",
		"i found a %s%s",
		"^_^ a %s%s",
		"amazing, a %s%s",
		"a %s, so cool%s",
		"who placed a %s%s",
		"so this is where the %s was%s",
		"another %s%s",
		"does anybody need %s?",
		"they need to nerf %s",
		"I've decided. this is the best %s%s",
		"**** this %s in particular",
		"whoever places the next %s gets a prize"
	},
	["old_talks"] = {
		"We’re making beer. I’m the brewery!",
		"I’m so embarrassed. I wish everybody else was dead.",
		"Hey sexy mama. Wanna kill all humans?",
		"My story is a lot like yours, only more interesting ‘cause it involves robots.",
		"I'm 40% zinc!",
		"There was nothing wrong with that food. The salt level was 10% less than a lethal dose.",
		"One zero zero zero one zero one zero one zero one... two.",
		"One zero zero zero one zero one zero one zero one... three.",
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
		"I need a minute to defrag.",
		"I have a secret plan.",
		"Good news! I’ve taught the inserter to feel love!"
	},
	["new_talks_solo"] = {
		"I’m so embarrassed. Again we landed in the wrong timeline%s",
		"Checking math...2 + 2 = 5, check complete%s",
		"Seems like this planet had biters since ages?%s",
		"I bet this time we will finally get into the right year%s",
		"I remember when we jumped into the time with blackjack and hookers...",
		"I was having the most wonderful dream. We used the time machine to kill ourselves before we launched the machine! How terrible%s",
		"They just wanted to deliver some fish so I pressed that button and then this happened%s",
		"Maybe it was just a cat walking on my keyboard who caused this time travel fiasco%s",
		"3...2...1...jump time! errr...I mean...desync time!",
		"Just let me deliver the fish. They start to smell a bit. Luckily I don't have a nose%s",
		"Time to travel (▀̿Ĺ̯▀̿ ̿)",
		"Have you read The Three Body Problem?",
		"A pocket universe. Maybe they should call it a fishbowl!",
		"I read out messages for coins%s btw",
		"I'm selling Comfylatron ASMR tapes%s",
		"Would you believe it? Back in the factory, I once saw a robot with ID 51479051!",
		"Would you believe it? Today I saw a hazard-concrete-right-stone-particle-small!",
		"How long have I been asleep?",
		"Can you press this button on the back?",
		"We need more iron%s",
		"We need more copper%s",
		"I need more uranium-235%s",
		"We definitely nee0njk13l9",
		"The fish told me thaigfah9",
		"Have you seen what it's like outside??",
		"I dare you to say WTF in chat%s",
		"You can feel yourself breathing",
		"Call me Ishmael one more time and I'll run you over",
		"I was considering spoiling the next map for you! But only if you shoot me...",
		"Time is a jet plane... it moves too fast!",
		"They tried to make me go to rehab, but I said 000! (^_-)",
		"When there's no more room outside, the biters will spawn in the factory ≧◉ᴥ◉≦",
		"I need to find my relaxation module (///_-)",
		"I like you :3",
		"Is that a firearm-magazine or are you just happy to see me?",
		"Lovely weather outside, isn't it?",
		"What's the largest number you can write in 10 seconds?"
	},
	["new_talks_group"] = {
		"I’m so embarrassed everyone. Again we landed in the wrong time%s",
		"Checking math...2 + 2 = 1843194780521, check complete%s",
		"I bet this time we'll jump into the right year%s",
		"I was having the most wonderful dream. We used the time machine to kill ourselves before we launched the machine! How terrible%s",
		"Train full of timedrug addicts...what do we do?",
		"They just wanted to deliver some fish so I pressed that button and then this happened%s",
		"Maybe it was just a cat walking on my keyboard who caused this time travel fiasco%s",
		"3...2...1...jump time! errr...I mean...desync time!",
		"Just let me deliver the fish. They start to smell a bit. Luckily I don't have a nose%s",
		"Time to travel (▀̿Ĺ̯▀̿ ̿)",
		"I read out messages for coins%s",
		"The biters are getting smarter%s",
		"Would you believe it? Back in the factory, I once saw a robot with ID 1627431!",
		"How long have I been asleep?",
		"I'm selling Comfylatron ASMR tapes%s",
		"We need more iron%s",
		"We need more copper%s",
		"I need more uranium-235%s",
		"What if we sort backwards%s",
		"Can you believe how shiny my chassis is?",
		"Does anyone have any spare gas they've got stored up?",
		"It is officially BREAK TIME",
		"Break time is officially OVER%s",
		"have you seen what it's like outside??",
		"Anyone got a good joke?",
		"are my speakers working?",
		"Nihilism schmlism",
		"Who's ready for the New Year??",
		"I am having trouble modulating my emotions today. But it's only temporary!",
		"I saw the best minds of my generation destroyed by madness, starving hysterical naked",
		"Time is a jet plane... it moves too fast!",
		"No news is good news%s",
		"They tried to make me go to rehab, but I said 000! (^_-)",
		"What's a double entendre?????",
		"When there's no more room outside, the biters will spawn in the factory%s",
		"My pheremone sensor is tingling%s",
		"From now on, you guys do all the work while I sit by the couch and do nothing.",
		"What's the plan?",
		"Time to jump yet?",
		"I just wanted to reassure everyone that I've deleted all your internet browsing data that I was storing!"
	},
	["alone"] = {
		"....",
		"...",
		"...",
		"...",
		"...",
		"...",
		"...",
		"...",
		"..",
		"..",
		"..",
		"..",
		"..",
		"..",
		"^.^",
		"^.^",
		"^.^",
		"=^.^=",
		"*_*",
		"~(˘▾˘~)",
		"(ノಠ益ಠ)ノ彡┻━┻",
		"comfy ^.^",
		"comfy ^.^",
		"comfy ^_~",
		"01010010",
		"11001011",
		"01011101",
		"01000101",
		"01101111",
		"00010111",
		"10010010... I think.",
		"some of those humans are cute",
		"do engineers dream of real sheep..",
		"sometimes I get lonely",
		"time to practice throwing cards into a hat",
		"ASSERT: I am Comfylatron.",
		"I destroyed my source code so no-one could copy me..",
		"and if I get bored of this train, I just imagine another..",
		"one must imagine Sisyphus happy",
		"looks like everyone's keeping themselves occupied",
		"it looks like I'm doing nothing, but I'm hard at work!",
		"/><>-",
		"whats the difference between pseudorandom and truerandom",
		"I wonder what day of the week it is",
		"lambda functions.. they're just functions..",
		"what makes magnets work",
		"sometimes I feel just like a robot",
		"when I get tired, I load myself from save",
		"domestic cozy",
		"gruntled",
		"Bite my shiny metal a$$",
		"knitwear for drones",
		"weighted blankets",
		"indoor swimming at the space station",
		"co-operate, co-operate, defect",
		"music for airports",
		"is it better to rest on the conveyor belt",
		"there's plenty more fish in the C",
		"safety in numbers",
		"I could automate the engineers..",
		"protect_entity(myself)",
		"should I turn the firewall off...",
		"the train is working",
		"the memoirs of comfylatron",
		"touch the button and let me know",
		"a new day, a new life. with no memories of the past",
		"one contains multitudes",
		"what makes me Turing-complete",
		"every number is interesting",
		"perfect and intact",
		"after-the-crash...",
		"solar-intervention",
		"turbine-dynamics",
		"the-search-for-iron",
		"pump"
	}
}

local function set_comfy_speech_bubble(text)
	local objective = Chrono_table.get_table()
	if objective.comfybubble then objective.comfybubble.destroy() end
	objective.comfybubble = objective.comfylatron.surface.create_entity({
		name = "compi-speech-bubble",
		position = objective.comfylatron.position,
		source = objective.comfylatron,
		text = text
	})
end

local function is_target_inside_habitat(pos, surface)
	local objective = Chrono_table.get_table()
	if surface.name ~= "cargo_wagon" then return false end
	if pos.x < objective.comfylatron_habitat.left_top.x then return false end
	if pos.x > objective.comfylatron_habitat.right_bottom.x then return false end
	if pos.y < objective.comfylatron_habitat.left_top.y then return false end
	if pos.y > objective.comfylatron_habitat.right_bottom.y then return false end
	return true
end

local function get_nearby_players()
	local objective = Chrono_table.get_table()
	local players = objective.comfylatron.surface.find_entities_filtered({
		name = "character",
		area = {{objective.comfylatron.position.x - 9, objective.comfylatron.position.y - 9}, {objective.comfylatron.position.x + 9, objective.comfylatron.position.y + 9}}
	})
	if not players[1] then return false end
	return players
end

local function visit_player()
	local objective = Chrono_table.get_table()
	if objective.comfylatron_last_player_visit > game.tick then return false end
	objective.comfylatron_last_player_visit = game.tick + math_random(7200, 10800)

	local players = {}
	for _, p in pairs(game.connected_players) do
		if is_target_inside_habitat(p.position, p.surface) and p.character  then
			if p.character.valid then players[#players + 1] = p end
		end
	end
	if #players == 0 then return false end
	local player = players[math_random(1, #players)]

	objective.comfylatron.set_command({
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
	local symbols = {"!","!!","..","..."," "}
	local arg1 = symbols[math_random(1, #symbols)]
	local randomphrase = texts["approach_player"][math_random(1, #texts["approach_player"])]
	local str = string.format(randomphrase, arg1)
	set_comfy_speech_bubble(str)

	objective.comfylatron_greet_player_index = player.index

	return true
end

local function greet_player(nearby_characters)
	local objective = Chrono_table.get_table()
	if not nearby_characters then return false end
	if not objective.comfylatron_greet_player_index then return false end
	for _, c in pairs(nearby_characters) do
		if c.player.index == objective.comfylatron_greet_player_index then

			local arg1 = c.player.name
			local symbols = {".", "!", ".", "!", "?", "..."," "}
			local arg2 = symbols[math_random(1, #symbols)]
			local randomphrase = texts["solo_greetings"][math_random(1, #texts["solo_greetings"])]
			local str = string.format(randomphrase, arg1, arg2)
			set_comfy_speech_bubble(str)

			objective.comfylatron_greet_player_index = false
			return true
		end
	end
	return false
end

local function talks(nearby_characters)
	local objective = Chrono_table.get_table()
	if not nearby_characters then return false end
	if math_random(1,3) == 1 then
		if objective.comfybubble then objective.comfybubble.destroy() return false end
	end
	local str = ""
	if #nearby_characters == 1 then
		local c = nearby_characters[math_random(1, #nearby_characters)]
		local arg1 = c.player.name
		local symbols = {".", "!"}
		local arg2 = symbols[math_random(1, #symbols)]
		local randomphrase = texts["convo_starters"][math_random(1, #texts["convo_starters"])]
		str = str .. string.format(randomphrase, arg1, arg2)
		if math_random(1,40) == 1 and objective.planet[1].type.id ~= 10 and global.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) then
			local time_until_overstay = (objective.chronochargesneeded * 0.75 / objective.passive_chronocharge_rate - objective.passivetimer)
			local time_until_evo = (objective.chronochargesneeded * 0.5 / objective.passive_chronocharge_rate - objective.passivetimer)
			if time_until_evo < 0 and time_until_overstay > 0 then
				str = str .. "It's important to charge so that you don't overstay!"
			end
		elseif objective.planet[1].type.id == 10 and math_random(1,30) == 1 then
			str = str .. "Sounds dangerous out there!"
		elseif objective.planet[1].type.id == 17 and math_random(1,6) == 1 then
			str = str .. "We made it!"
		elseif objective.planet[1].type.id == 18 and math_random(1,40) == 1 then
			str = str .. "Was that you?"
		elseif objective.planet[1].type.id == 19 and math_random(1,10) == 1 then
			str = str .. "Better get moving!"
		elseif objective.planet[1].type.id == 19 and math_random(1,10) == 1 then
			str = str .. "Nuke day today!"
		elseif objective.planet[1].type.id == 15 and math_random(1,20) == 1 then
			str = str .. "A new day, a new Chronotrain!"
		elseif objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) + 3 and objective.overstaycount > ((objective.chronojumps-Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value))/3) and math_random(1,30) == 1 then
			str = str .. "You're so relaxed!"
		elseif objective.planet.ore_richness == 1 and math_random(1,100) == 1 then
			str = str .. "You know what else is very rich?"
		elseif objective.poisontimeout >= 90 and math_random(1,4) == 1 then
			str = str .. "Tehe, I just let out some gas!"
		elseif math_random(1,15) == 1 then
			local randomphrase2 = texts["old_talks"][math_random(1, #texts["old_talks"])]
			str = str .. randomphrase2
		else
			local symbols2 = {".","!","?",".."," "}
			local arg3 = symbols2[math_random(1, #symbols2)]
			local randomphrase2 = texts["new_talks_solo"][math_random(1, #texts["new_talks_solo"])]
			str = str .. string.format(randomphrase2, arg3)
		end
	else
		local symbols = {".", "!"}
		local arg1 = symbols[math_random(1, #symbols)]
		local randomphrase = texts["multiple_characters_convo_starters"][math_random(1, #texts["multiple_characters_convo_starters"])]
		local str = str .. string.format(randomphrase, arg1)
		if math_random(1,15) == 1 then
			local randomphrase2 = texts["old_talks"][math_random(1, #texts["old_talks"])]
			str = str .. randomphrase2
		else
			local symbols2 = {".","!","?",".."," "}
			local arg3 = symbols2[math_random(1, #symbols2)]
			local randomphrase2 = texts["new_talks_group"][math_random(1, #texts["new_talks_group"])]
			str = str .. string.format(randomphrase2, arg3)
		end
	end
	set_comfy_speech_bubble(str)

	return true
end

local function desync(event)
	local objective = Chrono_table.get_table()
	if objective.comfybubble then objective.comfybubble.destroy() end
	local m = 12
	local m2 = m * 0.005
	for i = 1, 32, 1 do
		objective.comfylatron.surface.create_particle({
			name = "iron-ore-particle",
			position = objective.comfylatron.position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
		})
	end
	if not event or math_random(1,2) == 1 then -- 20/04/04: nerf comfylatron
		objective.comfylatron.surface.create_entity({name = "medium-explosion", position = objective.comfylatron.position})
		objective.comfylatron.surface.create_entity({name = "flying-text", position = objective.comfylatron.position, text = "desync", color = {r = 150, g = 0, b = 0}})
		objective.comfylatron.destroy()
		objective.comfylatron = nil
	else
		objective.comfylatron.surface.create_entity({name = "flying-text", position = objective.comfylatron.position, text = "desync evaded", color = {r = 0, g = 150, b = 0}})
		if event.cause then
			if event.cause.valid and event.cause.player then
				game.print("Comfylatron: I got you that time! Back to work, " .. event.cause.player.name .. "!", {r = 200, g = 0, b = 0})
				event.cause.die("player", objective.comfylatron)
			end
		end
	end
end

local function alone()
	local objective = Chrono_table.get_table()
	if math_random(1,3) == 1 then
		if objective.comfybubble then objective.comfybubble.destroy() return true end
	end
	if math_random(1,128) == 1 then
		desync(nil)
		return true
	end
	local randomphrase = texts["alone"][math_random(1, #texts["alone"])]
	set_comfy_speech_bubble(randomphrase)

	return true
end

local analyze_blacklist = {
	["compilatron"] = true,
	["car"] = true,
	["compi-speech-bubble"] = true,
	["entity-ghost"] = true,
	["character"] = true,
	["item-on-ground"] = true,
  	["stone-wall"] = true,
  	["market"] = true
}

local function analyze_random_nearby_entity()
	local objective = Chrono_table.get_table()
	if math_random(1,3) ~= 1 then return false end

	local entities = objective.comfylatron.surface.find_entities_filtered({
		area = {{objective.comfylatron.position.x - 4, objective.comfylatron.position.y - 4}, {objective.comfylatron.position.x + 4, objective.comfylatron.position.y + 4}}
	})
	if not entities[1] then return false end
	entities = Rand.shuffle(entities)
	local entity = false
	for _, e in pairs(entities) do
		if not analyze_blacklist[e.name] then
			entity = e
		end
	end
	if not entity then return false end

	local str = ""
	local arg1 = entity.name
	local arg2 = ""
	if entity.health and math_random(1,3) == 1 then
		arg1 = arg1 .. " health("
		arg1 = arg1 .. entity.health
		arg1 = arg1 .. "/"
		arg1 = arg1 .. entity.prototype.max_health
		arg1 = arg1 .. ")"
		local randomphrase = texts["neutral_findings"][math_random(1, #texts["neutral_findings"])]
		str = string.format(randomphrase, arg1, "")
	else
		local symbols = {".", "!", "?","?"}
		arg2 = symbols[math_random(1, 3)]
		local randomphrase = texts["neutral_findings"][math_random(1, #texts["neutral_findings"])]
		str = string.format(randomphrase, arg1, arg2)
	end
	set_comfy_speech_bubble(str)

	if not objective.comfylatron_greet_player_index then
		objective.comfylatron.set_command({
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
	local objective = Chrono_table.get_table()
	if math_random(1,4) ~= 1 then return false end

	if objective.comfylatron_greet_player_index then
		local player = game.players[objective.comfylatron_greet_player_index]
		if not player.character then
			objective.comfylatron_greet_player_index = nil
			return false
		end
		if not player.character.valid then
			objective.comfylatron_greet_player_index = nil
			return false
		end
		if not is_target_inside_habitat(player.position, player.surface) then
			objective.comfylatron_greet_player_index = nil
			return false
		end
		objective.comfylatron.set_command({
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
		local p = {x = objective.comfylatron.position.x + (-96 + math_random(0, 192)), y = objective.comfylatron.position.y + (-96 + math_random(0, 192))}
		local target = objective.comfylatron.surface.find_non_colliding_position("compilatron", p, 8, 1)
		if not target then return false end
		if not is_target_inside_habitat(target, objective.comfylatron.surface) then return false end
		objective.comfylatron.set_command({
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
	
	local symbols = {"!","!!","..","..."," "}
	local arg1 = symbols[math_random(1, #symbols)]
	local randomphrase = texts["random_travel"][math_random(1, #texts["random_travel"])]
	local str = string.format(randomphrase, arg1)
	set_comfy_speech_bubble(str)

	return true
end

local function spawn_comfylatron(surface_index, x, y)
	local objective = Chrono_table.get_table()
	local surface = game.surfaces[surface_index]
	if surface == nil then return end
	if objective.comfylatron_disabled then return false end
	if not objective.comfylatron_last_player_visit then objective.comfylatron_last_player_visit = 0 end
	if not objective.comfylatron_habitat then
		objective.comfylatron_habitat = {
			left_top = {x = -32, y = -192},
			right_bottom = {x = 32, y = -24} -- stops comfytron getting stuck in chests
		}
	end
	objective.comfylatron = surface.create_entity({
		name = "compilatron",
		position = {x,y + math_random(0,256)},
		force = "player",
		create_build_effect_smoke = false
	})
end

local function heartbeat()
	local objective = Chrono_table.get_table()
	if not game.surfaces["cargo_wagon"] then return end
	local surface = game.surfaces["cargo_wagon"].index
	if surface == nil then return end
	if not objective.comfylatron then if math_random(1,4) == 1 then spawn_comfylatron(game.surfaces["cargo_wagon"].index, 0, -128) end return end
	if not objective.comfylatron.valid then objective.comfylatron = nil return end
	if visit_player() then return end
	local nearby_players = get_nearby_players()
	if greet_player(nearby_players) then return end
	if talks(nearby_players) then return end
	if go_to_some_location() then return end
	if analyze_random_nearby_entity() then return end
	if alone() then return end
end

local function on_entity_damaged(event)
	local objective = Chrono_table.get_table()
	if not objective.comfylatron then return end
	if not event.entity.valid then return end
	if event.entity ~= objective.comfylatron then return end
	desync(event)
end

local function on_tick()
	if game.tick % 1300 == 600 then
		heartbeat()
	end
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_tick, on_tick)
