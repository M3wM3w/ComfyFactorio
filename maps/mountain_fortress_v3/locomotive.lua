local Event = require 'utils.event'
--local Power = require 'maps.mountain_fortress_v3.power'
local Market = require 'maps.mountain_fortress_v3.basic_markets'
local Generate = require 'maps.mountain_fortress_v3.generate'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WPT = require 'maps.mountain_fortress_v3.table'
local WD = require 'modules.wave_defense.table'
local Session = require 'utils.datastore.session_data'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Jailed = require 'utils.datastore.jail_data'
local RPG_Settings = require 'modules.rpg.table'
local Functions = require 'modules.rpg.functions'
local Gui = require 'utils.gui'
local Server = require 'utils.server'
local Alert = require 'utils.alert'
local Math2D = require 'math2d'
local Antigrief = require 'antigrief'
local Task = require 'utils.task'
local Token = require 'utils.token'
local MapFunctions = require 'tools.map_functions'
local SpamProtection = require 'utils.spam_protection'

local format_number = require 'util'.format_number

local Public = {}
local concat = table.concat
local main_frame_name = Gui.uid_name()
local rpg_main_frame = RPG_Settings.main_frame_name
local random = math.random
local floor = math.floor
local round = math.round
local rad = math.rad
local sin = math.sin
local cos = math.cos
local ceil = math.ceil

local shopkeeper = '[color=blue]Shopkeeper:[/color]\n'

local space = {
    minimal_height = 10,
    top_padding = 0,
    bottom_padding = 0
}

local function initial_cargo_boxes()
    return {
        {name = 'loader', count = 1},
        {name = 'coal', count = random(32, 64)},
        {name = 'coal', count = random(32, 64)},
        {name = 'iron-ore', count = random(32, 128)},
        {name = 'copper-ore', count = random(32, 128)},
        {name = 'empty-barrel', count = random(16, 32)},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'land-mine', count = random(6, 18)},
        {name = 'grenade', count = random(2, 3)},
        {name = 'grenade', count = random(2, 3)},
        {name = 'grenade', count = random(2, 3)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'firearm-magazine', count = random(10, 30)},
        {name = 'firearm-magazine', count = random(10, 30)},
        {name = 'firearm-magazine', count = random(10, 30)},
        {name = 'rail', count = random(16, 24)},
        {name = 'rail', count = random(16, 24)}
    }
end

local function add_random_loot_to_main_market(rarity)
    local main_market_items = WPT.get('main_market_items')
    local items = Market.get_random_item(rarity, true, false)
    if not items then
        return false
    end

    local types = game.item_prototypes

    for k, v in pairs(main_market_items) do
        if not v.static then
            main_market_items[k] = nil
        end
    end

    for k, v in pairs(items) do
        local price = v.price[1][2] + random(1, 15) * rarity
        local value = v.price[1][1]
        local stack = 1
        if v.offer.item == 'coin' then
            price = v.price[1][2]
            stack = v.offer.count
            if not stack then
                stack = v.price[1][2]
            end
        end

        if not main_market_items[v.offer.item] then
            main_market_items[v.offer.item] = {
                stack = stack,
                value = value,
                price = price,
                tooltip = types[v.offer.item].localised_name,
                upgrade = false
            }
        end
    end
end

local set_loco_tiles =
    Token.register(
    function(data)
        local position = data.position
        local surface = data.surface
        if not surface or not surface.valid then
            return
        end

        local cargo_boxes = initial_cargo_boxes()

        local p = {}

        for x = position.x - 5, 1, 3 do
            for y = 1, position.y + 5, 2 do
                if random(1, 4) == 1 then
                    p[#p + 1] = {x = x, y = y}
                end
            end
        end

        MapFunctions.draw_noise_tile_circle(position, 'blue-refined-concrete', surface, 15)

        for i = 1, #cargo_boxes, 1 do
            if not p[i] then
                break
            end
            if surface.can_place_entity({name = 'wooden-chest', position = p[i]}) then
                local e = surface.create_entity({name = 'wooden-chest', position = p[i], force = 'player', create_build_effect_smoke = false})
                e.minable = false
                local inventory = e.get_inventory(defines.inventory.chest)
                inventory.insert(cargo_boxes[i])
            end
        end
    end
)

local function add_style(frame, style)
    for k, v in pairs(style) do
        frame.style[k] = v
    end
end

local function add_space(frame)
    add_style(frame.add {type = 'line', direction = 'horizontal'}, space)
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.name] then
        return false
    end
    return true
end

function Public.add_player_to_permission_group(player, group, forced)
    local jailed = Jailed.get_jailed_table()
    local enable_permission_group_disconnect = WPT.get('disconnect_wagon')
    local session = Session.get_session_table()
    local AG = Antigrief.get()

    if not AG.enabled then
        local default_group = game.permissions.get_group('Default')
        default_group.add_player(player)
        return
    end

    local gulag = game.permissions.get_group('gulag')
    local tbl = gulag and gulag.players
    for i = 1, #tbl do
        if tbl[i].index == player.index then
            return
        end
    end

    if player.admin then
        return
    end

    if forced then
        local default_group = game.permissions.get_group('Default')
        default_group.add_player(player)
        return
    end

    local playtime = player.online_time
    if session[player.name] then
        playtime = player.online_time + session[player.name]
    end

    if jailed[player.name] then
        return
    end

    if not game.permissions.get_group('locomotive') then
        local locomotive_group = game.permissions.create_group('locomotive')
        locomotive_group.set_allows_action(defines.input_action.cancel_craft, false)
        locomotive_group.set_allows_action(defines.input_action.edit_permission_group, false)
        locomotive_group.set_allows_action(defines.input_action.import_permissions_string, false)
        locomotive_group.set_allows_action(defines.input_action.delete_permission_group, false)
        locomotive_group.set_allows_action(defines.input_action.add_permission_group, false)
        locomotive_group.set_allows_action(defines.input_action.admin_action, false)
        locomotive_group.set_allows_action(defines.input_action.drop_item, false)
        locomotive_group.set_allows_action(defines.input_action.place_equipment, false)
    end

    if not game.permissions.get_group('plebs') then
        local plebs_group = game.permissions.create_group('plebs')
        plebs_group.set_allows_action(defines.input_action.edit_permission_group, false)
        plebs_group.set_allows_action(defines.input_action.import_permissions_string, false)
        plebs_group.set_allows_action(defines.input_action.delete_permission_group, false)
        plebs_group.set_allows_action(defines.input_action.add_permission_group, false)
        plebs_group.set_allows_action(defines.input_action.admin_action, false)
    end

    if not game.permissions.get_group('not_trusted') then
        local not_trusted = game.permissions.create_group('not_trusted')
        not_trusted.set_allows_action(defines.input_action.cancel_craft, false)
        not_trusted.set_allows_action(defines.input_action.edit_permission_group, false)
        not_trusted.set_allows_action(defines.input_action.import_permissions_string, false)
        not_trusted.set_allows_action(defines.input_action.delete_permission_group, false)
        not_trusted.set_allows_action(defines.input_action.add_permission_group, false)
        not_trusted.set_allows_action(defines.input_action.admin_action, false)
        not_trusted.set_allows_action(defines.input_action.drop_item, false)
        not_trusted.set_allows_action(defines.input_action.place_equipment, false)
        not_trusted.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        not_trusted.set_allows_action(defines.input_action.connect_rolling_stock, false)
    end

    if enable_permission_group_disconnect then
        local locomotive_group = game.permissions.get_group('locomotive')
        local plebs_group = game.permissions.get_group('plebs')
        local default_group = game.permissions.get_group('Default')
        if locomotive_group then
            locomotive_group.set_allows_action(defines.input_action.disconnect_rolling_stock, true)
        end
        if plebs_group then
            plebs_group.set_allows_action(defines.input_action.disconnect_rolling_stock, true)
        end
        if default_group then
            default_group.set_allows_action(defines.input_action.disconnect_rolling_stock, true)
        end
    else
        local locomotive_group = game.permissions.get_group('locomotive')
        local plebs_group = game.permissions.get_group('plebs')
        local default_group = game.permissions.get_group('Default')
        if locomotive_group then
            locomotive_group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        end
        if plebs_group then
            plebs_group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        end
        if default_group then
            default_group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        end
    end

    if playtime < 5184000 then -- 24 hours
        local not_trusted = game.permissions.get_group('not_trusted')
        not_trusted.add_player(player)
    else
        if group == 'locomotive' then
            local locomotive_group = game.permissions.get_group('locomotive')
            locomotive_group.add_player(player)
        elseif group == 'plebs' then
            local plebs_group = game.permissions.get_group('plebs')

            plebs_group.add_player(player)
        elseif group == 'default' then
            local default_group = game.permissions.get_group('Default')

            default_group.add_player(player)
        end
    end
