require 'utils.data_stages'
_LIFECYCLE = _STAGE.control -- Control stage
_DEBUG = false
_DUMP_ENV = false

require 'utils.server'
require 'utils.server_commands'
require 'utils.utils'
require 'utils.table'
require 'utils.freeplay'
require 'utils.datastore.server_ups'
require 'utils.datastore.color_data'
require 'utils.datastore.session_data'
require 'utils.datastore.jail_data'
require 'utils.datastore.quickbar_data'
require 'utils.datastore.message_on_join_data'
require 'utils.datastore.player_tag_data'
require 'chatbot'
require 'commands'
require 'antigrief'
require 'modules.floaty_chat'
require 'modules.show_inventory'
require 'utils.debug.command'

require 'comfy_panel.main'
require 'comfy_panel.player_list'
require 'comfy_panel.admin'
require 'comfy_panel.group'
require 'comfy_panel.poll'
require 'comfy_panel.score'
require 'comfy_panel.config'

require 'modules.autostash'

---------------- !ENABLE MODULES HERE ----------------
--require 'modules.admins_operate_biters'
--require 'modules.the_floor_is_lava'
--require 'modules.biters_landfill_on_death'
--require 'modules.autodecon_when_depleted'
--require 'modules.biter_noms_you'
--require 'modules.biters_avoid_damage'
--require 'modules.biters_double_damage'
--require 'modules.burden'
--require 'modules.comfylatron'
--require 'modules.dangerous_goods'
--require 'modules.explosive_biters'
--require 'modules.explosive_player_respawn'
--require 'modules.explosives_are_explosive'
--require 'modules.fish_respawner'
--require 'modules.fluids_are_explosive'
--require 'modules.hunger'
--require 'modules.hunger_games'
--require 'modules.pistol_buffs'
--require 'modules.players_trample_paths'
--require 'modules.railgun_enhancer'
--require 'modules.restrictive_fluid_mining'
--require 'modules.satellite_score'
--require 'modules.show_health'
--require 'modules.splice_double'
--require 'modules.ores_are_mixed'
--require 'modules.team_teleport'
--require 'modules.surrounded_by_worms'
--require 'modules.no_blueprint_library'
--require 'modules.explosives'
--require 'modules.biter_pets'
--require 'modules.no_solar'
--require 'modules.biter_reanimator'
--require 'modules.force_health_booster'
--require 'modules.immersive_cargo_wagons.main'
--require 'modules.wave_defense.main'
--require 'modules.fjei.main'
--require 'modules.charging_station'
--require 'modules.nuclear_landmines'
--require 'modules.crawl_into_pipes'
--require 'modules.no_acid_puddles'
--require 'modules.simple_tags'
---------------------------------------------------------------

---------------- ENABLE MAPS HERE ----------------
--!Make sure only one map is enabled at a time.
--!Remove the "--" in front of the line to enable.
--!All lines with the "require" keyword are different maps.

