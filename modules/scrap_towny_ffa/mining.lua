local Table = require 'modules.scrap_towny_ffa.table'

local crash_site = {
	-- simple entity with owner
	"crash-site-spaceship-wreck-small-1",
	"crash-site-spaceship-wreck-small-2",
	"crash-site-spaceship-wreck-small-3",
	"crash-site-spaceship-wreck-small-4",
	"crash-site-spaceship-wreck-small-5",
	"crash-site-spaceship-wreck-small-6",
	-- containers
	"big-ship-wreck-1",
	"big-ship-wreck-2",
	"big-ship-wreck-3",
	"crash-site-chest-1",
	"crash-site-chest-2",
	"crash-site-spaceship-wreck-medium-1",
	"crash-site-spaceship-wreck-medium-2",
	"crash-site-spaceship-wreck-medium-3",
	"crash-site-spaceship-wreck-big-1",
	"crash-site-spaceship-wreck-big-2",
	"crash-site-spaceship"
}

local function is_crash_site(entity)
	if not entity.valid then return false end
	local f = false
	for i = 1, #crash_site, 1 do
		if entity.name == crash_site[i] then f = true end
	end
	return f
end

local function mining_sound(player)
	if game.tick % 15 ~= 0 then return end
	local target = player.selected
	if target == nil or not target.valid then return end
	local surface = target.surface
	local position = target.position
	local path = "entity-mining/" .. target.name
	surface.play_sound({path = path, position = position, volume_modifier = 1, override_sound_type = "game-effect" })
end

local function on_tick()
	local ffatable = Table.get_table()
	for index, player in pairs(game.players) do
		if player.character ~= nil then
			local mining = player.mining_state.mining
			if ffatable.mining[index] ~= mining then
				ffatable.mining[index] = mining
				-- state change
				if mining == true then
					--log(player.name .. " started mining")
					local target = player.selected
					if target ~= nil and target.valid then
						--log("target name = " .. target.prototype.name)
						--log("position = " .. serpent.block(target.position))
						--log("mineable_properties = " .. serpent.block(target.prototype.mineable_properties))
						if is_crash_site(target) then
							-- mining crash site
							mining_sound(player)
							ffatable.mining_target[index] = target
						end
					end
				else
				  --log(player.name .. " stopped mining")
				  local target = ffatable.mining_target[index]
					if target ~= nil then
						ffatable.mining_target[index] = nil
					end
				end
			else
				if mining == true then
					local target = player.selected
					if target ~= nil and target.valid then
						--local progress = player.character_mining_progress
						--log("progress = " .. progress)
						if is_crash_site(target) then
							-- mining crash site
							mining_sound(player)
						end
					end
				end
			end
		end
	end
end

local on_init = function ()
	local ffatable = Table.get_table()
	ffatable.mining = {}
	ffatable.mining_entity = {}
	ffatable.mining_target = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)