end

local function property_boost(data)
    local xp_floating_text_color = {r = 188, g = 201, b = 63}
    local visuals_delay = 1800
    local loco_surface = WPT.get('loco_surface')
    if not (loco_surface and loco_surface.valid) then
        return
    end
    local locomotive_xp_aura = WPT.get('locomotive_xp_aura')
    local locomotive = WPT.get('locomotive')
    local xp_points = WPT.get('xp_points')
    local aura = locomotive_xp_aura
    local rpg = data.rpg
    local loco = locomotive.position
    local area = {
        left_top = {x = loco.x - aura, y = loco.y - aura},
        right_bottom = {x = loco.x + aura, y = loco.y + aura}
    }

    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            return
        end
        if player.afk_time < 200 then
            if Math2D.bounding_box.contains_point(area, player.position) or player.surface.index == loco_surface.index then
                Public.add_player_to_permission_group(player, 'locomotive')
                local pos = player.position
                Functions.gain_xp(player, 0.5 * (rpg[player.index].bonus + xp_points))

                player.create_local_flying_text {
                    text = '+' .. '',
                    position = {x = pos.x, y = pos.y - 2},
                    color = xp_floating_text_color,
                    time_to_live = 60,
                    speed = 3
                }
                rpg[player.index].xp_since_last_floaty_text = 0
                rpg[player.index].last_floaty_text = game.tick + visuals_delay
                if player.gui.screen[rpg_main_frame] then
                    local f = player.gui.screen[rpg_main_frame]
                    local d = Gui.get_data(f)
                    if d.exp_gui and d.exp_gui.valid then
                        d.exp_gui.caption = floor(rpg[player.index].xp)
                    end
                end
            else
                Public.add_player_to_permission_group(player, 'plebs', true)
            end
        end
    end
end

local function is_around_train(data)
    local entity = data.entity
    local aura = data.aura + 20
    local loco = data.locomotive.position
    local area = {
        left_top = {x = loco.x - aura, y = loco.y - aura},
        right_bottom = {x = loco.x + aura, y = loco.y + aura}
    }
    local pos = entity.position

    if Math2D.bounding_box.contains_point(area, pos) then
        return true
    end
    return false
end

local function fish_tag()
    local locomotive_cargo = WPT.get('locomotive_cargo')
    if not (locomotive_cargo and locomotive_cargo.valid) then
        return
    end
    if not (locomotive_cargo.surface and locomotive_cargo.surface.valid) then
        return
    end

    local locomotive_tag = WPT.get('locomotive_tag')

    if locomotive_tag then
        if locomotive_tag.valid then
            if locomotive_tag.position.x == locomotive_cargo.position.x and locomotive_tag.position.y == locomotive_cargo.position.y then
                return
            end
            locomotive_tag.destroy()
        end
    end
    WPT.set().locomotive_tag =
        locomotive_cargo.force.add_chart_tag(
        locomotive_cargo.surface,
        {
            icon = {type = 'item', name = 'raw-fish'},
            position = locomotive_cargo.position,
            text = ' '
        }
    )
end

local function set_player_spawn()
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local position = locomotive.surface.find_non_colliding_position('stone-furnace', locomotive.position, 16, 2)
    if not position then
        return
    end
    game.forces.player.set_spawn_position({x = position.x, y = position.y}, locomotive.surface)
end

local function refill_fish()
    local locomotive_cargo = WPT.get('locomotive_cargo')
    if not locomotive_cargo then
        return
    end
    if not locomotive_cargo.valid then
        return
    end
    locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = 'raw-fish', count = random(2, 5)})
end

local function set_locomotive_health()
    local locomotive_health = WPT.get('locomotive_health')
    local locomotive_max_health = WPT.get('locomotive_max_health')
    local locomotive = WPT.get('locomotive')

    local function check_health()
        local m = locomotive_health / locomotive_max_health
        if locomotive_health > locomotive_max_health then
            WPT.set('locomotive_health', locomotive_max_health)
        end
        WPT.set().carriages = locomotive.train.carriages
        local carriages = WPT.get('carriages')
        if carriages then
            for i = 1, #carriages do
                local entity = carriages[i]
                if not (entity and entity.valid) then
                    return
                end
                local cargo_health = 600
                local modded = is_game_modded()
                if modded then
                    cargo_health = 750
                end
                if entity.type == 'locomotive' then
                    entity.health = 1000 * m
                else
                    entity.health = cargo_health * m
                end
            end
        end
    end

    if not (locomotive and locomotive.valid) then
        return
    end

    check_health()
end

local function validate_index()
    local icw_table = ICW.get_table()
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local icw_locomotive = WPT.get('icw_locomotive')
    local loco_surface = icw_locomotive.surface
    local unit_surface = locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]
    if loco_surface.valid then
        WPT.set().loco_surface = locomotive_surface
    end
end

local function create_defense_system(position, name, target)
    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]

    local random_angles = {
        rad(random(359)),
        rad(random(359)),
        rad(random(359)),
        rad(random(359))
    }

    surface.create_entity(
        {
            name = name,
            position = {x = position.x, y = position.y},
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[1]),
                y = position.y + 12 * sin(random_angles[1])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[2]),
                y = position.y + 12 * sin(random_angles[2])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[3]),
                y = position.y + 12 * sin(random_angles[3])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[4]),
                y = position.y + 12 * sin(random_angles[4])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
end

local function close_market_gui(player)
    local players = WPT.get('players')

    local element = player.gui.screen
    local data = players[player.index].data
    if not data then
        return
    end

    local frame = element[main_frame_name]
    Public.close_gui_player(frame)
    if data then
        players[player.index].data = nil
    end
end

