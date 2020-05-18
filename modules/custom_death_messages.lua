-- prints death messages to all forces with custom texts -- by mewmew

local event = require 'utils.event'
local math_random = math.random
local message_color = {r=0.9, g=0.9, b=0.9}

local messages = {
	["small-biter"] = {" was nibbled to death.", " should not have played with the biters.", " is biter food."},
	["medium-biter"] = {" lost their leg to a hungry biter.", " is biter food.", " was a tasty biter treat."},
	["big-biter"] = {" had their head chomped off.", " is biter food.", " was a tasty biter treat."},
	["behemoth-biter"] = {" was devoured by a behemoth biter.", " was crushed by a behemoth biter.", " is biter food."},
	["small-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time."},
	["medium-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time."},
	["big-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a spitter."},
	["behemoth-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a spitter."},
	["small-worm-turret"] = {" melted away by acid spit!", " couldn't dodge the spit in time."},
	["medium-worm-turret"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a medium worm turret."},
	["big-worm-turret"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a big worm turret."},
	["gun-turret"] = {" was mowed down by a barrage from a gun turret."},
	["laser-turret"] = {" was fatally enlightened by a laser beam."},
	["cargo-wagon"] = {" was flattened.", " was crushed."},
	["locomotive"] = {" was flattened.", " was crushed."}	
}

local function on_player_died(event)
	local player = game.players[event.player_index]
	
	local tag = ""
	if player.tag then
		if player.tag ~= "" then tag = " " .. player.tag end
	end
	
	if event.cause then
		local cause = event.cause	
		if not cause.name then
			game.print(player.name .. tag .. " was killed.", message_color)
			return
		end
		if messages[cause.name] then
			game.print(player.name .. messages[cause.name][math.random(1, #messages[cause.name])], message_color)
			return
		end
					
		if cause.name == "character" then
			if not player.name then return end
			if not cause.player.name then return end
			if cause.player.tag ~= "" then
				game.print(player.name .. tag .. " was killed by " .. cause.player.name .. " " .. cause.player.tag .. ".", message_color)
			else
				game.print(player.name .. tag .. " was killed by " .. cause.player.name .. ".", message_color)
			end								
			return
		end
		
		if cause.type == "car" then
			local driver = cause.get_driver()
			if driver.player then				
				game.print(player.name .. tag .. " was killed by " .. driver.player.name .. " " .. player.tag .. ".", message_color)
				return								
			end
		end
				
		game.print(player.name .. tag .. " was killed by " .. cause.name .. ".", message_color)				
		return
	end
	for _, p in pairs(game.connected_players) do
		if player.force.name ~= p.force.name then			
			p.print(player.name .. tag .. " was killed.", message_color)						
		end
	end
end

event.add(defines.events.on_player_died, on_player_died)