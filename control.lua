require 'utils.data_stages'
_LIFECYCLE = _STAGE.control -- Control stage
_DEBUG = false
_DUMP_ENV = false

require 'utils.server'
require "utils.server_commands"
require "utils.utils"
require "utils.table"
require "utils.color_data"
require "utils.session_data"
require "chatbot"
require "commands"
require "antigrief"
require "modules.corpse_markers"
require "modules.floaty_chat"
require "modules.autohotbar"

require "comfy_panel.main"
require "comfy_panel.player_list"
require "comfy_panel.admin"
require "comfy_panel.group"
require "comfy_panel.poll"
require "comfy_panel.score"
require "comfy_panel.config"

require "modules.autostash"

---- enable modules here ----
--require "modules.admins_operate_biters"
--require "modules.the_floor_is_lava"
--require "modules.biters_landfill_on_death"
--require "modules.autodecon_when_depleted"
--require "modules.biter_noms_you"
--require "modules.biters_avoid_damage"
--require "modules.biters_double_damage"
--require "modules.burden"
--require "modules.comfylatron"
--require "modules.spaghett_challenge"
--require "modules.dangerous_goods"
--require "modules.dynamic_landfill"
--require "modules.explosive_biters"
--require "modules.explosive_player_respawn"
--require "modules.explosives_are_explosive"
--require "modules.fish_respawner"
--require "modules.fluids_are_explosive"
--require "modules.hunger"
--require "modules.hunger_games"
--require "modules.pistol_buffs"
--require "modules.players_trample_paths"
--require "modules.railgun_enhancer"
--require "modules.restrictive_fluid_mining"
--require "modules.satellite_score"
--require "modules.show_health"
--require "modules.splice_double"
--require "modules.ores_are_mixed"
--require "modules.team_teleport" --(REQUIRES "on_tick_schedule" !)
--require "modules.surrounded_by_worms"
--require "modules.more_attacks"
--require "modules.evolution_extended"
--require "modules.no_blueprint_library"
--require "modules.explosives"
--require "modules.biter_pets"
--require "modules.no_solar"
--require "modules.biter_reanimator"
--require "modules.wave_defense.main"
--require "modules.fjei.main"
-----------------------------

---- enable maps here ---- (maps higher up in the list may be more actually playable)
--require "maps.chronosphere.main"
--require "maps.fish_defender.main"
--require "maps.biter_battles_v2.main"
--require "maps.native_war.main"
--require "maps.mountain_fortress_v2.main"
--require "maps.dungeons.main"
--require "maps.island_troopers.main"
--require "maps.biter_hatchery.main"
--require "maps.junkyard_pvp.main"
--require "maps.scrapyard.main"
--require "maps.tank_conquest.tank_conquest"
--require "maps.territorial_control"
--require "maps.cave_choppy.cave_miner"
--require "maps.wave_of_death.WoD"
--require "maps.planet_prison"
--require "maps.stone_maze.main"
--require "maps.choppy"
--require "maps.overgrowth"
--require "maps.quarters"
--require "maps.railway_troopers.main"
--require "maps.tetris.main"
--require "maps.maze_challenge"
--require "maps.cave_miner"
--require "maps.labyrinth"
--require "maps.junkyard"
--require "maps.hedge_maze"
--require "maps.spooky_forest"
--require "maps.mixed_railworld"
--require "maps.biter_battles.biter_battles"
--require "maps.fish_defender_v1.fish_defender"
--require "maps.mountain_fortress"
--require "maps.rocky_waste"
--require "maps.nightfall"
--require "maps.lost"
--require "maps.rivers"
--require "maps.atoll"
--require "maps.cratewood_forest"
--require "maps.tank_battles"
--require "maps.spiral_troopers"
--require "maps.refactor-io"
--require "maps.desert_oasis"
--require "maps.lost_desert"
--require "maps.stoneblock"
--require "maps.wave_defense"
--require "maps.crossing"
--require "maps.anarchy"
--require "maps.spaghettorio"
--require "maps.blue_beach"
--require "maps.deep_jungle"
--require "maps.rainbow_road"
--require "maps.pitch_black.main"
--require "maps.cube"
--require "maps.forest_circle"
-----------------------------

---- more modules here ----
--require "modules.towny.main"
--require "modules.rpg"
--require "modules.trees_grow"
--require "modules.trees_randomly_die"

--require "terrain_layouts.caves"
--require "terrain_layouts.cone_to_east"
--require "terrain_layouts.biters_and_resources_east"
--require "terrain_layouts.scrap_01"
--require "terrain_layouts.watery_world"
--require "terrain_layouts.tree_01"
------

if _DUMP_ENV then
    require 'utils.dump_env'
end
if _DEBUG then
    require 'utils.debug.command'
end

local function on_player_created(event)
	local player = game.players[event.player_index]
	player.gui.top.style = 'slot_table_spacing_horizontal_flow'
	player.gui.left.style = 'slot_table_spacing_vertical_flow'
end

local function on_init()
	game.forces.player.research_queue_enabled = true
end

local loaded = _G.package.loaded
function require(path)
    return loaded[path] or error('Can only require files at runtime that have been required in the control stage.', 2)
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_created, on_player_created)