local function redraw_market_items(gui, player, search_text)
    if not validate_player(player) then
        return
    end
    local players = WPT.get('players')
    local trusted = Session.get_trusted_table()

    if gui and gui.valid then
        gui.clear()
    end

    local inventory = player.get_main_inventory()
    local player_item_count

    if not (gui and gui.valid) then
        return
    end

    gui.add(
        {
            type = 'label',
            caption = ({'locomotive.upgrades'})
        }
    )

    local upgrade_table = gui.add({type = 'table', column_count = 6})

    for item, data in pairs(Public.get_items()) do
        if data.upgrade then
            if not search_text then
                goto continue
            end
            if not search_text.text then
                goto continue
            end
            if not string.lower(item:gsub('-', ' ')):find(search_text.text) then
                goto continue
            end
            local item_count = data.stack
            local item_cost = data.price

            local frame = upgrade_table.add({type = 'flow'})
            frame.style.vertical_align = 'bottom'

            player_item_count = inventory.get_item_count(data.value)

            local button =
                frame.add(
                {
                    type = 'sprite-button',
                    sprite = data.sprite or 'item/' .. item,
                    number = item_count,
                    name = item,
                    tooltip = data.tooltip,
                    style = 'slot_button',
                    enabled = data.enabled
                }
            )
            local label =
                frame.add(
                {
                    type = 'label',
                    caption = concat {'[item=', data.value, ']: '} .. format_number(item_cost, true)
                }
            )
            label.style.font = 'default-bold'

            if player_item_count < item_cost then
                button.enabled = false
            end
            ::continue::
        end
    end
    gui.add(
        {
            type = 'label',
            caption = ({'locomotive.items'})
        }
    )

    local slider_value = ceil(players[player.index].data.slider.slider_value)
    local items_table = gui.add({type = 'table', column_count = 6})

    for item, data in pairs(Public.get_items()) do
        if not data.upgrade then
            if not search_text then
                goto continue
            end
            if not search_text.text then
                goto continue
            end
            if not string.lower(item:gsub('-', ' ')):find(search_text.text) then
                goto continue
            end
            local item_count = data.stack * slider_value
            local item_cost = data.price * slider_value

            local frame = items_table.add({type = 'flow'})
            frame.style.vertical_align = 'bottom'

            player_item_count = inventory.get_item_count(data.value)

            local button =
                frame.add(
                {
                    type = 'sprite-button',
                    sprite = data.sprite or 'item/' .. item,
                    number = item_count,
                    name = item,
                    tooltip = data.tooltip,
                    style = 'slot_button',
                    enabled = data.enabled
                }
            )
            if WPT.get('trusted_only_car_tanks') then
                if not trusted[player.name] then
                    if item == 'tank' then
                        button.enabled = false
                        button.tooltip = ({'locomotive.not_trusted'})
                    end
                    if item == 'car' then
                        button.enabled = false
                        button.tooltip = ({'locomotive.not_trusted'})
                    end
                end
            end

            local label =
                frame.add(
                {
                    type = 'label',
                    caption = concat {'[item=', data.value, ']: '} .. format_number(item_cost, true)
                }
            )
            label.style.font = 'default-bold'

            if player_item_count < item_cost then
                button.enabled = false
            end
            ::continue::
        end
    end
end

local function redraw_coins_left(gui, player)
    if not validate_player(player) then
        return
    end

    gui.clear()
    local inventory = player.get_main_inventory()
    local player_item_count = inventory.get_item_count('coin')

    local coinsleft =
        gui.add(
        {
            type = 'label',
            caption = ({'locomotive.coins_left', format_number(player_item_count, true)})
        }
    )

    add_space(coinsleft)
end

local function slider_changed(event)
    local player = game.players[event.player_index]
    local players = WPT.get('players')
    local slider_value

    slider_value = players
    if not slider_value then
        return
    end
    slider_value = slider_value[player.index].data
    if not slider_value then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, 2, 'Locomotive Slider Change')
    if is_spamming then
        return
    end
    slider_value = slider_value.slider
    if not slider_value then
        return
    end
    slider_value = slider_value.slider_value
    if not slider_value then
        return
    end
    slider_value = ceil(slider_value)
    if players[player.index] and players[player.index].data and players[player.index].data.text_input then
        players[player.index].data.text_input.text = tostring(slider_value)
        redraw_market_items(players[player.index].data.item_frame, player, players[player.index].data.search_text)
    end
end

local function text_changed(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end

    local players = WPT.get('players')
    local player = game.players[event.player_index]

    local data = players[player.index].data
    if not data then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, 2, 'Locomotive Text Changed')
    if is_spamming then
        return
    end

    if not data.text_input or not data.text_input.valid then
        return
    end

    if not data.text_input.text then
        return
    end

    local value = tonumber(data.text_input.text)

    if not value then
        return
    end

    if (value > 1e2) then
        data.text_input.text = '100'
        value = 1e2
    elseif (value <= 0) then
        data.text_input.text = '1'
        value = 1
    end

    data.slider.slider_value = tostring(value)

    redraw_market_items(data.item_frame, player, data.search_text)
end

local function gui_opened(event)
    local market = WPT.get('market')

    if not event.gui_type == defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity then
        return
    end

    if entity ~= market then
        return
    end

    local player = game.players[event.player_index]

    if not validate_player(player) then
        return
    end

    local inventory = player.get_main_inventory()
    local player_item_count = inventory.get_item_count('coin')

    local players = WPT.get('players')

    if not players[player.index].data then
        players[player.index].data = {}
    end

    local data = players[player.index].data

    if data.frame then
        data.frame = nil
    end
    local frame =
        player.gui.screen.add(
        {
            type = 'frame',
            caption = ({'locomotive.market_name'}),
            direction = 'vertical',
            name = main_frame_name
        }
    )

    frame.auto_center = true

    player.opened = frame
    frame.style.minimal_width = 325
    frame.style.minimal_height = 250

    local search_table = frame.add({type = 'table', column_count = 2})
    search_table.add({type = 'label', caption = ({'locomotive.search_text'})})
    local search_text = search_table.add({type = 'textfield'})
    search_text.style.width = 140

    add_space(frame)

    local pane =
        frame.add {
        type = 'scroll-pane',
        direction = 'vertical',
        vertical_scroll_policy = 'always',
        horizontal_scroll_policy = 'never'
    }
    pane.style.maximal_height = 200
    pane.style.horizontally_stretchable = true
    pane.style.minimal_height = 200
    pane.style.right_padding = 0

    local flow = frame.add({type = 'flow'})

    add_space(flow)

    local bottom_grid = frame.add({type = 'table', column_count = 4})
    bottom_grid.style.vertically_stretchable = false

    local bg = bottom_grid.add({type = 'label', caption = ({'locomotive.quantity_text'})})
    bg.style.font = 'default-bold'

    local text_input =
        bottom_grid.add(
        {
            type = 'text-box',
            text = 1
        }
    )
    text_input.style.maximal_height = 28

    local slider =
        frame.add(
        {
            type = 'slider',
            minimum_value = 1,
            maximum_value = 1e2,
            value = 1
        }
    )
    slider.style.width = 115
    text_input.style.width = 60

    local coinsleft = frame.add({type = 'flow'})

    coinsleft.add(
        {
            type = 'label',
            caption = ({'locomotive.coins_left', format_number(player_item_count, true)})
        }
    )

    players[player.index].data.search_text = search_text
    players[player.index].data.text_input = text_input
    players[player.index].data.slider = slider
    players[player.index].data.frame = frame
    players[player.index].data.item_frame = pane
    players[player.index].data.coins_left = coinsleft

    redraw_market_items(pane, player, search_text)
end

