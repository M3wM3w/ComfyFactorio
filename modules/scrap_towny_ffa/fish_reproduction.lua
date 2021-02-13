local Public = {}
local math_random = math.random
local math_floor = math.floor

local Table = require 'modules.scrap_towny_ffa.table'

function Public.reproduce()
	local ffatable = Table.get_table()
	for _, town_center in pairs(ffatable.town_centers) do
		local surface = town_center.market.surface
		local position = town_center.market.position
		local fishes = surface.find_entities_filtered({ name = "fish", position = position, radius = 27 })
		if #fishes == 0 then return end
		if #fishes >= 100 then return end
		-- pick a random fish
		local t = math_random(1, #fishes)
		local fish = fishes[t]
		-- test against all other fishes
		local guppy = false
		for i, f in pairs(fishes) do
			if i ~= t then
				if math_floor(fish.position.x) == math_floor(f.position.x) and math_floor(fish.position.y) == math_floor(f.position.y) then
					guppy = true
				end
			end
		end
		if guppy == true then
			--log("fish spawn {" .. fish.position.x .. "," .. fish.position.y .. "}")
			surface.create_entity({ name = "water-splash", position = fish.position })
			surface.create_entity({ name = "fish", position = fish.position })
		end
	end
end

local function on_player_used_capsule(event)
	if event.item.name ~= "raw-fish" then return end
	local player = game.players[event.player_index]
	local surface = player.surface
	local position = event.position
	local tile = player.surface.get_tile(position.x, position.y)

	-- return back some of the health if not healthy
	if player.character.health < 250 then
		player.surface.play_sound({ path = "utility/armor_insert", position = player.position, volume_modifier = 1 })
		return
	end

	-- if using fish on water
	if tile.name == "water" and tile.name == "water-green" and tile.name == "deepwater" and tile.name == "deepwater-green" then
		-- get the count of fish in the water nearby and test if can be repopulated
		local fishes = surface.find_entities_filtered({ name = "fish", position = position, radius = 27 })
		if #fishes < 12 then
			surface.create_entity({ name = "water-splash", position = position })
			surface.create_entity({ name = "fish", position = position })
			surface.play_sound({ path = "utility/achievement_unlocked", position = player.position, volume_modifier = 1 })
			return
		end
	end
	-- otherwise return the fish and make no sound
	player.insert({ name = "raw-fish", count = 1 })

end

local Event = require 'utils.event'
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)

return Public
