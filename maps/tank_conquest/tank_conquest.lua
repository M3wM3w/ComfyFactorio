
    -- factorio scenario -- tank conquest -- xalpha made this --

    local blueprint_poi_base_json = require 'maps.tank_conquest.blueprint_poi_base_json'

    local blueprint_poi_spot_one_json = require 'maps.tank_conquest.blueprint_poi_spot_one_json'

    local blueprint_poi_spot_two_json = require 'maps.tank_conquest.blueprint_poi_spot_two_json'

    local blueprint_poi_spot_three_json = require 'maps.tank_conquest.blueprint_poi_spot_three_json'

    local blueprint_poi_fire_json = require 'maps.tank_conquest.blueprint_poi_fire_json'

    local blueprint_poi_laser_json = require 'maps.tank_conquest.blueprint_poi_laser_json'

    global.table_of_properties = {}

    global.table_of_properties.required_number_of_players = 2

    global.table_of_properties.countdown_in_seconds = 28800

    global.table_of_properties.wait_in_seconds = 2

    global.table_of_properties.size_of_the_battlefield = 2000

    global.table_of_properties.amount_of_tickets = 800

    global.table_of_properties.conquest_speed = 5

    global.table_of_properties.acceleration_value = 0.05

    global.table_of_properties.game_stage = 'lobby'

    global.table_of_tanks = {}

    global.table_of_scores = {}

    global.table_of_spots = {}

    global.table_of_spawns = {}

    global.table_of_squads = {}

    global.table_of_drawings = {}

    global.table_of_delays = {}

    local table_of_colors = { squad = { r = 75, g = 155, b = 45 }, team = { r = 65, g = 120, b = 200 }, enemy = { r = 190, g = 55, b = 50 }, neutral = { r = 77, g = 77, b = 77 }, damage = { r = 255, g = 0, b = 255 }, white = { r = 255, g = 255, b = 255 } }

    local table_of_loots = { { name = 'iron-ore', count = 50 }, { name = 'copper-ore', count = 50 }, { name = 'stone', count = 50 }, { name = 'coal', count = 50 }, { name = 'defender-capsule', count = 10 }, { name = 'land-mine', count = 20 }, { name = 'gun-turret', count = 5 }, { name = 'piercing-rounds-magazine', count = 50 }, { name = 'uranium-rounds-magazine', count = 10 }, { name = 'combat-shotgun', count = 1 }, { name = 'shotgun-shell', count = 20 }, { name = 'piercing-shotgun-shell', count = 20 }, { name = 'flamethrower', count = 1 }, { name = 'flamethrower-ammo', count = 20 }, { name = 'rocket-launcher', count = 1 }, { name = 'rocket', count = 20 }, { name = 'explosive-rocket', count = 10 }, { name = 'atomic-bomb', count = 1 }, { name = 'grenade', count = 20 }, { name = 'cluster-grenade', count = 10 }, { name = 'cannon-shell', count = 20 }, { name = 'explosive-cannon-shell', count = 10 }, { name = 'uranium-cannon-shell', count = 5 }, { name = 'explosive-uranium-cannon-shell', count = 5 }, { name = 'modular-armor', count = 1 }, { name = 'power-armor', count = 1 }, { name = 'power-armor-mk2', count = 1 }, { name = 'exoskeleton-equipment', count = 1 }, { name = 'battery-mk2-equipment', count = 1 }, { name = 'energy-shield-equipment', count = 1 }, { name = 'fusion-reactor-equipment', count = 1 }, { name = 'solid-fuel', count = 20 }, { name = 'rocket-fuel', count = 10 }, { name = 'nuclear-fuel', count = 1 }, { name = 'gate', count = 10 }, { name = 'stone-wall', count = 20 } }

    local table_of_slots = { 'stone-wall', 'gun-turret', 'wood', 'repair-pack', 'raw-fish', 'defender-capsule', 'rocket', 'explosive-rocket', 'atomic-bomb', 'flamethrower-ammo', 'land-mine', 'firearm-magazine', 'piercing-rounds-magazine', 'uranium-rounds-magazine', 'grenade', 'cluster-grenade', 'cannon-shell', 'explosive-cannon-shell', 'uranium-cannon-shell', 'explosive-uranium-cannon-shell' }

    local table_of_ores = { 'iron-ore', 'copper-ore', 'stone', 'coal' }

    local map_functions = require 'tools.map_functions'

    local event = require 'utils.event'

    local map_intro = [[                                                            - - - T A N K    C O N Q U E S T - - -

    When the round is running, the ticket overview is shown in the header. Your objective
    is to defend your team's tickets and withdraw the tickets from the opposing team as
    quickly as possible.

    There are two ways to withdraw the tickets from the opposing team. First, by killing
    the player and second, by taking the spots. A spot withdraw 0.05 tickets per second
    from the opposing team.

    The battlefield has two special features: First, there is a point of interest in the
    north and south. And second, there are loot boxes scattered throughout the battlefield.

    PvP battles and the conquest of the spots are the deciding factor to win the round.

    The battlefield is created when at least two players are online.

    There is no biter evolution from pollution, time or destruction.]]

    local function draw_gui_intro_button( player )

        if player.gui.top[ 'draw_gui_intro_button' ] then return end

        local element_button = player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_intro_button', caption = '?', tooltip = 'Map Intro' } )

        element_button.style.width = 38

        element_button.style.height = 38

        element_button.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }

        element_button.style.font = 'heading-1'

    end

    local function draw_gui_intro_frame( player )

        if player.gui.center[ 'draw_gui_intro_frame' ] then player.gui.center[ 'draw_gui_intro_frame' ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = 'draw_gui_intro_frame', direction = 'vertical' } )

        element_frame = element_frame.add( { type = 'frame' } )

        local element_label = element_frame.add( { type = 'label', name = 'draw_gui_intro_content', caption = map_intro } )

        element_label.style.top_padding = 15

        element_label.style.single_line = false

        element_label.style.font = 'heading-2'

        element_label.style.font_color = { r = 0.7, g = 0.6, b = 0.99 }

    end

    local function initialize_forces()

        game.create_force( 'force_player_one' )

        game.create_force( 'force_player_two' )

        game.create_force( 'force_biter_one' )

        game.create_force( 'force_biter_two' )

        game.create_force( 'force_spectator' )

        local force = game.forces.force_player_one

        if global.table_of_properties[ force.name ] == nil then global.table_of_properties[ force.name ] = { name = force.name, enemy = 'force_player_two', icon = '☠', available_tickets = global.table_of_properties.amount_of_tickets } end

        force.set_friend( 'force_biter_two', true )

        force.set_friend( 'force_spectator', true )

        force.set_cease_fire( 'player', true )

        local force = game.forces.force_player_two

        if global.table_of_properties[ force.name ] == nil then global.table_of_properties[ force.name ] = { name = force.name, enemy = 'force_player_one', icon = '☢', available_tickets = global.table_of_properties.amount_of_tickets } end

        force.set_friend( 'force_biter_one', true )

        force.set_friend( 'force_spectator', true )

        force.set_cease_fire( 'player', true )

        local force = game.forces[ 'force_biter_one' ]

        force.set_friend( 'force_player_two', true )

        force.set_friend( 'force_biter_two', true )

        force.set_friend( 'force_spectator', true )

        force.set_friend( 'player', true )

        local force = game.forces[ 'force_biter_two' ]

        force.set_friend( 'force_player_one', true )

        force.set_friend( 'force_biter_one', true )

        force.set_friend( 'force_spectator', true )

        force.set_friend( 'player', true )

        local force = game.forces.force_spectator

        force.set_spawn_position( { x = 0, y = 0 }, game.surfaces.nauvis )

        force.technologies[ 'toolbelt' ].researched = true

        force.set_friend( 'force_player_one', true )

        force.set_friend( 'force_player_two', true )

        force.set_cease_fire( 'force_biter_one', true )

        force.set_cease_fire( 'force_biter_two', true )

        force.set_cease_fire( 'player', true )

        force.set_cease_fire( 'enemy', true )

        local force = game.forces[ 'player' ]

        force.set_cease_fire( 'force_player_one', true )

        force.set_cease_fire( 'force_player_two', true )

        force.set_cease_fire( 'force_biter_one', true )

        force.set_cease_fire( 'force_biter_two', true )

        force.set_cease_fire( 'force_spectator', true )

        local spectator = game.permissions.create_group( 'permission_spectator' )

        for action_name, _ in pairs( defines.input_action ) do spectator.set_allows_action( defines.input_action[ action_name ], false ) end

        local table_of_definitions = { defines.input_action.write_to_console, defines.input_action.gui_click, defines.input_action.gui_selection_state_changed, defines.input_action.gui_checked_state_changed, defines.input_action.gui_elem_changed, defines.input_action.gui_text_changed, defines.input_action.gui_value_changed, defines.input_action.start_walking, defines.input_action.open_kills_gui, defines.input_action.toggle_show_entity_info }

        for _, define in pairs( table_of_definitions ) do spectator.set_allows_action( define, true ) end

        for _, force in pairs( game.forces ) do

            game.forces[ force.name ].technologies[ 'artillery' ].enabled = false

            game.forces[ force.name ].technologies[ 'artillery-shell-range-1' ].enabled = false

            game.forces[ force.name ].technologies[ 'artillery-shell-speed-1' ].enabled = false

            game.forces[ force.name ].technologies[ 'follower-robot-count-1' ].researched = true

            game.forces[ force.name ].technologies[ 'atomic-bomb' ].enabled = false

            game.forces[ force.name ].set_turret_attack_modifier( 'flamethrower-turret', 4 )

            game.forces[ force.name ].set_turret_attack_modifier( 'laser-turret', 2 )

            game.forces[ force.name ].set_turret_attack_modifier( 'gun-turret', 4 )

            game.forces[ force.name ].set_ammo_damage_modifier( 'cannon-shell', 1 )

            game.forces[ force.name ].set_ammo_damage_modifier( 'grenade', 1 )

            game.forces[ force.name ].research_queue_enabled = true

            game.forces[ force.name ].friendly_fire = false

            game.forces[ force.name ].share_chart = true

        end

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.grab_blueprint_record, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint_string, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint, false )

        game.forces[ 'enemy' ].evolution_factor = 0.4

    end

    function initialize_surface()

        game.map_settings.enemy_evolution.time_factor = 0

        game.map_settings.enemy_evolution.destroy_factor = 0

        game.map_settings.enemy_evolution.pollution_factor = 0

        game.map_settings.pollution.enabled = false

        game.map_settings.enemy_expansion.enabled = true

        game.map_settings.enemy_expansion.settler_group_min_size = 8

        game.map_settings.enemy_expansion.settler_group_max_size = 16

        game.map_settings.enemy_expansion.min_expansion_cooldown = 54000

        game.map_settings.enemy_expansion.max_expansion_cooldown = 108000

        local map_gen_settings = {}

        map_gen_settings.width = global.table_of_properties.size_of_the_battlefield

        map_gen_settings.height = global.table_of_properties.size_of_the_battlefield

        map_gen_settings.seed = math.random( 1, 2097152 )

        map_gen_settings.water = 'none'

        map_gen_settings.starting_area = 'none'

        map_gen_settings.cliff_settings = { name = 'cliff', cliff_elevation_0 = 0, cliff_elevation_interval = 0 }

        map_gen_settings.autoplace_controls = { [ 'trees' ] = { frequency = 'normal', size = 'normal', richness = 'normal' }, [ 'coal' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'stone' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'copper-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'uranium-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'iron-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'crude-oil' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'enemy-base' ] = { frequency = 'normal', size = 'normal', richness = 'normal' } }

        -- map_gen_settings.autoplace_settings = { entity = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } }, decorative = { treat_missing_as_default = true, settings = { frequency = 'none', size = 'none', richness = 'none' } } }

        -- map_gen_settings.default_enable_all_autoplace_controls = false

        if game.surfaces.tank_conquest == nil then

            game.create_surface( 'tank_conquest', map_gen_settings )

        else

            rendering.clear()

            game.surfaces.tank_conquest.clear()

            game.surfaces.tank_conquest.map_gen_settings = map_gen_settings

         end

    end

    function draw_gui_button( player )

        if player.gui.top[ 'draw_gui_button' ] then player.gui.top[ 'draw_gui_button' ].destroy() end

        player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_button', sprite = 'item/tank', tooltip = 'MENU' } )

        -- player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_button_score', sprite = 'item/heavy-armor', tooltip = 'SCORE' } )

        -- player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_button_squad', sprite = 'item/personal-roboport-equipment', tooltip = 'SQUAD' } )

      end

    function draw_gui_status( player )

        if player.gui.top[ 'draw_gui_status' ] then player.gui.top[ 'draw_gui_status' ].destroy() end

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        if player.force.name == 'force_spectator' then return end

        if #global.table_of_spots == 0 then return end

        local element_frame = player.gui.top.add( { type = 'frame', name = 'draw_gui_status', direction = 'horizontal' } )

        element_frame.style.height = 38

        element_frame.style.margin = 0

        element_frame.style.padding = 0

        element_frame.style.left_padding = 20

        element_frame.style.right_padding = 20

        element_frame.style.vertical_align = 'center'

        local element_progressbar = element_frame.add( { type = 'progressbar', value = 100 } )

        element_progressbar.style.width = 125

        element_progressbar.style.right_padding = 20

        element_progressbar.style.top_padding = 10

        element_progressbar.style.color = table_of_colors.team

        local element_label = element_frame.add( { type = 'label', caption = math.floor( global.table_of_properties[ player.force.name ].available_tickets ) } )

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add( { type = 'label', caption = global.table_of_properties[ player.force.name ].icon } )

        element_label.style.left_padding = 20

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add( { type = 'label', caption = seconds_to_clock( global.table_of_properties.countdown_in_seconds ) } )

        element_label.style.left_padding = 20

        element_label.style.right_padding = 20

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add( { type = 'label', caption = global.table_of_properties[ global.table_of_properties[ player.force.name ].enemy ].icon } )

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add( { type = 'label', caption = math.floor( global.table_of_properties[ global.table_of_properties[ player.force.name ].enemy ].available_tickets ) } )

        element_label.style.left_padding = 20

        element_label.style.font_color = table_of_colors.white

        local element_progressbar = element_frame.add( { type = 'progressbar', value = 100 } )

        element_progressbar.style.width = 125

        element_progressbar.style.left_padding = 20

        element_progressbar.style.top_padding = 10

        element_progressbar.style.color = table_of_colors.enemy

        for _, element_item in pairs( element_frame.children ) do element_item.style.font = 'heading-1' end

    end

    function draw_gui_spots( player )

        if player.gui.top[ 'draw_gui_spots' ] then player.gui.top[ 'draw_gui_spots' ].destroy() end

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        if player.force.name == 'force_spectator' then return end

        if #global.table_of_spots == 0 then return end

        local element_frame = player.gui.top.add( { type = 'frame', name = 'draw_gui_spots', direction = 'horizontal' } )

        element_frame.style.height = 38

        element_frame.style.margin = 0

        element_frame.style.padding = 0

        element_frame.style.vertical_align = 'center'

        element_frame.style.horizontal_align = 'center'

        for _, spot in pairs( global.table_of_spots ) do

            local element_label = element_frame.add( { type = 'label', caption = spot.properties.name } )

            element_label.style.width = 38

            element_label.style.height = 38

            element_label.style.margin = 0

            element_label.style.padding = 0

            element_label.style.vertical_align = 'top'

            element_label.style.horizontal_align = 'center'

            element_label.style.font = 'heading-1'

            local color = table_of_colors.white

            if player.force.name ~= 'force_spectator' then

                color = table_of_colors.neutral

                if spot.properties.force.name == global.table_of_properties[ player.force.name ].name and spot.properties.value == 100 then color = table_of_colors.team end

                if spot.properties.force.name == global.table_of_properties[ player.force.name ].enemy and spot.properties.value == 100 then color = table_of_colors.enemy end

            end

            element_label.style.font_color = color

        end

    end

    function draw_gui_menu( player )

        if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = 'draw_gui_menu', direction = 'vertical' } )

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        if game.permissions.get_group( 'Default' ).players[ player.index ] == nil then

            element_frame.add( { type = 'sprite-button', name = 'event_on_click_join', caption = 'JOIN' } )

        else

            element_frame.add( { type = 'sprite-button', name = 'event_on_click_lobby', caption = 'LOBBY' } )

        end

        for _, element_item in pairs( element_frame.children ) do

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.minimal_width = 170

            element_item.style.minimal_height = 170

            element_item.style.font = 'heading-1'

            element_item.style.font_color = table_of_colors.white

        end

    end

    function draw_gui_score( player )

        if player.gui.center[ 'draw_gui_score' ] then player.gui.center[ 'draw_gui_score' ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = 'draw_gui_score', direction = 'vertical' } )

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.vertical_align = 'center'

        element_frame.style.horizontal_align = 'center'

        local element_table = element_frame.add( { type = 'table', column_count = 14, draw_horizontal_lines = true } )

        element_table.style.padding = 0

        element_table.style.top_padding = 5

        element_table.style.left_padding = 10

        element_table.style.bottom_padding = 5

        element_table.style.margin = 0

        element_table.style.vertical_align = 'center'

        element_table.style.horizontal_align = 'center'

        local element_label = element_table.add( { type = 'label', caption = global.table_of_properties[ player.force.name ].icon } )

        local element_label = element_table.add( { type = 'label', caption = '#' } )

        local element_label = element_table.add( { type = 'label', caption = 'NAME' } )

        local element_label = element_table.add( { type = 'label', caption = 'CLASS' } )

        local element_label = element_table.add( { type = 'label', caption = 'K' } )

        local element_label = element_table.add( { type = 'label', caption = 'D' } )

        local element_label = element_table.add( { type = 'label', caption = 'POINTS' } )

        local element_label = element_table.add( { type = 'label', caption = global.table_of_properties[ global.table_of_properties[ player.force.name ].enemy ].icon } )

        local element_label = element_table.add( { type = 'label', caption = '#' } )

        local element_label = element_table.add( { type = 'label', caption = 'NAME' } )

        local element_label = element_table.add( { type = 'label', caption = 'CLASS' } )

        local element_label = element_table.add( { type = 'label', caption = 'K' } )

        local element_label = element_table.add( { type = 'label', caption = 'D' } )

        local element_label = element_table.add( { type = 'label', caption = 'POINTS' } )

        for index = 1, 28 do local element_label = element_table.add( { type = 'label', caption = '•' } ) end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.padding = 0

            element_item.style.right_padding = 10

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.font = 'heading-2'

            element_item.style.font_color = table_of_colors.white

        end

    end

    function draw_gui_squad( player )

        if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() end

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local element_frame = player.gui.left.add( { type = 'frame', name = 'draw_gui_squad', direction = 'vertical' } )

        element_frame.style.minimal_width = 50

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.top_margin = 5

        element_frame.style.left_margin = 5

        local element_table = element_frame.add( { type = 'table', column_count = 4 } )

        element_table.style.padding = 0

        element_table.style.margin = 0

        for index = 1, 8 do

            local element_label = element_table.add( { type = 'label', caption = 'SQUAD ' .. index } )

            local element_label = element_table.add( { type = 'label' } )

            local element_label = element_table.add( { type = 'label' } )

            local element_button = element_table.add( { type = 'sprite-button', name = 'aaa_' .. index, caption = 'JOIN' } )

            element_button.style.width = 50

            element_button.style.height = 25

            local element_label = element_table.add( { type = 'label', caption = '•' } )

            local element_label = element_table.add( { type = 'label', caption = '•' } )

            local element_label = element_table.add( { type = 'label', caption = '•' } )

            local element_label = element_table.add( { type = 'label', caption = '•' } )

        end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.minimal_width = 50

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.horizontal_align  = 'center'

            element_item.style.font  = 'heading-2'

            element_item.style.font_color = table_of_colors.white

        end

    end

    function draw_gui_spawn( player )

        if player.gui.center[ 'draw_gui_spawn' ] then player.gui.center[ 'draw_gui_spawn' ].destroy() end

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local element_frame = player.gui.center.add( { type = 'frame', name = 'draw_gui_spawn', direction = 'horizontal' } )

        local element_button = element_frame.add( { type = 'button', name = 'event_on_click_spawn_base', caption = 'BASE' } )

        -- element_button.style.color = table_of_colors.damage

        element_button.style.font_color = table_of_colors.white

        for index, spot in pairs( global.table_of_spots ) do

            local element_button = element_frame.add( { type = 'button', name = 'event_on_click_spawn_' .. index, caption = spot.properties.name } )

            -- element_button.enabled = false

            local color = table_of_colors.neutral

            -- if spot.properties.force.name == global.table_of_properties[ player.force.name ].name and spot.properties.value >= 50 then element_button.enabled = true end

            if spot.properties.force.name == global.table_of_properties[ player.force.name ].name and spot.properties.value > 0 then color = table_of_colors.team end

            if spot.properties.force.name == global.table_of_properties[ player.force.name ].enemy and spot.properties.value > 0 then color = table_of_colors.enemy end

            element_button.style.font_color = color

        end

        for _, element_item in pairs( element_frame.children ) do

            element_item.style.width = 100

            element_item.style.height = 100

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.horizontal_align  = 'center'

            element_item.style.font  = 'heading-2'

        end

    end

    function create_a_tank( player )

        player.insert( { name = 'light-armor', count = 1 } )

        player.insert( { name = 'submachine-gun', count = 1 } )

        player.insert( { name = 'firearm-magazine', count = 50 } )

        player.insert( { name = 'raw-fish', count = 10 } )

        player.insert( { name = 'explosive-cannon-shell', count = 5 } )

        local table_of_entities = player.surface.find_entities_filtered( { name = 'tank', force = player.force.name } )

        if #table_of_entities < #player.force.connected_players then

            local position = player.surface.find_non_colliding_position( 'tank', player.position, 64, 4 )

            if not position then position = { 0, 0 } end

            local entity = player.surface.create_entity( { name = 'tank', position = position, force = player.force.name } )

            if not entity then return end

            entity.minable = false

            entity.last_user = player.name

            entity.insert( { name = 'wood', count = 50 } )

            entity.insert( { name = 'cannon-shell', count = 50 } )

            entity.set_driver( player )

            global.table_of_tanks[ player.index ] = entity

        end

    end

    function create_a_base( force_name, base_position )

        local surface = game.surfaces.tank_conquest

        local table_of_items = game.json_to_table( blueprint_poi_base_json )

        for _, tile in pairs( table_of_items.blueprint.tiles ) do tile.position = { x = tile.position.x + base_position.x, y = tile.position.y + base_position.y + 10 } end

        surface.set_tiles( table_of_items.blueprint.tiles, true )

        for _, object in pairs( table_of_items.blueprint.entities ) do

            object.force = game.forces[ force_name ]

            object.position = { x = object.position.x + base_position.x, y = object.position.y + base_position.y + 10 }

            local entity = surface.create_entity( object )

            if not entity then return end

            if object.name == 'infinity-chest' or object.name == 'substation' or object.name == 'big-electric-pole' or object.name == 'medium-electric-pole' or object.name == 'inserter' or object.name == 'accumulator' or object.name == 'solar-panel' or object.name == 'gun-turret' then

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

                entity.operable = false

            end

            if object.name == 'wooden-chest' then

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

            end

            if object.name == 'stone-wall' or object.name == 'gate' or object.name == 'land-mine' then

                entity.destructible = false

                entity.minable = false

            end

        end

    end

    function create_a_spot( spot_name, spot_position, spot_blueprint )

        local surface = game.surfaces.tank_conquest

        local spot = { name = spot_name, position = spot_position, force = { name = 'neutral' }, value = 0, color = table_of_colors.white }

        local table_of_positions = {}

        for x = 1, 18 do for y = 1, 18 do table.insert( table_of_positions, { x = math.floor( spot.position.x + x - 9 ), y = math.floor( spot.position.y + y - 9 ) } ) end end

        local table_of_players = {}

        local draw_spot_border = rendering.draw_rectangle( { surface = surface, target = spot.position, color = spot.color, left_top = { spot.position.x - 9, spot.position.y - 9 }, right_bottom = { spot.position.x + 9, spot.position.y + 9 }, width = 5, filled = false, draw_on_ground = true } )

        local draw_spot_force = rendering.draw_text( { text = spot.force.name, surface = surface, target = { spot.position.x, spot.position.y + 0.5 }, color = spot.color, scale = 5, alignment = 'center' } )

        local draw_spot_value = rendering.draw_text( { text = spot.value, surface = surface, target = { spot.position.x, spot.position.y - 4 }, color = spot.color, scale = 5, alignment = 'center' } )

        local draw_spot_name = rendering.draw_text( { text = spot.name, surface = surface, target = { spot.position.x, spot.position.y - 2 }, color = spot.color, scale = 5, alignment = 'center' } )

        local table_of_drawings = { name = draw_spot_name, value = draw_spot_value, force = draw_spot_force, border = draw_spot_border }

        local table_of_properties = { name = spot.name, position = spot.position, value = spot.value, force = spot.force, color = spot.color }

        local table_of_entities = {}

        local table_of_items = game.json_to_table( spot_blueprint )

        for _, tile in pairs( table_of_items.blueprint.tiles ) do tile.position = { x = tile.position.x + spot.position.x - 1, y = tile.position.y + spot.position.y - 1 } end

        surface.set_tiles( table_of_items.blueprint.tiles, true )

        for _, object in pairs( table_of_items.blueprint.entities ) do

            object.force = 'enemy'

            object.position = { x = object.position.x + spot.position.x - 1, y = object.position.y + spot.position.y - 1 }

            local entity = surface.create_entity( object )

            if not entity then return end

            if object.name == 'infinity-chest' or object.name == 'substation' or object.name == 'inserter' or object.name == 'accumulator' or object.name == 'solar-panel' then

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

                entity.operable = false

            end

            if object.name == 'wooden-chest' then

                entity.force = 'neutral'

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

            end

            if object.name == 'stone-wall' or object.name == 'gate' or object.name == 'land-mine' then entity.minable = false end

            table.insert( table_of_entities, entity )

        end

        table.insert( global.table_of_spots, { properties = table_of_properties, drawings = table_of_drawings, players = table_of_players, positions = table_of_positions, entities = table_of_entities } )

    end

    function create_a_point_of_interest( poi_blueprint, poi_position )

        local surface = game.surfaces.tank_conquest

        local table_of_items = game.json_to_table( poi_blueprint )

        for _, tile in pairs( table_of_items.blueprint.tiles ) do tile.position = { x = tile.position.x + poi_position.x, y = tile.position.y + poi_position.y } end

        surface.set_tiles( table_of_items.blueprint.tiles, true )

        for _, object in pairs( table_of_items.blueprint.entities ) do

            object.force = 'enemy'

            object.position = { x = object.position.x + poi_position.x, y = object.position.y + poi_position.y }

            local entity = surface.create_entity( object )

            if not entity then return end

            if object.name == 'infinity-chest' or object.name == 'substation' or object.name == 'inserter' or object.name == 'accumulator' or object.name == 'solar-panel' then

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

                entity.operable = false

            end

            if object.name == 'wooden-chest' then

                entity.force = 'neutral'

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

            end

            if object.name == 'stone-wall' or object.name == 'gate' or object.name == 'land-mine' then entity.minable = false end

        end

    end

    function seconds_to_clock( seconds )

        local seconds = tonumber( seconds )

        if seconds <= 0 then

            return '00:00:00'

        else

            local hours = string.format( '%02.f', math.floor( seconds / 3600 ) )

            local minutes = string.format( '%02.f', math.floor( seconds / 60 - ( hours * 60 ) ) )

            seconds = string.format( '%02.f', math.floor( seconds - hours * 3600 - minutes * 60 ) )

            return hours .. ':' .. minutes .. ':' .. seconds

        end

    end

    function draw_a_polygon( position, radius, angle, sides )

        if not type( position ) == 'table' then return end

        if not type( radius ) == 'number' then return end

        if not type( angle ) == 'number' then return end

        if not type( sides ) == 'number' then return end

        local table_of_positions = {}

        table.insert( table_of_positions, { x = position.x, y = position.y } )

        for index = 1, sides + 1 do

            local x = table_of_positions[ 1 ].x + ( radius * math.cos( angle + ( index + index - 1 ) * math.pi / sides ) )

            local y = table_of_positions[ 1 ].y + ( radius * math.sin( angle + ( index + index - 1 ) * math.pi / sides ) )

            table.insert( table_of_positions, { x = x, y = y } )

        end

        return table_of_positions

    end

    function draw_circle_lobby( surface, spawn_diameter, spawn_position )

        for x = - spawn_diameter, spawn_diameter do for y = - spawn_diameter, spawn_diameter do

            local tile_position = { x = spawn_position.x + x, y = spawn_position.y + y }

            local distance_to_center = math.sqrt( tile_position.x ^ 2 + tile_position.y ^ 2 )

            local tile_name = false

            if distance_to_center < spawn_diameter then

                tile_name = 'deepwater'

                if math.random( 1, 48 ) == 1 then surface.create_entity( { name = 'fish', position = tile_position } ) end

            end

            if distance_to_center < 9.5 then tile_name = 'refined-concrete' end

            if distance_to_center < 7 then tile_name = 'sand-1' end

            if tile_name then surface.set_tiles( { { name = tile_name, position = tile_position } }, true ) end

        end end

    end

    function event_on_click_join( player )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local surface = game.surfaces.tank_conquest

        if not surface then return end

        if not player.character then return end

        game.permissions.get_group( 'Default' ).add_player( player )

        if player.force.name == 'force_spectator' then

            if #game.forces.force_player_one.connected_players == #game.forces.force_player_two.connected_players then

                local table_of_forces = { 'force_player_one', 'force_player_two' }

                player.force = game.forces[ table_of_forces[ math.random( 1, #table_of_forces ) ] ]

            elseif #game.forces.force_player_one.connected_players < #game.forces.force_player_two.connected_players then

                player.force = game.forces.force_player_one

            else

                player.force = game.forces.force_player_two

            end

        end

        local position = player.force.get_spawn_position( surface )

        global.table_of_spawns[ player.index ] = position

        if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

        player.character.destructible = true

        player_icon_add( player )

        create_a_tank( player )

        -- draw_gui_spawn( player ) -- only for tests

        for _, spot in pairs( global.table_of_spots ) do player.force.chart( game.surfaces.tank_conquest, { { x = spot.properties.position.x - 10, y = spot.properties.position.y - 10 }, { x = spot.properties.position.x + 10, y = spot.properties.position.y + 10 } } ) end

        game.print( player.name .. ' joined ' .. global.table_of_properties[ player.force.name ].icon )

    end

    function event_on_click_lobby( player )

        local surface = game.surfaces.nauvis

        if global.table_of_properties.game_stage == 'ongoing_game' then surface = game.surfaces.tank_conquest end

        if not player.character then return end

        game.permissions.get_group( 'permission_spectator' ).add_player( player )

        player.force = game.forces.force_spectator

        if global.table_of_tanks[ player.index ] ~= nil and global.table_of_tanks[ player.index ].valid then

            global.table_of_tanks[ player.index ].clear_items_inside()

            global.table_of_tanks[ player.index ].destroy()

        end

        global.table_of_tanks[ player.index ] = nil

        local position = { x = 0, y = 0 }

        global.table_of_spawns[ player.index ] = position

        if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

        player.character.destructible = false

        player_icon_remove( player )

        player.character.clear_items_inside()

    end

    function event_on_click_spawn( player )

        game.print( 'A' )

    end

    function shuffle( table_of_items )

        local length_of_items = #table_of_items

            for index = length_of_items, 1, - 1 do

                local random = math.random( length_of_items )

                table_of_items[ index ], table_of_items[ random ] = table_of_items[ random ], table_of_items[ index ]

            end

        return table_of_items

    end

    local function on_init( surface )

        game.surfaces.nauvis.clear()

        game.surfaces.nauvis.map_gen_settings = { width = 1, height = 1 }

        game.create_surface( 'tank_conquest', { width = 1, height = 1 } )

        initialize_forces()

        -- global.table_of_properties.game_stage = 'do_nothing'

    end

    event.on_init( on_init )

    local function on_tick( event )

        if game.tick % 30 == 0 and global.table_of_damages ~= nil then

            for _, item in pairs( global.table_of_damages ) do item.surface.create_entity( { name = 'flying-text', position = item.position, text = math.ceil( item.damage ), color = table_of_colors.damage } ) end

            global.table_of_damages = nil

        end

        if game.tick % 60 == 0 then

            if global.table_of_properties.game_stage == 'ongoing_game' then

                for _, spot in pairs( global.table_of_spots ) do

                    if spot.properties.value == 100 then

                        local enemy = global.table_of_properties[ spot.properties.force.name ].enemy

                        if global.table_of_properties[ enemy ].available_tickets >= 0 then global.table_of_properties[ enemy ].available_tickets = global.table_of_properties[ enemy ].available_tickets - global.table_of_properties.acceleration_value end

                    end

                    for _, player in pairs( game.connected_players ) do if player.force.name == spot.properties.force.name and spot.properties.value > 0 then player.force.chart( game.surfaces.tank_conquest, { { x = spot.properties.position.x - 10, y = spot.properties.position.y - 10 }, { x = spot.properties.position.x + 10, y = spot.properties.position.y + 10 } } ) end end

                    for _, player in pairs( spot.players ) do

                        if spot.properties.force.name == 'neutral' and spot.properties.value == 0 then

                            spot.properties.force.name = player.force.name

                            for _, entity in pairs( spot.entities ) do

                                if entity.valid then

                                    entity.force = player.force.name

                                    if entity.name == 'stone-wall' or entity.name == 'gate' or entity.name == 'land-mine' then entity.minable = true end

                                end

                            end

                        end

                        if spot.properties.force.name == 'neutral' or spot.properties.force.name == player.force.name and spot.properties.value < 100 then spot.properties.value = spot.properties.value + 1 * global.table_of_properties.conquest_speed end

                        if spot.properties.force.name ~= player.force.name and spot.properties.value > 0 then spot.properties.value = spot.properties.value - 1 * global.table_of_properties.conquest_speed end

                        if spot.properties.value == 0 then spot.properties.force.name = 'neutral' end

                        local force_label = spot.properties.force.name

                        if force_label ~= 'neutral' then force_label = global.table_of_properties[ force_label ].icon end

                        rendering.set_text( spot.drawings.force, force_label )

                        rendering.set_text( spot.drawings.value, spot.properties.value )

                    end

                end

                if global.table_of_properties.countdown_in_seconds == 60 then game.print( 'The round is in the hot phase, there are still 60 seconds left.' ) end

                if global.table_of_properties.countdown_in_seconds >= 0 then global.table_of_properties.countdown_in_seconds = global.table_of_properties.countdown_in_seconds - 1 end

                if global.table_of_properties.countdown_in_seconds < 0 or global.table_of_properties.force_player_one.available_tickets < 0 or global.table_of_properties.force_player_two.available_tickets < 0 then

                    if global.table_of_properties.force_player_one.available_tickets == global.table_of_properties.force_player_two.available_tickets then

                        game.print( 'The battle is over. The round ended in a draw.' )

                    elseif global.table_of_properties.force_player_one.available_tickets > global.table_of_properties.force_player_two.available_tickets then

                        game.print( 'The battle is over. Force ' .. global.table_of_properties.force_player_one.icon .. ' has won the round.' )

                    else

                        game.print( 'The battle is over. Force ' .. global.table_of_properties.force_player_two.icon .. ' has won the round.' )

                    end

                    game.forces.force_spectator.set_spawn_position( { x = 0, y = 0 }, game.surfaces.nauvis )

                    global.table_of_spots = {}

                    global.table_of_properties.force_player_one.available_tickets = global.table_of_properties.amount_of_tickets

                    global.table_of_properties.force_player_two.available_tickets = global.table_of_properties.amount_of_tickets

                    global.table_of_properties.countdown_in_seconds = 28800

                    global.table_of_properties.wait_in_seconds = 30

                    global.table_of_properties.game_stage = 'lobby'

                    game.print( 'You are now in the lobby, please make yourself comfortable, it continues immediately.' )

                    for _, player in pairs( game.connected_players ) do

                        if player.gui.top[ 'draw_gui_button' ] then player.gui.top[ 'draw_gui_button' ].destroy() end

                        if player.gui.top[ 'draw_gui_status' ] then player.gui.top[ 'draw_gui_status' ].destroy() end

                        if player.gui.top[ 'draw_gui_spots' ] then player.gui.top[ 'draw_gui_spots' ].destroy() end

                        -- if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() end

                        -- if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

                        -- draw_gui_score( player )

                        event_on_click_lobby( player )

                    end

                end

                for _, player in pairs( game.connected_players ) do

                    draw_gui_status( player )

                    draw_gui_spots( player )

                end

            end

            if global.table_of_properties.game_stage == 'regenerate_facilities' then

                table_of_ores = shuffle( table_of_ores )

                local position = game.forces.force_spectator.get_spawn_position( game.surfaces.tank_conquest )

                draw_circle_lobby( game.surfaces.tank_conquest, 28, position )

                local position = game.forces.force_player_one.get_spawn_position( game.surfaces.tank_conquest )

                map_functions.draw_noise_tile_circle( { x = position.x - 50, y = 10 }, 'water', game.surfaces.tank_conquest, math.random( 8, 10 ) )

                local radius, angle, sides = 10, 1, #table_of_ores

                local table_of_positions = draw_a_polygon( { x = position.x - 50, y = 10 }, radius, angle, sides )

                for index = 1, #table_of_positions do map_functions.draw_smoothed_out_ore_circle( table_of_positions[ index + 1 ], table_of_ores[ index ], game.surfaces.tank_conquest, 15, 3000 ) end

                create_a_base( 'force_player_one', position )

                local position = game.forces.force_player_two.get_spawn_position( game.surfaces.tank_conquest )

                map_functions.draw_noise_tile_circle( { x = position.x + 50, y = 10 }, 'water', game.surfaces.tank_conquest, math.random( 8, 10 ) )

                local radius, angle, sides = 10, 1, #table_of_ores

                local table_of_positions = draw_a_polygon( { x = position.x + 50, y = 10 }, radius, angle, sides )

                for index = 1, #table_of_positions do map_functions.draw_smoothed_out_ore_circle( table_of_positions[ index + 1 ], table_of_ores[ index ], game.surfaces.tank_conquest, 15, 3000 ) end

                create_a_base( 'force_player_two', position )

                local position = { x = 0, y = - 500 }

                create_a_point_of_interest( blueprint_poi_laser_json, position )

                local position = { x = 0, y = 500 }

                create_a_point_of_interest( blueprint_poi_fire_json, position )

                local table_of_blueprints = { blueprint_poi_spot_one_json, blueprint_poi_spot_two_json, blueprint_poi_spot_three_json }

                local table_of_names = { 'A', 'B', 'C', 'D', 'E', 'F', 'G' }

                local length_of_names = math.random( 3, #table_of_names )

                local position, radius, angle, sides = { x = 0, y = 0 }, math.random( 150, 250 ), math.random( 0.1, 6.3 ), length_of_names

                local table_of_positions = draw_a_polygon( position, radius, angle, sides )

                for index = 1, length_of_names do create_a_spot( table_of_names[ index ], table_of_positions[ index + 1 ], table_of_blueprints[ math.random( 1, #table_of_blueprints ) ] ) end

                game.print( 'A new battlefield was created. Make yourself comfortable, but be vigilant.' )

                global.table_of_properties.game_stage = 'ongoing_game'

                for _, player in pairs( game.connected_players ) do

                    -- if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() end

                    -- if player.gui.center[ 'draw_gui_score' ] then player.gui.center[ 'draw_gui_score' ].destroy() end

                    if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

                    draw_gui_button( player )

                    event_on_click_join( player )

                end

            end

            if global.table_of_properties.game_stage == 'preparing_spawn_positions' then

                game.forces.force_player_one.set_spawn_position( { x = - 500, y = 0 }, game.surfaces.tank_conquest )

                game.forces.force_player_two.set_spawn_position( { x = 500, y = 0 }, game.surfaces.tank_conquest )

                game.forces.force_spectator.set_spawn_position( { x = 0, y = 0 }, game.surfaces.tank_conquest )

                global.table_of_scores = {}

                for _, player in pairs( game.connected_players ) do

                    if player.character then

                        player.character.destroy()

                        player.character = nil

                    end

                    player.create_character()

                end

                global.table_of_properties.game_stage = 'regenerate_facilities'

            end

            if global.table_of_properties.game_stage == 'check_the_process_of_creating_the_map' then

                if game.surfaces.tank_conquest.is_chunk_generated( { x = 0, y = 0 } ) then

                    global.table_of_properties.game_stage = 'preparing_spawn_positions'

                else

                    game.surfaces.tank_conquest.request_to_generate_chunks( { 0, 0 }, 1 )

                    game.surfaces.tank_conquest.request_to_generate_chunks( { - 500, 0 }, 1 )

                    game.surfaces.tank_conquest.request_to_generate_chunks( { 500, 0 }, 1 )

                    game.surfaces.tank_conquest.request_to_generate_chunks( { 0, - 500 }, 1 )

                    game.surfaces.tank_conquest.request_to_generate_chunks( { 0, 500 }, 1 )

                end

            end

            if global.table_of_properties.game_stage == 'regenerate_battlefield' and global.table_of_properties.wait_in_seconds == 0 then

                initialize_surface()

                game.surfaces.tank_conquest.force_generate_chunk_requests()

                global.table_of_properties.game_stage = 'check_the_process_of_creating_the_map'

            end

            if global.table_of_properties.game_stage == 'lobby' then

                if #game.connected_players >= global.table_of_properties.required_number_of_players and global.table_of_properties.wait_in_seconds > 0 then

                    if global.table_of_properties.wait_in_seconds % 10 == 0 then game.print( 'The round starts in ' .. global.table_of_properties.wait_in_seconds .. ' seconds.' ) end

                    global.table_of_properties.wait_in_seconds = global.table_of_properties.wait_in_seconds - 1

                end

                if global.table_of_properties.wait_in_seconds == 0 then global.table_of_properties.game_stage = 'regenerate_battlefield' end

            end

        end

        if game.tick % 1800 == 0 then

            if game.surfaces.tank_conquest ~= nil and #game.connected_players and #global.table_of_spots then

                for _, player in pairs( game.connected_players ) do

                    for _, spot in pairs( global.table_of_spots ) do

                        if player.force.is_chunk_charted( game.surfaces.tank_conquest, { x = math.floor( spot.properties.position.x / 32 ), y = math.floor( spot.properties.position.y / 32 ) } ) then

                            local chart_tags = player.force.find_chart_tags( game.surfaces.tank_conquest, { { spot.properties.position.x - 1, spot.properties.position.y - 1 }, { spot.properties.position.x + 1, spot.properties.position.y + 1 } } )

                            if #chart_tags == 0 then player.force.add_chart_tag( game.surfaces.tank_conquest, { icon = { type = 'virtual', name = 'signal-' .. spot.properties.name }, position = spot.properties.position } ) end

                        end

                    end

                end

            end

        end

        if game.tick == 60 then

            draw_circle_lobby( game.surfaces.nauvis, 28, { x = 0, y = 0 } )

            for _, player in pairs( game.connected_players ) do if player.character == nil then player.create_character() end end

        end

    end

    event.add( defines.events.on_tick, on_tick )

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == 'draw_gui_intro_content' then player.gui.center[ 'draw_gui_intro_frame' ].destroy() return end

        if event.element.valid and event.element.name == 'draw_gui_intro_button' then

            if player.gui.center[ 'draw_gui_intro_frame' ] then player.gui.center[ 'draw_gui_intro_frame' ].destroy() else draw_gui_intro_frame( player ) end

        end

        if event.element.valid and event.element.name == 'draw_gui_button' then

            if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() else draw_gui_menu( player ) end

        end

        if event.element.valid and event.element.name == 'event_on_click_score' then

            if player.gui.center[ 'draw_gui_score' ] then player.gui.center[ 'draw_gui_score' ].destroy() else draw_gui_score( player ) end

        end

        if event.element.valid and event.element.name == 'event_on_click_squad' then

            if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() else draw_gui_squad( player ) end

        end

        if event.element.valid and event.element.name == 'event_on_click_lobby' then

            global.table_of_delays[ player.index ] = game.tick

            game.print( player.name .. ' is spectating' )

            event_on_click_lobby( player )

            if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

        end

        if event.element.valid and event.element.name == 'event_on_click_join' then

            if game.tick - global.table_of_delays[ player.index ] < 3600 then

                player.print( 'Not ready to return. Please wait ' .. 60 - ( math.floor( ( game.tick - global.table_of_delays[ player.index ] ) / 60 ) ) .. ' seconds.' )

            else

                global.table_of_delays[ player.index ] = nil

                event_on_click_join( player )

                if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

            end

        end

        if event.element.valid and event.element.name == 'event_on_click_spawn_1' then

            event_on_click_spawn( player )

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_console_chat( event )

        if not event.message then return end

        if not event.player_index then return end

        local player = game.players[ event.player_index ]

        local color = { r = player.color.r * 0.6 + 0.35, g = player.color.g * 0.6 + 0.35, b = player.color.b * 0.6 + 0.35, a = 1 }

        if player.force.name == 'force_player_one' then

            game.forces.force_player_two.print( global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ': '.. event.message, color )

            game.forces.force_spectator.print( global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ': '.. event.message, color )

        end

        if player.force.name == 'force_player_two' then

            game.forces.force_player_one.print( global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ': '.. event.message, color )

            game.forces.force_spectator.print( global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ': '.. event.message, color )

        end

        if player.force.name == 'force_spectator' then

            game.forces.force_player_one.print( '(Spectator) ' .. player.name .. ': '.. event.message, color )

            game.forces.force_player_two.print( '(Spectator) ' .. player.name .. ': '.. event.message, color )

        end

    end

    event.add( defines.events.on_console_chat, on_console_chat )

    local function on_chunk_generated( event )

        local chunk_position = { x = event.area.left_top.x, y = event.area.left_top.y }

        for x = 0, 31 do for y = 0, 31 do

            local tile_position = { x = chunk_position.x + x, y = chunk_position.y + y }

            if math.random( 1, 3000 ) == 1 and event.surface.can_place_entity( { name = 'wooden-chest', force = 'enemy', position = tile_position } ) then event.surface.create_entity( { name = 'wooden-chest', force = 'enemy', position = tile_position } ) end

        end end

    end

    event.add( defines.events.on_chunk_generated, on_chunk_generated )

    local function on_entity_damaged( event )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        if event.entity.name == 'wooden-chest' then return end

        if not event.entity.unit_number then return end

        if event.final_damage_amount < 1 then return end

        if global.table_of_damages == nil then global.table_of_damages = {} end

        if global.table_of_damages[ event.entity.unit_number ] == nil then global.table_of_damages[ event.entity.unit_number ] = { surface = event.entity.surface, position = event.entity.position, damage = 0 } end

        global.table_of_damages[ event.entity.unit_number ].damage = global.table_of_damages[ event.entity.unit_number ].damage + event.final_damage_amount

    end

    event.add( defines.events.on_entity_damaged, on_entity_damaged )

    local function on_entity_died( event )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        if event.entity.name == 'wooden-chest' and event.entity.force.name == 'enemy' then

            local loot = table_of_loots[ math.random( 1, #table_of_loots ) ]

            event.entity.surface.spill_item_stack( event.entity.position, loot, true )

            event.entity.surface.create_entity( { name = 'flying-text', position = event.entity.position, text = '+' .. loot.count .. ' ' .. loot.name, color = table_of_colors.white } )

        end

    end

    event.add( defines.events.on_entity_died, on_entity_died )

    local function on_player_changed_position( event )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local player = game.players[ event.player_index ]

        for spot_index, spot_item in pairs( global.table_of_spots ) do

            if global.table_of_spots[ spot_index ].players[ player.index ] ~= nil then global.table_of_spots[ spot_index ].players[ player.index ] = nil end

            for _, position in pairs( spot_item.positions ) do

                if math.floor( player.position.x ) == position.x and math.floor( player.position.y ) == position.y or math.ceil( player.position.x ) == position.x and math.ceil( player.position.y ) == position.y then

                    if global.table_of_spots[ spot_index ].players[ player.index ] == nil then

                        global.table_of_spots[ spot_index ].players[ player.index ] = player

                        break

                    end

                end

            end

            if global.table_of_spots[ spot_index ].players[ player.index ] ~= nil then break end

        end

    end

    event.add( defines.events.on_player_changed_position, on_player_changed_position )

    local function on_player_respawned( event )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local player = game.players[ event.player_index ]

        local surface = player.surface

        if player.gui.center[ 'draw_gui_spawn' ] then player.gui.center[ 'draw_gui_spawn' ].destroy() end

        local position = global.table_of_spawns[ player.index ]

        if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

        player_icon_add( player )

        create_a_tank( player )

    end

    event.add( defines.events.on_player_respawned, on_player_respawned )

    local function on_player_died( event )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local player = game.players[ event.player_index ]

        global.table_of_spawns[ player.index ] = player.force.get_spawn_position( player.surface )

        local table_of_entities = player.surface.find_entities_filtered( { name = 'character-corpse' } )

        for _, entity in pairs( table_of_entities ) do

            entity.clear_items_inside()

            entity.destroy()

        end

        -- draw_gui_spawn( player )

        player_icon_remove( player )

        if global.table_of_tanks[ player.index ] ~= nil and global.table_of_tanks[ player.index ].valid then

            global.table_of_tanks[ player.index ].clear_items_inside()

            global.table_of_tanks[ player.index ].destroy()

        end

        global.table_of_tanks[ player.index ] = nil

        local force = global.table_of_properties[ player.force.name ]

        if force ~= nil and force.available_tickets > 0 then force.available_tickets = force.available_tickets - 1 end

        for _, spot in pairs( global.table_of_spots ) do if spot.players[ player.index ] ~= nil then spot.players[ player.index ] = nil end end

        local player_death_message = global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ' was killed.'

        if event.cause and event.cause.valid then

            if event.cause.name == 'character' then

                player_death_message = global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ' was killed by ' .. global.table_of_properties[ event.cause.player.force.name ].icon .. ' ' .. event.cause.player.name .. '.'

            elseif event.cause.name == 'car' or event.cause.name == 'tank' or event.cause.name == 'train' then

                local driver = event.cause.get_driver()

                if driver.player then

                    player_death_message = global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ' was killed with a vehicle by ' .. global.table_of_properties[ driver.player.force.name ].icon .. ' ' .. driver.player.name .. '.'

                else

                    player_death_message = global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ' was killed by run over.'

                end

            elseif event.cause.name then

                player_death_message = global.table_of_properties[ player.force.name ].icon .. ' ' .. player.name .. ' was killed by ' .. event.cause.name .. '.'

            end

        end

        for _, p in pairs( game.connected_players ) do

            if p.force.name ~= player.force.name and p.name ~= event.cause.player.name and p.name ~= driver.player.name then

                p.print( player_death_message, table_of_colors.damage )

            end

        end

    end

    event.add( defines.events.on_player_died, on_player_died )

    local function on_player_left_game( event )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local player = game.players[ event.player_index ]

        player_icon_remove( player )

        if global.table_of_tanks[ player.index ] ~= nil and global.table_of_tanks[ player.index ].valid then

            global.table_of_tanks[ player.index ].clear_items_inside()

            global.table_of_tanks[ player.index ].destroy()

        end

        global.table_of_tanks[ player.index ] = nil

        global.table_of_spawns[ player.index ] = nil

        for _, spot in pairs( global.table_of_spots ) do if spot.players[ player.index ] ~= nil then spot.players[ player.index ] = nil end end

    end

    event.add( defines.events.on_player_left_game, on_player_left_game )

    local function on_player_joined_game( event )

        local surface = game.surfaces.nauvis

        local player = game.players[ event.player_index ]

        player.force = game.forces.force_spectator

        draw_gui_intro_button( player )

        if player.online_time == 0 then

            draw_gui_intro_frame( player )

            local position = player.force.get_spawn_position( surface )

            if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

            player.character.destructible = false

            game.permissions.get_group( 'permission_spectator' ).add_player( player )

        elseif player.surface.name == 'tank_conquest' then

            player.character.clear_items_inside()

            draw_gui_button( player )

            event_on_click_join( player )

        end

        if player.online_time == 0 and global.table_of_properties.game_stage == 'ongoing_game' then

            draw_gui_button( player )

            draw_gui_menu( player )

        end

        for index, slot in pairs( table_of_slots ) do

            player.set_quick_bar_slot( index, slot )

        end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )

    function player_icon_add( player )

        if global.table_of_drawings[ player.index ] == nil then

            -- local icon = rendering.draw_circle( { target = player.character, target_offset = { x = 0, y = - 3.7 }, force = game.forces.force_player_one, surface = player.surface, color = table_of_colors.team, radius = 0.3, filled = true, only_in_alt_mode = false } )

            -- local color = { r = player.color.r * 0.6 + 0.35, g = player.color.g * 0.6 + 0.35, b = player.color.b * 0.6 + 0.35, a = 1 }

            local icon = rendering.draw_text( { text = global.table_of_properties[ player.force.name ].icon, target = player.character, target_offset = { 0, - 3.7 }, surface = player.surface, color = table_of_colors.white, scale = 2, alignment = 'center' } )

            global.table_of_drawings[ player.index ] = icon

        end

    end

    function player_icon_change( player )

        if global.table_of_drawings[ player.index ] ~= nil then

            local icon = global.table_of_drawings[ player.index ]

        end

    end

    function player_icon_remove( player )

        if global.table_of_drawings[ player.index ] ~= nil then

            rendering.destroy( global.table_of_drawings[ player.index ] )

            global.table_of_drawings[ player.index ] = nil

        end

    end