local function gui_click(event)
    local players = WPT.get('players')

    local element = event.element
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    if not players[player.index] then
        return
    end

    local data = players[player.index].data
    if not data then
        return
    end

    if not element.valid then
        return
    end
    local name = element.name

    if not player.opened then
        return
    end

    if not player.opened == main_frame_name then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, nil, 'Locomotive Gui Clicked')
    if is_spamming then
        return
    end

    if not data then
        return
    end
    local item = Public.get_items()[name]
    if not item then
        return
    end

    local inventory = player.get_main_inventory()
    local player_item_count = inventory.get_item_count(item.value)
    local slider_value = ceil(data.slider.slider_value)
    local cost = (item.price * slider_value)
    local item_count = item.stack * slider_value

    local this = WPT.get()
    if name == 'upgrade_pickaxe' then
        player.remove_item({name = item.value, count = item.price})

        this.pickaxe_tier = this.pickaxe_tier + item.stack

        local pickaxe_tiers = WPT.pickaxe_upgrades
        local tier = this.pickaxe_tier
        local offer = pickaxe_tiers[tier]

        local message = ({
            'locomotive.pickaxe_bought_info',
            shopkeeper,
            player.name,
            offer,
            format_number(item.price, true)
        })
        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has upgraded the teams pickaxe to tier ' .. tier .. ' for ' .. format_number(item.price, true) .. ' coins.'
            }
        )

        local force = game.forces.player

        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + this.pickaxe_speed_per_purchase

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'chest_limit_outside' then
        if this.chest_limit_outside_upgrades == 8 then
            local main_market_items = WPT.get('main_market_items')

            main_market_items['chest_limit_outside'].enabled = false
            main_market_items['chest_limit_outside'].tooltip = ({'locomotive.limit_reached'})
            redraw_market_items(data.item_frame, player, data.search_text)
            return player.print(({'locomotive.chests_full'}), {r = 0.98, g = 0.66, b = 0.22})
        end
        player.remove_item({name = item.value, count = item.price})

        local message = ({'locomotive.chest_bought_info', shopkeeper, player.name, format_number(item.price, true)})
        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has bought the chest limit upgrade for ' .. format_number(item.price, true) .. ' coins.'
            }
        )
        this.chest_limit_outside_upgrades = this.chest_limit_outside_upgrades + item.stack

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'locomotive_max_health' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({'locomotive.health_bought_info', shopkeeper, player.name, format_number(item.price, true)})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has bought the locomotive health modifier for ' .. format_number(item.price, true) .. ' coins.'
            }
        )
        this.locomotive_max_health = this.locomotive_max_health + 4000 * item.stack
        local m = this.locomotive_health / this.locomotive_max_health

        if this.carriages then
            for i = 1, #this.carriages do
                local entity = this.carriages[i]
                if not (entity and entity.valid) then
                    return
                end
                local cargo_health = 600
                local modded = is_game_modded()
                if modded then
                    cargo_health = 750
                end
                if entity.type == 'locomotive' then
                    entity.health = 1000 * m
                else
                    entity.health = cargo_health * m
                end
            end
        end

        this.train_upgrades = this.train_upgrades + item.stack
        this.health_upgrades = this.health_upgrades + item.stack
        rendering.set_text(this.health_text, 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health)

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'locomotive_xp_aura' then
        player.remove_item({name = item.value, count = item.price})

        local message = ({'locomotive.aura_bought_info', shopkeeper, player.name, format_number(item.price, true)})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has bought the locomotive xp aura modifier for ' .. format_number(item.price, true) .. ' coins.'
            }
        )
        this.locomotive_xp_aura = this.locomotive_xp_aura + 5
        this.aura_upgrades = this.aura_upgrades + item.stack
        this.train_upgrades = this.train_upgrades + item.stack

        if this.circle then
            rendering.destroy(this.circle)
        end
        this.circle =
            rendering.draw_circle {
            surface = game.surfaces[this.active_surface_index],
            target = this.locomotive,
            color = this.locomotive.color,
            filled = false,
            radius = this.locomotive_xp_aura,
            only_in_alt_mode = true
        }

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'xp_points_boost' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({'locomotive.xp_bought_info', shopkeeper, player.name, format_number(item.price, true)})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has bought the XP points modifier for ' .. format_number(item.price) .. ' coins.'
            }
        )
        this.xp_points = this.xp_points + 0.5
        this.xp_points_upgrade = this.xp_points_upgrade + item.stack
        this.train_upgrades = this.train_upgrades + item.stack

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'explosive_bullets' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({
            'locomotive.explosive_bullet_bought_info',
            shopkeeper,
            player.name,
            format_number(item.price, true)
        })

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has bought the explosive bullet modifier for ' .. format_number(item.price) .. ' coins.'
            }
        )
        this.explosive_bullets = true

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'flamethrower_turrets' then
        player.remove_item({name = item.value, count = item.price})
        if item.stack >= 1 then
            local message = ({
                'locomotive.one_flamethrower_bought_info',
                shopkeeper,
                player.name,
                format_number(item.price, true)
            })
            Alert.alert_all_players(5, message)
            Server.to_discord_bold(
                table.concat {
                    player.name .. ' has bought a flamethrower-turret slot for ' .. format_number(item.price, true) .. ' coins.'
                }
            )
        else
            local message = ({
                'locomotive.multiple_flamethrower_bought_info',
                shopkeeper,
                player.name,
                item.stack,
                format_number(item.price, true)
            })
            Alert.alert_all_players(5, message)
            Server.to_discord_bold(
                table.concat {
                    player.name .. ' has bought ' .. item.stack .. ' flamethrower-turret slots for ' .. format_number(item.price, true) .. ' coins.'
                }
            )
        end
        this.upgrades.flame_turret.limit = this.upgrades.flame_turret.limit + item.stack
        this.upgrades.flame_turret.bought = this.upgrades.flame_turret.bought + item.stack

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'land_mine' then
        player.remove_item({name = item.value, count = item.price})

        if item.stack >= 1 and this.upgrades.landmine.bought % 10 == 0 then
            local message = ({
                'locomotive.landmine_bought_info',
                shopkeeper,
                player.name,
                format_number(item.price, true)
            })

            Alert.alert_all_players(3, message)

            if item.price >= 1000 then
                Server.to_discord_bold(
                    table.concat {
                        player.name .. ' has bought ' .. item.stack .. ' landmine slots for ' .. format_number(item.price, true) .. ' coins.'
                    }
                )
            end
        end

        this.upgrades.landmine.limit = this.upgrades.landmine.limit + item.stack
        this.upgrades.landmine.bought = this.upgrades.landmine.bought + item.stack

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)
        return
    end

    if player_item_count >= cost then
        if player.can_insert({name = name, count = item_count}) then
            player.play_sound({path = 'entity-close/stone-furnace', volume_modifier = 0.65})
            local inserted_count = player.insert({name = name, count = item_count})
            if inserted_count < item_count then
                player.play_sound({path = 'utility/cannot_build', volume_modifier = 0.65})
                player.print(({'locomotive.full_inventory', inserted_count, name}), {r = 0.98, g = 0.66, b = 0.22})
                player.print(({'locomotive.change_returned'}), {r = 0.98, g = 0.66, b = 0.22})
                player.insert({name = name, count = inserted_count})
                player.remove_item({name = item.value, count = ceil(item.price * (inserted_count / item.stack))})
            else
                player.remove_item({name = item.value, count = cost})
            end
            redraw_market_items(data.item_frame, player, data.search_text)
            redraw_coins_left(data.coins_left, player)
        else
            player.play_sound({path = 'utility/cannot_build', volume_modifier = 0.65})
            if (random(1, 10) > 1) then
                player.print(({'locomotive.notify_full_inventory_1'}), {r = 0.98, g = 0.66, b = 0.22})
                player.print(({'locomotive.notify_full_inventory_2'}), {r = 0.98, g = 0.66, b = 0.22})
            else
                player.print(({'locomotive.notify_full_inventory_2'}), {r = 0.98, g = 0.66, b = 0.22})
            end
        end
    end
end