--![[North VS South Survival PVP, feed the opposing team's biters with science flasks. Disable Autostash, Group and Poll modules.]]--
--require 'maps.biter_battles_v2.main'
--require 'maps.biter_battles.biter_battles'

--![[A map that imitating MF, defending rocket silos instead of trains]]--
--require 'maps.amap.main'

--![[Guide a Train through rough terrain, while defending it from the biters]]--
--require 'maps.mountain_fortress_v3.main'
--require 'maps.mountain_fortress_v2.main'
--require 'maps.mountain_fortress'

--![[Defend the market against waves of biters]]--
--require 'maps.fish_defender_v2.main'
--require 'maps.crab_defender.main'
--require 'maps.fish_defender_v1.fish_defender'
--require 'maps.fish_defender.main'

--![[Comfylatron has seized the Fish Train and turned it into a time machine]]--
--require 'maps.chronosphere.main'

--![[East VS West Survival PVP, where you breed biters with science flasks]]--
--require 'maps.biter_hatchery.main'

--![[Fight in a world where everyone are prisoners]]
--require 'maps.planet_prison'

--![[Chop trees to gain resources]]--
--require 'maps.choppy'
--require 'maps.choppy_dx'

--![[Launch rockets in increasingly harder getting worlds.]]--
require 'maps.journey.main'

--![[Minesweeper?]]--
--require 'maps.minesweeper.main'

--![[Infinite random dungeon with RPG]]--
--require 'maps.dungeons.main'
--require 'maps.dungeons.tiered_dungeon'

--![[Randomly generating Islands that have to be beaten in levels to gain credits]]--
--require 'maps.island_troopers.main'

--![[Infinitely expanding mazes]]--
--require 'maps.stone_maze.main'
--require 'maps.labyrinth'

--![[Extreme survival mode with thirst and limited building room]]--
--require 'maps.desert_oasis'

--![[The trees are your enemy here]]--
--require 'maps.overgrowth'

--![[Wave Defense Map split in 4 Quarters]]--
--require 'maps.quarters'

--![[Flee from the collapsing map with portable base inside train]]--
--require 'maps.railway_troopers_v2.main'

--![[Another simliar version without collapsing terrain]]--
--require 'maps.railway_troopers.main'

--![[You fell in a dark cave, will you survive?]]--
--require 'maps.cave_miner'
--require 'maps.cave_choppy.cave_miner'
--require 'maps.cave_miner_v2.main'

--![[Hungry boxes eat your items, but reward you with new territory to build.]]--
--require 'maps.expanse.main'

--![[Crashlanding on Junk Planet]]--
--require 'maps.junkyard'
--require 'maps.territorial_control'
--require 'maps.junkyard_pvp.main'

--![[A green maze]]--
--require 'maps.hedge_maze'

--![[Dangerous forest with unique map revealing]]--
--require 'maps.spooky_forest'

--![[Defeat the biters and unlock new areas]]--
--require 'maps.spiral_troopers'

--![[Railworld style terrains]]--
--require 'maps.mixed_railworld'
--require 'maps.scrap_railworld'

--![[It's tetris!]]--
--require 'maps.tetris.main'

--![[4 Team Lane Surival]]--
--require 'maps.wave_of_death.WoD'

--![[PVP Battles with Tanks]]--
--require 'maps.tank_conquest.tank_conquest'
--require 'maps.tank_battles'

--![[Terrain with lots of Rocks]]--
--require 'maps.rocky_waste'

--![[Landfill is reveals the map, set resources to high when rolling the map]]--
--require 'maps.lost'

--![[A terrain layout with many rivers]]--
--require 'maps.rivers'

--![[Islands Theme]]--
--require 'maps.atoll'

--![[Placed buildings can hardly be removed]]--
--require 'maps.refactor-io'

--![[Prebuilt buildings on the map that can not be removed, you will hate this map]]--
--require 'maps.spaghettorio'

--![[Misc / WIP]]--
--require 'maps.rainbow_road'
--require 'maps.deep_jungle'
--require 'maps.cratewood_forest'
--require 'maps.maze_challenge'
--require 'maps.lost_desert'
--require 'maps.stoneblock'
--require 'maps.wave_defense'
--require 'maps.crossing'
--require 'maps.anarchy'
--require 'maps.blue_beach'
--require 'maps.nightfall'
--require 'maps.pitch_black.main'
--require 'maps.cube'
--require 'maps.mountain_race.main'
--require 'maps.native_war.main'
--require 'maps.scrap_towny_ffa.main'
---------------------------------------------------------------

---------------- MORE MODULES HERE ----------------
--require 'modules.hidden_dimension.main'
--require 'modules.towny.main'
--require 'modules.rpg.main'
--require 'modules.rpg'
--require 'modules.trees_grow'
--require 'modules.trees_randomly_die'
---------------------------------------------------------------

---------------- MOSTLY TERRAIN LAYOUTS HERE ----------------
--require 'terrain_layouts.winter'
--require 'terrain_layouts.caves'
--require 'terrain_layouts.cone_to_east'
--require 'terrain_layouts.biters_and_resources_east'
--require 'terrain_layouts.scrap_01'
--require 'terrain_layouts.scrap_02'
--require 'terrain_layouts.watery_world'
--require 'terrain_layouts.tree_01'
--require 'terrain_layouts.scrap_towny_ffa'
---------------------------------------------------------------

if _DUMP_ENV then
    require 'utils.dump_env'
    require 'utils.profiler'
end

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.gui.top.style = 'slot_table_spacing_horizontal_flow'
    player.gui.left.style = 'slot_table_spacing_vertical_flow'
end

local loaded = _G.package.loaded
function require(path)
    return loaded[path] or error('Can only require files at runtime that have been required in the control stage.', 2)
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_created, on_player_created)