local function gui_closed(event)
    local player = game.players[event.player_index]
    local players = WPT.get('players')

    local type = event.gui_type

    if type == defines.gui_type.custom then
        local data = players[player.index].data
        if not data then
            return
        end
        close_market_gui(player)
    end
end

local function on_player_changed_position(event)
    local players = WPT.get('players')
    local player = game.players[event.player_index]
    if not players[player.index] then
        return
    end
    local data = players[player.index].data

    local market = WPT.get('market')

    if not (market and market.valid) then
        return
    end

    if data and data.frame and data.frame.valid then
        local position = market.position
        local area = {
            left_top = {x = position.x - 10, y = position.y - 10},
            right_bottom = {x = position.x + 10, y = position.y + 10}
        }
        if Math2D.bounding_box.contains_point(area, player.position) then
            return
        end
        if not data then
            return
        end
        close_market_gui(player)
    end
end

local function spawn_biter()
    local this = WPT.get()
    local loco_surface = this.icw_locomotive.surface

    if not loco_surface.valid then
        return
    end

    local locomotive = this.icw_locomotive

    local center_position = {
        x = locomotive.area.left_top.x + (locomotive.area.right_bottom.x - locomotive.area.left_top.x) * 0.5,
        y = locomotive.area.left_top.y + (locomotive.area.right_bottom.y - locomotive.area.left_top.y) * 0.5
    }

    if not this.icw_area then
        this.icw_area = center_position
    end

    local position = loco_surface.find_non_colliding_position('market', center_position, 128, 0.5)
    local biters = {
        'big-biter',
        'behemoth-biter',
        'big-spitter',
        'behemoth-spitter'
    }
    if is_mod_loaded('bobenemies') then
        biters = {'bob-leviathan-biter', 'bob-behemoth-biter', 'bob-huge-explosive-spitter'}
    end

    local size_of = #biters

    if not position then
        return
    end
    this.locomotive_biter = loco_surface.create_entity({name = biters[random(1, size_of)], position = position, force = 'player', create_build_effect_smoke = false})
    this.locomotive_biter.ai_settings.allow_destroy_when_commands_fail = false
    this.locomotive_biter.ai_settings.allow_try_return_to_spawner = false

    rendering.draw_text {
        text = ({'locomotive.shoo'}),
        surface = this.locomotive_biter.surface,
        target = this.locomotive_biter,
        target_offset = {0, -3.5},
        scale = 1.05,
        font = 'default-large-semibold',
        color = {r = 175, g = 75, b = 255},
        alignment = 'center',
        scale_with_zoom = false
    }
end

local function create_market(data, rebuild)
    local surface = data.surface
    local this = data.this

    if not this.locomotive then
        return
    end

    if not this.locomotive.valid then
        return
    end

    if rebuild then
        local radius = 512
        local area = {{x = -radius, y = -radius}, {x = radius, y = radius}}
        for _, entity in pairs(surface.find_entities_filtered {area = area, name = 'market'}) do
            entity.destroy()
        end
        for _, entity in pairs(surface.find_entities_filtered {area = area, type = 'item-entity', name = 'item-on-ground'}) do
            entity.destroy()
        end
        for _, entity in pairs(surface.find_entities_filtered {area = area, type = 'unit'}) do
            entity.destroy()
        end
        this.market = nil
    end

    local locomotive = this.icw_locomotive

    local loco_surface = this.icw_locomotive.surface

    if not loco_surface.valid then
        return
    end

    local center_position = {
        x = locomotive.area.left_top.x + (locomotive.area.right_bottom.x - locomotive.area.left_top.x) * 0.5,
        y = locomotive.area.left_top.y + (locomotive.area.right_bottom.y - locomotive.area.left_top.y) * 0.5
    }

    if not this.icw_area then
        this.icw_area = center_position
    end

    this.market = surface.create_entity {name = 'market', position = center_position, force = 'player'}

    Generate.wintery(this.market, 5.5)

    rendering.draw_text {
        text = 'Market',
        surface = surface,
        target = this.market,
        scale = 1.5,
        target_offset = {0, -2},
        color = {r = 0.98, g = 0.66, b = 0.22},
        alignment = 'center'
    }

    this.market.destructible = false

    spawn_biter()

    for x = center_position.x - 5, center_position.x + 5, 1 do
        for y = center_position.y - 5, center_position.y + 5, 1 do
            if random(1, 2) == 1 then
                loco_surface.spill_item_stack({x + random(0, 9) * 0.1, y + random(0, 9) * 0.1}, {name = 'raw-fish', count = 1}, false)
            end
            loco_surface.set_tiles({{name = 'blue-refined-concrete', position = {x, y}}}, true)
        end
    end
    for x = center_position.x - 3, center_position.x + 3, 1 do
        for y = center_position.y - 3, center_position.y + 3, 1 do
            if random(1, 2) == 1 then
                loco_surface.spill_item_stack({x + random(0, 9) * 0.1, y + random(0, 9) * 0.1}, {name = 'raw-fish', count = 1}, false)
            end
            loco_surface.set_tiles({{name = 'cyan-refined-concrete', position = {x, y}}}, true)
        end
    end
end

local function contains_positions(area)
    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    local wagons = ICW.get_table('wagons')
    for _, wagon in pairs(wagons) do
        if wagon.entity and wagon.entity.valid then
            if wagon.entity.name == 'cargo-wagon' then
                if inside(wagon.entity.position, area) then
                    return true, wagon.entity
                end
            end
        end
    end
    return false, nil
end

local function on_built_entity(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    if entity.name ~= 'steel-chest' then
        return
    end

    local map_name = 'mountain_fortress_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local area = {
        left_top = {x = entity.position.x - 3, y = entity.position.y - 3},
        right_bottom = {x = entity.position.x + 3, y = entity.position.y + 3}
    }

    local success, train = contains_positions(area)

    if not success then
        return
    end

    local outside_chests = WPT.get('outside_chests')
    local chests_linked_to = WPT.get('chests_linked_to')
    local chest_limit_outside_upgrades = WPT.get('chest_limit_outside_upgrades')
    local chest_created
    local increased = false

    for k, data in pairs(outside_chests) do
        if data and data.chest and data.chest.valid then
            if chests_linked_to[train.unit_number] then
                local linked_to = chests_linked_to[train.unit_number].count
                if linked_to == chest_limit_outside_upgrades then
                    return
                end
                outside_chests[entity.unit_number] = {chest = entity, position = entity.position, linked = train.unit_number}

                if not increased then
                    chests_linked_to[train.unit_number].count = linked_to + 1
                    chests_linked_to[train.unit_number][entity.unit_number] = true
                    increased = true

                    goto continue
                end
            else
                outside_chests[entity.unit_number] = {chest = entity, position = entity.position, linked = train.unit_number}
                chests_linked_to[train.unit_number] = {count = 1}
            end

            ::continue::
            rendering.draw_text {
                text = '♠',
                surface = entity.surface,
                target = entity,
                target_offset = {0, -0.6},
                scale = 2,
                color = {r = 0, g = 0.6, b = 1},
                alignment = 'center'
            }
            chest_created = true
        end
    end

    if chest_created then
        return
    end

    if next(outside_chests) == nil then
        outside_chests[entity.unit_number] = {chest = entity, position = entity.position, linked = train.unit_number}
        chests_linked_to[train.unit_number] = {count = 1}
        chests_linked_to[train.unit_number][entity.unit_number] = true

        rendering.draw_text {
            text = '♠',
            surface = entity.surface,
            target = entity,
            target_offset = {0, -0.6},
            scale = 2,
            color = {r = 0, g = 0.6, b = 1},
            alignment = 'center'
        }
        return
    end
end

local function on_player_and_robot_mined_entity(event)
    local entity = event.entity

    if not entity.valid then
        return
    end

    local outside_chests = WPT.get('outside_chests')
    local chests_linked_to = WPT.get('chests_linked_to')

    if outside_chests[entity.unit_number] then
        for k, data in pairs(chests_linked_to) do
            if data[entity.unit_number] then
                data.count = data.count - 1
                if data.count <= 0 then
                    chests_linked_to[k] = nil
                end
            end
            if chests_linked_to[k] and chests_linked_to[k][entity.unit_number] then
                chests_linked_to[k][entity.unit_number] = nil
            end
        end
        outside_chests[entity.unit_number] = nil
    end
end

local function divide_contents()
    local outside_chests = WPT.get('outside_chests')
    local chests_linked_to = WPT.get('chests_linked_to')
    local target_chest

    if not next(outside_chests) then
        goto final
    end

    for key, data in pairs(outside_chests) do
        local chest = data.chest
        local area = {
            left_top = {x = data.position.x - 4, y = data.position.y - 4},
            right_bottom = {x = data.position.x + 4, y = data.position.y + 4}
        }
        if not (chest and chest.valid) then
            if chests_linked_to[data.linked] then
                if chests_linked_to[data.linked][key] then
                    chests_linked_to[data.linked][key] = nil
                    chests_linked_to[data.linked].count = chests_linked_to[data.linked].count - 1
                    if chests_linked_to[data.linked].count <= 0 then
                        chests_linked_to[data.linked] = nil
                    end
                end
            end
            outside_chests[key] = nil
            goto continue
        end

        local success, entity = contains_positions(area)
        if success then
            target_chest = entity
        else
            if chests_linked_to[data.linked] then
                if chests_linked_to[data.linked][key] then
                    chests_linked_to[data.linked][key] = nil
                    chests_linked_to[data.linked].count = chests_linked_to[data.linked].count - 1
                    if chests_linked_to[data.linked].count <= 0 then
                        chests_linked_to[data.linked] = nil
                    end
                end
            end
            goto continue
        end

        local chest1 = chest.get_inventory(defines.inventory.chest)
        local chest2 = target_chest.get_inventory(defines.inventory.cargo_wagon)

        for item, count in pairs(chest1.get_contents()) do
            local t = {name = item, count = count}
            local c = chest2.insert(t)
            if (c > 0) then
                chest1.remove({name = item, count = c})
            end
        end
        ::continue::
    end
    ::final::
end

local function place_market()
    local this = WPT.get()
    local icw_table = ICW.get_table()
    if not this.locomotive then
        return
    end

    if not this.locomotive.valid then
        return
    end

    local unit_surface = this.locomotive.unit_number
    local surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

    local data = {
        this = this,
        surface = surface
    }
    if not this.market then
        create_market(data)
    elseif not this.market.valid then
        create_market(data, true)
    end
end

local function on_research_finished()
    local market_announce = WPT.get('market_announce')
    if market_announce > game.tick then
        return
    end

    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local breached_wall = WPT.get('breached_wall')
    add_random_loot_to_main_market(breached_wall)
    local message = ({'locomotive.new_items_at_market'})
    Alert.alert_all_players(5, message, nil, 'achievement/tech-maniac', 0.1)
    Public.refresh_gui()
end

local function shoo(event)
    local icw_locomotive = WPT.get('icw_locomotive')
    local loco_surface = icw_locomotive.surface

    if not loco_surface.valid then
        return
    end

    local player = game.players[event.player_index]

    if player and player.valid then
        if player.surface.index ~= loco_surface.index then
            return
        end
    end

    local locomotive_biter = WPT.get('locomotive_biter')
    local surface = player.surface
    local message = event.message
    message = string.lower(message)
    for word in string.gmatch(message, '%g+') do
        if word == 'shoo' then
            if not locomotive_biter or not locomotive_biter.valid then
                spawn_biter()
                return
            end
            surface.create_entity(
                {
                    name = 'rocket',
                    position = locomotive_biter.position,
                    force = 'enemy',
                    speed = 1,
                    max_range = 1200,
                    target = locomotive_biter,
                    source = locomotive_biter
                }
            )
            if locomotive_biter and locomotive_biter.valid then
                locomotive_biter.die()
                WPT.set().locomotive_biter = nil
            end
            return
        end
    end
end

local function on_console_chat(event)
    if not event.player_index then
        return
    end
    shoo(event)
end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local map_name = 'mountain_fortress_v3'

    if player.surface.name == 'nauvis' then
        local active_surface = WPT.get('active_surface_index')
        local surface = game.surfaces[active_surface]
        if not surface or not surface.valid then
            return
        end
        player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
    end

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return Public.add_player_to_permission_group(player, 'locomotive')
    else
        return Public.add_player_to_permission_group(player, 'plebs')
    end
end

local function on_player_driving_changed_state(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local trusted = Session.get_trusted_table()
    if #trusted == 0 then
        return
    end

    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    if entity.unit_number == locomotive.unit_number then
        if not trusted[player.name] then
            if player.character and player.character.valid and player.character.driving then
                player.character.driving = false
            end
        end
    end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local trusted = Session.get_trusted_table()
    if trusted[player.name] then
        trusted[player.name] = nil
    end
end

function Public.close_gui_player(frame)
    if not frame then
        return
    end

    if frame then
        frame.destroy()
    end
end

function Public.refresh_gui()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]

        local gui = player.gui
        local screen = gui.screen

        local player_data = WPT.get('players')
        local data = player_data[player.index].data

        if screen and data and data.frame then
            redraw_market_items(data.item_frame, player, data.search_text)
        end
    end
end

function Public.boost_players_around_train()
    local rpg = RPG_Settings.get('rpg_t')
    local active_surface_index = WPT.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local locomotive = WPT.get('locomotive')
    if not (locomotive and locomotive.valid) then
        return
    end
    local surface = game.surfaces[active_surface_index]
    local icw_table = ICW.get_table()
    local unit_surface = locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

    local data = {
        surface = surface,
        locomotive_surface = locomotive_surface,
        rpg = rpg
    }
    property_boost(data)
end

function Public.is_around_train(entity)
    local locomotive = WPT.get('locomotive')
    local active_surface_index = WPT.get('active_surface_index')

    if not active_surface_index then
        return false
    end
    if not locomotive then
        return false
    end
    if not locomotive.valid then
        return false
    end

    if not entity or not entity.valid then
        return false
    end

    local surface = game.surfaces[active_surface_index]
    local aura = WPT.get('locomotive_xp_aura')

    local data = {
        locomotive = locomotive,
        surface = surface,
        entity = entity,
        aura = aura
    }

    local success = is_around_train(data)
    return success
end

function Public.render_train_hp()
    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]

    local locomotive_health = WPT.get('locomotive_health')
    local locomotive_max_health = WPT.get('locomotive_max_health')
    local locomotive = WPT.get('locomotive')
    local locomotive_xp_aura = WPT.get('locomotive_xp_aura')

    WPT.set().health_text =
        rendering.draw_text {
        text = 'HP: ' .. locomotive_health .. ' / ' .. locomotive_max_health,
        surface = surface,
        target = locomotive,
        target_offset = {0, -4.5},
        color = locomotive.color,
        scale = 1.40,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    WPT.set().caption =
        rendering.draw_text {
        text = 'Comfy Choo Choo',
        surface = surface,
        target = locomotive,
        target_offset = {0, -6.25},
        color = locomotive.color,
        scale = 1.80,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    WPT.set().circle =
        rendering.draw_circle {
        surface = surface,
        target = locomotive,
        color = locomotive.color,
        filled = false,
        radius = locomotive_xp_aura,
        only_in_alt_mode = true
    }
end

function Public.locomotive_spawn(surface, position)
    local this = WPT.get()
    for y = -6, 6, 2 do
        surface.create_entity({name = 'straight-rail', position = {position.x, position.y + y}, force = 'player', direction = 0})
    end
    this.locomotive = surface.create_entity({name = 'locomotive', position = {position.x, position.y + -3}, force = 'player'})
    this.locomotive.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 100})

    this.locomotive_cargo = surface.create_entity({name = 'cargo-wagon', position = {position.x, position.y + 3}, force = 'player'})
    this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = 'raw-fish', count = 8})

    local winter_mode_locomotive = Generate.wintery(this.locomotive, 5.5)
    if not winter_mode_locomotive then
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 5.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = {255, 255, 255},
                target = this.locomotive,
                surface = surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
    end

    local winter_mode_cargo = Generate.wintery(this.locomotive_cargo, 5.5)

    if not winter_mode_cargo then
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 5.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = {255, 255, 255},
                target = this.locomotive_cargo,
                surface = surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
    end

    local data = {
        surface = surface,
        position = position
    }

    Task.set_timeout_in_ticks(300, set_loco_tiles, data)

    for y = -1, 0, 0.05 do
        local scale = random(50, 100) * 0.01
        rendering.draw_sprite(
            {
                sprite = 'item/raw-fish',
                orientation = random(0, 100) * 0.01,
                x_scale = scale,
                y_scale = scale,
                tint = {random(60, 255), random(60, 255), random(60, 255)},
                render_layer = 'selection-box',
                target = this.locomotive_cargo,
                target_offset = {-0.7 + random(0, 140) * 0.01, y},
                surface = surface
            }
        )
    end

    this.locomotive.color = {0, 255, random(60, 255)}
    this.locomotive.minable = false
    this.locomotive_cargo.minable = false
    this.locomotive_cargo.operable = true

    local locomotive = ICW.register_wagon(this.locomotive)
    ICW.register_wagon(this.locomotive_cargo)

    this.icw_locomotive = locomotive

    game.forces.player.set_spawn_position({0, 19}, locomotive.surface)
end

function Public.get_items()
    local chest_limit_outside_upgrades = WPT.get('chest_limit_outside_upgrades')
    local health_upgrades = WPT.get('health_upgrades')
    local pickaxe_tier = WPT.get('pickaxe_tier')
    local aura_upgrades = WPT.get('aura_upgrades')
    local main_market_items = WPT.get('main_market_items')
    local xp_points_upgrade = WPT.get('xp_points_upgrade')
    local flame_turret = WPT.get('upgrades').flame_turret.bought
    local landmine = WPT.get('upgrades').landmine.bought
    local fixed_prices = WPT.get('marked_fixed_prices')

    local chest_limit_cost = round(fixed_prices.chest_limit_cost * (1 + chest_limit_outside_upgrades))
    local health_cost = round(fixed_prices.health_cost * (1 + health_upgrades))
    local pickaxe_cost = round(fixed_prices.pickaxe_cost * (0.1 + pickaxe_tier / 2))
    local aura_cost = round(fixed_prices.aura_cost * (1 + aura_upgrades))
    local xp_point_boost_cost = round(fixed_prices.xp_point_boost_cost * (1 + xp_points_upgrade))
    local explosive_bullets_cost = round(fixed_prices.explosive_bullets_cost)
    local flamethrower_turrets_cost = round(fixed_prices.flamethrower_turrets_cost * (1 + flame_turret))
    local land_mine_cost = round(fixed_prices.land_mine_cost * (1 + landmine))

    local pickaxe_tiers = WPT.pickaxe_upgrades
    local tier = WPT.get('pickaxe_tier')
    local offer = pickaxe_tiers[tier]

    if pickaxe_tier >= 59 then
        main_market_items['upgrade_pickaxe'] = {
            stack = 1,
            value = 'coin',
            price = pickaxe_cost,
            tooltip = ({'main_market.sold_out'}),
            sprite = 'achievement/delivery-service',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['upgrade_pickaxe'] = {
            stack = 1,
            value = 'coin',
            price = pickaxe_cost,
            tooltip = ({'main_market.purchase_pickaxe', offer}),
            sprite = 'achievement/delivery-service',
            enabled = true,
            upgrade = true,
            static = true
        }
    end
    if main_market_items['chest_limit_outside'] then
        main_market_items['chest_limit_outside'] = {
            stack = 1,
            value = 'coin',
            price = chest_limit_cost,
            tooltip = main_market_items['chest_limit_outside'].tooltip,
            sprite = 'achievement/so-long-and-thanks-for-all-the-fish',
            enabled = main_market_items['chest_limit_outside'].enabled,
            upgrade = true,
            static = true
        }
    else
        main_market_items['chest_limit_outside'] = {
            stack = 1,
            value = 'coin',
            price = chest_limit_cost,
            tooltip = ({'main_market.chest'}),
            sprite = 'achievement/so-long-and-thanks-for-all-the-fish',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    main_market_items['locomotive_max_health'] = {
        stack = 1,
        value = 'coin',
        price = health_cost,
        tooltip = ({'main_market.locomotive_max_health'}),
        sprite = 'achievement/getting-on-track',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['locomotive_xp_aura'] = {
        stack = 1,
        value = 'coin',
        price = aura_cost,
        tooltip = ({'main_market.locomotive_xp_aura'}),
        sprite = 'achievement/tech-maniac',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['xp_points_boost'] = {
        stack = 1,
        value = 'coin',
        price = xp_point_boost_cost,
        tooltip = ({'main_market.xp_points_boost'}),
        sprite = 'achievement/trans-factorio-express',
        enabled = true,
        upgrade = true,
        static = true
    }
    if WPT.get('explosive_bullets') then
        main_market_items['explosive_bullets'] = {
            stack = 1,
            value = 'coin',
            price = explosive_bullets_cost,
            tooltip = ({'main_market.sold_out'}),
            sprite = 'achievement/steamrolled',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['explosive_bullets'] = {
            stack = 1,
            value = 'coin',
            price = explosive_bullets_cost,
            tooltip = ({'main_market.explosive_bullets'}),
            sprite = 'achievement/steamrolled',
            enabled = true,
            upgrade = true,
            static = true
        }
    end
    main_market_items['flamethrower_turrets'] = {
        stack = 1,
        value = 'coin',
        price = flamethrower_turrets_cost,
        tooltip = ({'main_market.flamethrower_turret'}),
        sprite = 'achievement/pyromaniac',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['land_mine'] = {
        stack = 1,
        value = 'coin',
        price = land_mine_cost,
        tooltip = ({'main_market.land_mine'}),
        sprite = 'achievement/watch-your-step',
        enabled = true,
        upgrade = true,
        static = true
    }

    if game.forces.player.technologies['logistics'].researched then
        if is_mod_loaded('Krastorio2') then
            main_market_items['kr-loader'] = {
                stack = 1,
                value = 'coin',
                price = 128,
                tooltip = ({'entity-name.kr-loader'}),
                upgrade = false,
                static = true
            }
        else
            main_market_items['loader'] = {
                stack = 1,
                value = 'coin',
                price = 128,
                tooltip = ({'entity-name.loader'}),
                upgrade = false,
                static = true
            }
        end
    end
    if game.forces.player.technologies['logistics-2'].researched then
        if is_mod_loaded('Krastorio2') then
            main_market_items['kr-fast-loader'] = {
                stack = 1,
                value = 'coin',
                price = 256,
                tooltip = ({'entity-name.kr-fast-loader'}),
                upgrade = false,
                static = true
            }
        else
            main_market_items['fast-loader'] = {
                stack = 1,
                value = 'coin',
                price = 256,
                tooltip = ({'entity-name.fast-loader'}),
                upgrade = false,
                static = true
            }
        end
    end
    if game.forces.player.technologies['logistics-3'].researched then
        if is_mod_loaded('Krastorio2') then
            main_market_items['kr-express-loader'] = {
                stack = 1,
                value = 'coin',
                price = 512,
                tooltip = ({'entity-name.kr-express-loader'}),
                upgrade = false,
                static = true
            }
        else
            main_market_items['express-loader'] = {
                stack = 1,
                value = 'coin',
                price = 512,
                tooltip = ({'entity-name.express-loader'}),
                upgrade = false,
                static = true
            }
        end
    end
    main_market_items['small-lamp'] = {
        stack = 1,
        value = 'coin',
        price = 5,
        tooltip = ({'entity-name.small-lamp'}),
        upgrade = false,
        static = false
    }
    main_market_items['wood'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.wood'}),
        upgrade = false,
        static = false
    }
    main_market_items['iron-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.iron-ore'}),
        upgrade = false,
        static = false
    }
    main_market_items['copper-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.copper-ore'}),
        upgrade = false,
        static = false
    }
    main_market_items['stone'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.stone'}),
        upgrade = false,
        static = false
    }
    main_market_items['coal'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.coal'}),
        upgrade = false,
        static = false
    }
    main_market_items['uranium-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.uranium-ore'}),
        upgrade = false,
        static = false
    }
    if is_mod_loaded('Factorio-Tiberium') then
        main_market_items['tiberium-ore'] = {
            stack = 25,
            value = 'coin',
            price = 15,
            tooltip = ({'item-name.tiberium-ore'}),
            upgrade = false,
            static = false
        }
    end
    if is_mod_loaded('Krastorio2') then
        main_market_items['first-aid-kit'] = {
            stack = 1,
            value = 'coin',
            price = 20,
            tooltip = ({'item-name.first-aid-kit'}),
            upgrade = false,
            static = false
        }
    end
    main_market_items['land-mine'] = {
        stack = 1,
        value = 'coin',
        price = 10,
        tooltip = ({'entity-name.land-mine'}),
        upgrade = false,
        static = false
    }
    main_market_items['raw-fish'] = {
        stack = 1,
        value = 'coin',
        price = 4,
        tooltip = ({'item-name.raw-fish'}),
        upgrade = false,
        static = false
    }
    main_market_items['firearm-magazine'] = {
        stack = 1,
        value = 'coin',
        price = 5,
        tooltip = ({'item-name.firearm-magazine'}),
        upgrade = false,
        static = false
    }
    main_market_items['crude-oil-barrel'] = {
        stack = 1,
        value = 'coin',
        price = 8,
        tooltip = ({'item-name.crude-oil-barrel'}),
        upgrade = false,
        static = false
    }
    main_market_items['car'] = {
        stack = 1,
        value = 'coin',
        price = 6000,
        tooltip = ({'main_market.car'}),
        upgrade = false,
        static = true
    }
    main_market_items['tank'] = {
        stack = 1,
        value = 'coin',
        price = 12000,
        tooltip = ({'main_market.tank'}),
        upgrade = false,
        static = true
    }
    if is_mod_loaded('Krastorio2') then
        main_market_items['kr-advanced-tank'] = {
            stack = 1,
            value = 'coin',
            price = 20000,
            tooltip = ({'main_market.tank'}),
            upgrade = false,
            static = true
        }
    end
    local wave_number = WD.get_wave()

    if wave_number >= 650 then
        main_market_items['tank-cannon'] = {
            stack = 1,
            value = 'coin',
            price = 25000,
            tooltip = ({'item-name.tank-cannon'}),
            upgrade = false,
            static = true,
            enabled = true
        }
    else
        main_market_items['tank-cannon'] = {
            stack = 1,
            value = 'coin',
            price = 25000,
            tooltip = ({'main_market.tank_cannon_na', 650}),
            upgrade = false,
            static = true,
            enabled = false
        }
    end
    if wave_number >= 100 then
        main_market_items['vehicle-machine-gun'] = {
            stack = 1,
            value = 'coin',
            price = 2000,
            tooltip = ({'item-name.vehicle-machine-gun'}),
            upgrade = false,
            static = true,
            enabled = true
        }
    else
        main_market_items['vehicle-machine-gun'] = {
            stack = 1,
            value = 'coin',
            price = 2000,
            tooltip = ({'main_market.vehicle_machine_gun_na', 100}),
            upgrade = false,
            static = true,
            enabled = false
        }
    end

    return main_market_items
end

function Public.transfer_pollution()
    local locomotive = WPT.get('locomotive')
    local active_surface_index = WPT.get('active_surface_index')
    local icw_locomotive = WPT.get('icw_locomotive')
    local surface = icw_locomotive.surface
    if not surface or not surface.valid then
        return
    end
    local active_surface = game.surfaces[active_surface_index]
    if not active_surface or not active_surface.valid then
        return
    end

    if not locomotive or not locomotive.valid then
        return
    end

    local total_interior_pollution = surface.get_total_pollution()

    local pollution = surface.get_total_pollution() * (3 / (4 / 3 + 1)) * Difficulty.get().difficulty_vote_value
    active_surface.pollute(locomotive.position, pollution)
    game.pollution_statistics.on_flow('locomotive', pollution - total_interior_pollution)
    surface.clear_pollution()
end

function Public.enable_poison_defense(pos)
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end
    pos = pos or locomotive.position
    create_defense_system({x = pos.x, y = pos.y}, 'poison-cloud', pos)
    if random(1, 4) == 1 then
        local random_angles = {rad(random(344))}
        create_defense_system({x = pos.x + 24 * cos(random_angles[1]), y = pos.y + -24 * sin(random_angles[1])}, 'poison-cloud', pos)
    end
end

function Public.enable_robotic_defense(pos)
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end
    pos = pos or locomotive.position
    create_defense_system({x = pos.x, y = pos.y}, 'destroyer-capsule', pos)
    if random(1, 4) == 1 then
        local random_angles = {rad(random(324))}
        create_defense_system({x = pos.x + 24 * cos(random_angles[1]), y = pos.y + -24 * sin(random_angles[1])}, 'destroyer-capsule', pos)
    end
end

local boost_players = Public.boost_players_around_train
local pollute_area = Public.transfer_pollution

local function tick()
    local ticker = game.tick

    if ticker % 30 == 0 then
        set_locomotive_health()
        place_market()
        validate_index()
        fish_tag()
        divide_contents()
    end

    if ticker % 120 == 0 then
        -- tp_player()
        boost_players()
    end

    if ticker % 1200 == 0 then
        set_player_spawn()
        refill_fish()
    end

    if ticker % 2500 == 0 then
        pollute_area()
    end
end

Public.place_market = place_market

Event.on_nth_tick(5, tick)
Event.add(defines.events.on_gui_click, gui_click)
Event.add(defines.events.on_gui_opened, gui_opened)
Event.add(defines.events.on_gui_value_changed, slider_changed)
Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(defines.events.on_gui_closed, gui_closed)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_player_and_robot_mined_entity)
Event.add(defines.events.on_pre_player_mined_item, on_player_and_robot_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_player_and_robot_mined_entity)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_player_left_game, on_player_left_game)

return Public
