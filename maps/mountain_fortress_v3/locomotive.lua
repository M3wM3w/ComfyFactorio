local Event = require 'utils.event'
--local Power = require 'maps.mountain_fortress_v3.power'
local Market = require 'maps.mountain_fortress_v3.basic_markets'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WPT = require 'maps.mountain_fortress_v3.table'
local Difficulty = require 'modules.difficulty_vote'
local RPG = require 'maps.mountain_fortress_v3.rpg'
local Gui = require 'utils.gui'
local Server = require 'utils.server'
local Alert = require 'utils.alert'
local Math2D = require 'math2d'
local format_number = require 'util'.format_number

local Public = {}
local concat = table.concat
local main_frame_name = Gui.uid_name()

local shopkeeper = '[color=blue]Shopkeeper:[/color]\n'

local space = {
    minimal_height = 10,
    top_padding = 0,
    bottom_padding = 0
}

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

local function property_boost(data)
    local xp_floating_text_color = {r = 0, g = 127, b = 33}
    local visuals_delay = 1800
    local this = data.this
    local locomotive_surface = data.locomotive_surface
    local aura = this.locomotive_xp_aura
    local rpg = data.rpg
    local loco = this.locomotive.position
    local area = {
        left_top = {x = loco.x - aura, y = loco.y - aura},
        right_bottom = {x = loco.x + aura, y = loco.y + aura}
    }

    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            return
        end
        if player.afk_time < 200 then
            if
                Math2D.bounding_box.contains_point(area, player.position) or
                    player.surface.index == locomotive_surface.index
             then
                local pos = player.position
                RPG.gain_xp(player, 0.3 * (rpg[player.index].bonus + this.xp_points))

                player.create_local_flying_text {
                    text = '+' .. '',
                    position = {x = pos.x, y = pos.y - 2},
                    color = xp_floating_text_color,
                    time_to_live = 60,
                    speed = 3
                }
                rpg[player.index].xp_since_last_floaty_text = 0
                rpg[player.index].last_floaty_text = game.tick + visuals_delay
            end
        end
    end
end

local function is_around_train(data)
    local entity = data.entity
    local aura = 60
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
    local this = WPT.get()
    if not this.locomotive_cargo then
        return
    end
    if not this.locomotive_cargo.valid then
        return
    end
    if not this.locomotive_cargo.surface then
        return
    end
    if not this.locomotive_cargo.surface.valid then
        return
    end
    if this.locomotive_tag then
        if this.locomotive_tag.valid then
            if
                this.locomotive_tag.position.x == this.locomotive_cargo.position.x and
                    this.locomotive_tag.position.y == this.locomotive_cargo.position.y
             then
                return
            end
            this.locomotive_tag.destroy()
        end
    end
    this.locomotive_tag =
        this.locomotive_cargo.force.add_chart_tag(
        this.locomotive_cargo.surface,
        {
            icon = {type = 'item', name = 'raw-fish'},
            position = this.locomotive_cargo.position,
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
    locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = 'raw-fish', count = math.random(2, 5)})
end

local function set_locomotive_health()
    local this = WPT.get()
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end
    local locomotive_health = WPT.get('locomotive_health')
    local locomotive_max_health = WPT.get('locomotive_max_health')
    local m = locomotive_health / locomotive_max_health
    this.locomotive.health = 1000 * m
    rendering.set_text(this.health_text, 'HP: ' .. locomotive_health .. ' / ' .. locomotive_max_health)
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
    if not loco_surface.valid then
        WPT.get().loco_surface = locomotive_surface
    end
end

local function create_poison_cloud(position)
    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]

    local random_angles = {
        math.rad(math.random(359)),
        math.rad(math.random(359)),
        math.rad(math.random(359)),
        math.rad(math.random(359))
    }

    surface.create_entity({name = 'poison-cloud', position = {x = position.x, y = position.y}})
    surface.create_entity(
        {
            name = 'poison-cloud',
            position = {
                x = position.x + 12 * math.cos(random_angles[1]),
                y = position.y + 12 * math.sin(random_angles[1])
            }
        }
    )
    surface.create_entity(
        {
            name = 'poison-cloud',
            position = {
                x = position.x + 12 * math.cos(random_angles[2]),
                y = position.y + 12 * math.sin(random_angles[2])
            }
        }
    )
    surface.create_entity(
        {
            name = 'poison-cloud',
            position = {
                x = position.x + 12 * math.cos(random_angles[3]),
                y = position.y + 12 * math.sin(random_angles[3])
            }
        }
    )
    surface.create_entity(
        {
            name = 'poison-cloud',
            position = {
                x = position.x + 12 * math.cos(random_angles[4]),
                y = position.y + 12 * math.sin(random_angles[4])
            }
        }
    )
end

local function close_market_gui(player)
    local this = WPT.get()

    local element = player.gui.screen
    local data = this.players[player.index].data
    if not data then
        return
    end

    local frame = element[main_frame_name]
    Public.close_gui_player(frame)
    if data then
        this.players[player.index].data = nil
    end
end

local function redraw_market_items(gui, player, search_text)
    if not validate_player(player) then
        return
    end
    local players = WPT.get('players')

    gui.clear()

    local inventory = player.get_main_inventory()
    local player_item_count

    gui.add(
        {
            type = 'label',
            caption = 'Upgrades: '
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
            caption = 'Items: '
        }
    )

    local slider_value = math.ceil(players[player.index].data.slider.slider_value)
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
            caption = 'Coins left: ' .. format_number(player_item_count, true)
        }
    )

    add_space(coinsleft)
end

local function slider_changed(event)
    local player = game.players[event.player_index]
    local this = WPT.get()
    local slider_value

    slider_value = this.players
    if not slider_value then
        return
    end
    slider_value = slider_value[player.index].data
    if not slider_value then
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
    slider_value = math.ceil(slider_value)
    this.players[player.index].data.text_input.text = slider_value
    redraw_market_items(this.players[player.index].data.item_frame, player, this.players[player.index].data.search_text)
end

local function text_changed(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end

    local this = WPT.get()
    local player = game.players[event.player_index]

    local data = this.players[player.index].data
    if not data then
        return
    end
    if not data.text_input then
        return
    end

    if not data.text_input.text then
        return
    end

    local value = tonumber(data.text_input.text)

    if not value then
        return
    end

    redraw_market_items(data.item_frame, player, data.search_text)
end

local function gui_opened(event)
    local this = WPT.get()

    if not event.gui_type == defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity then
        return
    end

    if entity ~= this.market then
        return
    end

    local player = game.players[event.player_index]

    if not validate_player(player) then
        return
    end

    local inventory = player.get_main_inventory()
    local player_item_count = inventory.get_item_count('coin')

    if not this.players[player.index].data then
        this.players[player.index].data = {}
    end

    local data = this.players[player.index].data

    if data.frame then
        data.frame = nil
    end
    local frame =
        player.gui.screen.add(
        {
            type = 'frame',
            caption = 'Market',
            direction = 'vertical',
            name = main_frame_name
        }
    )

    frame.auto_center = true

    player.opened = frame
    frame.style.minimal_width = 325
    frame.style.minimal_height = 250

    local search_table = frame.add({type = 'table', column_count = 2})
    search_table.add({type = 'label', caption = 'Search: '})
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

    local bottom_grid = frame.add({type = 'table', column_count = 2})

    bottom_grid.add({type = 'label', caption = 'Quantity: '}).style.font = 'default-bold'

    local text_input =
        bottom_grid.add(
        {
            type = 'text-box',
            text = 1
        }
    )

    local slider =
        frame.add(
        {
            type = 'slider',
            minimum_value = 1,
            maximum_value = 5e3,
            value = 1
        }
    )
    slider.style.width = 115
    text_input.style.width = 60

    local coinsleft = frame.add({type = 'flow'})

    coinsleft.add(
        {
            type = 'label',
            caption = 'Coins left: ' .. format_number(player_item_count, true)
        }
    )

    this.players[player.index].data.search_text = search_text
    this.players[player.index].data.text_input = text_input
    this.players[player.index].data.slider = slider
    this.players[player.index].data.frame = frame
    this.players[player.index].data.item_frame = pane
    this.players[player.index].data.coins_left = coinsleft

    redraw_market_items(pane, player, search_text)
end

local function gui_click(event)
    local this = WPT.get()

    local element = event.element
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    if not this.players[player.index] then
        return
    end

    local data = this.players[player.index].data
    if not data then
        return
    end

    if not element.valid then
        return
    end
    local name = element.name

    if name == 'less' then
        local slider_value = this.players[player.index].data.slider.slider_value
        if slider_value > 1 then
            data.slider.slider_value = slider_value - 1
            data.text_input.text = data.slider.slider_value
            redraw_market_items(data.item_frame, player, data.search_text)
        end
        return
    elseif name == 'more' then
        local slider_value = data.slider.slider_value
        if slider_value <= 1e3 then
            data.slider.slider_value = slider_value + 1
            data.text_input.text = data.slider.slider_value
            redraw_market_items(data.item_frame, player, data.search_text)
        end
        return
    end

    if not player.opened then
        return
    end

    if not player.opened == main_frame_name then
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
    local slider_value = math.ceil(data.slider.slider_value)
    local cost = (item.price * slider_value)
    local item_count = item.stack * slider_value

    if name == 'chest_limit_outside' then
        if this.chest_limit_outside_upgrades == 8 then
            local main_market_items = WPT.get('main_market_items')

            main_market_items['chest_limit_outside'].enabled = false
            main_market_items['chest_limit_outside'].tooltip = 'Max limit bought!'
            redraw_market_items(data.item_frame, player, data.search_text)
            return player.print("You can't purchase more chests.", {r = 0.98, g = 0.66, b = 0.22})
        end
        player.remove_item({name = item.value, count = item.price})

        local message =
            shopkeeper ..
            player.name .. ' has bought the chest limit upgrade for ' .. format_number(item.price, true) .. ' coins.'
        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name ..
                    ' has bought the chest limit upgrade for ' .. format_number(item.price, true) .. ' coins.'
            }
        )
        this.chest_limit_outside_upgrades = this.chest_limit_outside_upgrades + item.stack

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'locomotive_max_health' then
        player.remove_item({name = item.value, count = item.price})

        local message =
            shopkeeper ..
            player.name ..
                ' has bought the locomotive health modifier for ' .. format_number(item.price, true) .. ' coins.'
        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name ..
                    ' has bought the locomotive health modifier for ' .. format_number(item.price, true) .. ' coins.'
            }
        )
        this.locomotive_max_health = this.locomotive_max_health + 2500 * item.stack
        local m = this.locomotive_health / this.locomotive_max_health
        this.locomotive.health = 1000 * m

        this.train_upgrades = this.train_upgrades + item.stack
        this.health_upgrades = this.health_upgrades + item.stack
        rendering.set_text(this.health_text, 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health)

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'locomotive_xp_aura' then
        player.remove_item({name = item.value, count = item.price})

        local message =
            shopkeeper ..
            player.name ..
                ' has bought the locomotive xp aura modifier for ' .. format_number(item.price, true) .. ' coins.'
        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name ..
                    ' has bought the locomotive xp aura modifier for ' .. format_number(item.price, true) .. ' coins.'
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

        local message =
            shopkeeper ..
            player.name .. ' has bought the XP points modifier for ' .. format_number(item.price, true) .. ' coins.'
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

    if name == 'flamethrower_turrets' then
        player.remove_item({name = item.value, count = item.price})
        if item.stack >= 1 then
            local message =
                shopkeeper ..
                player.name ..
                    ' has bought a flamethrower-turret slot for ' .. format_number(item.price, true) .. ' coins.'
            Alert.alert_all_players(5, message)
            Server.to_discord_bold(
                table.concat {
                    player.name ..
                        ' has bought a flamethrower-turret slot for ' .. format_number(item.price, true) .. ' coins.'
                }
            )
        else
            local message =
                shopkeeper ..
                player.name ..
                    ' has bought ' ..
                        item.stack .. ' flamethrower-turret slots for ' .. format_number(item.price, true) .. ' coins.'
            Alert.alert_all_players(5, message)
            Server.to_discord_bold(
                table.concat {
                    player.name ..
                        ' has bought ' ..
                            item.stack ..
                                ' flamethrower-turret slots for ' .. format_number(item.price, true) .. ' coins.'
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
            local message =
                shopkeeper ..
                player.name .. ' has bought a landmine slot for ' .. format_number(item.price, true) .. ' coins.'
            Alert.alert_all_players(3, message)

            if item.price >= 1000 then
                Server.to_discord_bold(
                    table.concat {
                        player.name ..
                            ' has bought ' ..
                                item.stack .. ' landmine slots for ' .. format_number(item.price, true) .. ' coins.'
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
    if name == 'skill_reset' then
        player.remove_item({name = item.value, count = item.price})

        local message =
            shopkeeper ..
            player.name ..
                ' decided to recycle their RPG skills and start over for ' ..
                    format_number(item.price, true) .. ' coins.'
        Alert.alert_all_players(10, message)

        RPG.rpg_reset_player(player, true)

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)
        return
    end

    if player_item_count >= cost then
        if player.can_insert({name = name, count = item_count}) then
            player.play_sound({path = 'entity-close/stone-furnace', volume_modifier = 0.65})
            player.remove_item({name = item.value, count = cost})
            local inserted_count = player.insert({name = name, count = item_count})
            if inserted_count < item_count then
                player.play_sound({path = 'utility/cannot_build', volume_modifier = 0.65})
                player.insert({name = item.value, count = cost})
                player.remove_item({name = name, count = inserted_count})
            end
            redraw_market_items(data.item_frame, player, data.search_text)
            redraw_coins_left(data.coins_left, player)
        end
    end
end

local function gui_closed(event)
    local player = game.players[event.player_index]
    local this = WPT.get()

    local type = event.gui_type

    if type == defines.gui_type.custom then
        local data = this.players[player.index].data
        if not data then
            return
        end
        close_market_gui(player)
    end
end

local function on_player_changed_position(event)
    local this = WPT.get()
    local player = game.players[event.player_index]
    if not this.players[player.index] then
        return
    end
    local data = this.players[player.index].data

    if data and data.frame and data.frame.valid then
        local position = this.market.position
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
        for _, entity in pairs(
            surface.find_entities_filtered {area = area, type = 'item-entity', name = 'item-on-ground'}
        ) do
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

    local position = loco_surface.find_non_colliding_position('market', center_position, 128, 0.5)
    local biters = {
        'big-biter',
        'behemoth-biter',
        'big-spitter',
        'behemoth-spitter'
    }
    local e =
        loco_surface.create_entity(
        {name = biters[math.random(1, 4)], position = position, force = 'player', create_build_effect_smoke = false}
    )
    e.ai_settings.allow_destroy_when_commands_fail = false
    e.ai_settings.allow_try_return_to_spawner = false

    for x = center_position.x - 5, center_position.x + 5, 1 do
        for y = center_position.y - 5, center_position.y + 5, 1 do
            if math.random(1, 2) == 1 then
                loco_surface.spill_item_stack(
                    {x + math.random(0, 9) * 0.1, y + math.random(0, 9) * 0.1},
                    {name = 'raw-fish', count = 1},
                    false
                )
            end
            loco_surface.set_tiles({{name = 'blue-refined-concrete', position = {x, y}}}, true)
        end
    end
    for x = center_position.x - 3, center_position.x + 3, 1 do
        for y = center_position.y - 3, center_position.y + 3, 1 do
            if math.random(1, 2) == 1 then
                loco_surface.spill_item_stack(
                    {x + math.random(0, 9) * 0.1, y + math.random(0, 9) * 0.1},
                    {name = 'raw-fish', count = 1},
                    false
                )
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
        if wagon.entity.name == 'cargo-wagon' then
            if inside(wagon.entity.position, area) then
                return true, wagon.entity
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

    for k, v in pairs(outside_chests) do
        if v and v.valid then
            if chests_linked_to[train.unit_number] then
                local linked_to = chests_linked_to[train.unit_number].count
                if linked_to == chest_limit_outside_upgrades then
                    return
                end
                outside_chests[entity.unit_number] = entity

                if not increased then
                    chests_linked_to[train.unit_number].count = linked_to + 1
                    chests_linked_to[train.unit_number][entity.unit_number] = true
                    increased = true
                    goto continue
                end
            else
                outside_chests[entity.unit_number] = entity
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
        outside_chests[entity.unit_number] = entity
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
        for k, v in pairs(chests_linked_to) do
            if v[entity.unit_number] then
                v.count = v.count - 1
                if v.count <= 0 then
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
    local target_chest

    for key, chest in pairs(outside_chests) do
        if not chest or not chest.valid then
            return
        end

        local area = {
            left_top = {x = chest.position.x - 4, y = chest.position.y - 4},
            right_bottom = {x = chest.position.x + 4, y = chest.position.y + 4}
        }
        local success, entity = contains_positions(area)
        if success then
            target_chest = entity
        else
            return
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
    end
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

local function add_random_loot_to_main_market(rarity)
    local main_market_items = WPT.get('main_market_items')
    local items = Market.get_random_item(rarity, true, false)

    local types = game.item_prototypes
    local ticker = 0

    for k, v in pairs(main_market_items) do
        if not v.static then
            main_market_items[k] = nil
        end
    end

    for k, v in pairs(items) do
        local price = v.price[1][2] + math.random(1, 15) * rarity
        local value = v.price[1][1]
        local stack = 1
        ticker = ticker + 1
        if v.offer.item == 'coin' then
            price = v.price[1][2]
            stack = v.offer.count
            if not stack then
                stack = v.price[1][2]
            end
        end

        if main_market_items[v.offer.item] then
            main_market_items[v.offer.item] = nil
        end
        main_market_items[v.offer.item] = {
            stack = stack,
            value = value,
            price = price,
            tooltip = types[v.offer.item].localised_name,
            upgrade = false
        }
        if ticker >= 9 then
            return
        end
    end
end

local function on_research_finished()
    local difficulty_poll_closing_timeout = Difficulty.get('difficulty_poll_closing_timeout')
    if game.tick < difficulty_poll_closing_timeout then
        return
    end

    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local breached_wall = WPT.get('breached_wall')
    add_random_loot_to_main_market(breached_wall)
    local message = 'New items have been unlocked at the locomotive market!'
    Alert.alert_all_players(5, message, nil, 'achievement/tech-maniac', 0.1)
    Public.refresh_gui()
end

local function tick()
    local ticker = game.tick

    if ticker % 30 == 0 then
        place_market()
        validate_index()
        set_locomotive_health()
        fish_tag()
        divide_contents()
    end

    if ticker % 120 == 0 then
        Public.boost_players_around_train()
    end

    if ticker % 2500 == 0 then
        Public.transfer_pollution()
    end

    if ticker % 1800 == 0 then
        set_player_spawn()
        refill_fish()
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
    local rpg = RPG.get_table()
    local this = WPT.get()
    if not this.active_surface_index then
        return
    end
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end
    local surface = game.surfaces[this.active_surface_index]
    local icw_table = ICW.get_table()
    local unit_surface = this.locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

    local data = {
        this = this,
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

    local data = {
        locomotive = locomotive,
        surface = surface,
        entity = entity
    }

    local success = is_around_train(data)
    return success
end

function Public.render_train_hp()
    local this = WPT.get()
    local surface = game.surfaces[this.active_surface_index]

    this.health_text =
        rendering.draw_text {
        text = 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health,
        surface = surface,
        target = this.locomotive,
        target_offset = {0, -4.5},
        color = this.locomotive.color,
        scale = 1.40,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    this.caption =
        rendering.draw_text {
        text = 'Comfy Choo Choo',
        surface = surface,
        target = this.locomotive,
        target_offset = {0, -6.25},
        color = this.locomotive.color,
        scale = 1.80,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    this.circle =
        rendering.draw_circle {
        surface = surface,
        target = this.locomotive,
        color = this.locomotive.color,
        filled = false,
        radius = this.locomotive_xp_aura,
        only_in_alt_mode = true
    }
end

function Public.locomotive_spawn(surface, position)
    local this = WPT.get()
    for y = -6, 6, 2 do
        surface.create_entity(
            {name = 'straight-rail', position = {position.x, position.y + y}, force = 'player', direction = 0}
        )
    end
    this.locomotive =
        surface.create_entity({name = 'locomotive', position = {position.x, position.y + -3}, force = 'player'})
    this.locomotive.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 100})

    this.locomotive_cargo =
        surface.create_entity({name = 'cargo-wagon', position = {position.x, position.y + 3}, force = 'player'})
    this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = 'raw-fish', count = 8})

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

    for y = -1, 0, 0.05 do
        local scale = math.random(50, 100) * 0.01
        rendering.draw_sprite(
            {
                sprite = 'item/raw-fish',
                orientation = math.random(0, 100) * 0.01,
                x_scale = scale,
                y_scale = scale,
                tint = {math.random(60, 255), math.random(60, 255), math.random(60, 255)},
                render_layer = 'selection-box',
                target = this.locomotive_cargo,
                target_offset = {-0.7 + math.random(0, 140) * 0.01, y},
                surface = surface
            }
        )
    end

    this.locomotive.color = {0, 255, 0}
    this.locomotive.minable = false
    this.locomotive_cargo.minable = false
    this.locomotive_cargo.operable = true

    local locomotive = ICW.register_wagon(this.locomotive)
    local wagon = ICW.register_wagon(this.locomotive_cargo)
    locomotive.entity_count = 999
    wagon.entity_count = 999

    this.icw_locomotive = locomotive

    game.forces.player.set_spawn_position({0, 19}, locomotive.surface)
end

function Public.get_items()
    local chest_limit_outside_upgrades = WPT.get('chest_limit_outside_upgrades')
    local health_upgrades = WPT.get('health_upgrades')
    local aura_upgrades = WPT.get('aura_upgrades')
    local main_market_items = WPT.get('main_market_items')
    local xp_points_upgrade = WPT.get('xp_points_upgrade')
    local flame_turret = WPT.get('upgrades').flame_turret.bought
    local landmine = WPT.get('upgrades').landmine.bought

    local chest_limit_cost = 2500 * (1 + chest_limit_outside_upgrades)
    local health_cost = 10000 * (1 + health_upgrades)
    local aura_cost = 5000 * (1 + aura_upgrades)
    local xp_point_boost_cost = 7500 * (1 + xp_points_upgrade)
    local flamethrower_turrets_cost = 3000 * (1 + flame_turret)
    local land_mine_cost = 2 * (1 + landmine)
    local skill_reset_cost = 100000

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
            tooltip = 'Upgrades the amount of chests that can be placed outside.\nCan be purchased multiple times.',
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
        tooltip = 'Upgrades the train health.\nCan be purchased multiple times.',
        sprite = 'achievement/getting-on-track',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['locomotive_xp_aura'] = {
        stack = 1,
        value = 'coin',
        price = aura_cost,
        tooltip = 'Upgrades the XP aura that is around the train.',
        sprite = 'achievement/tech-maniac',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['xp_points_boost'] = {
        stack = 1,
        value = 'coin',
        price = xp_point_boost_cost,
        tooltip = 'Upgrades the amount of XP points you get inside the XP aura',
        sprite = 'achievement/trans-factorio-express',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['flamethrower_turrets'] = {
        stack = 1,
        value = 'coin',
        price = flamethrower_turrets_cost,
        tooltip = 'Upgrades the amount of flamethrowers that can be placed.',
        sprite = 'achievement/pyromaniac',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['land_mine'] = {
        stack = 1,
        value = 'coin',
        price = land_mine_cost,
        tooltip = 'Upgrades the amount of landmines that can be placed.',
        sprite = 'achievement/watch-your-step',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['skill_reset'] = {
        stack = 1,
        value = 'coin',
        price = skill_reset_cost,
        tooltip = 'For when you have picked the wrong RPG path and want to start over.\nPoints will be kept.',
        sprite = 'achievement/golem',
        enabled = true,
        upgrade = true,
        static = true
    }

    main_market_items['small-lamp'] = {
        stack = 1,
        value = 'coin',
        price = 5,
        tooltip = 'Small Sunlight',
        upgrade = false,
        static = true
    }
    main_market_items['wood'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = 'Some fine Wood',
        upgrade = false,
        static = true
    }
    main_market_items['iron-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = 'Some chunky iron',
        upgrade = false,
        static = true
    }
    main_market_items['copper-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = 'Some chunky copper',
        upgrade = false,
        static = true
    }
    main_market_items['stone'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = 'Some chunky stone',
        upgrade = false,
        static = true
    }
    main_market_items['coal'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = 'Some chunky coal',
        upgrade = false,
        static = true
    }
    main_market_items['uranium-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = 'Some chunky uranium',
        upgrade = false,
        static = true
    }
    main_market_items['land-mine'] = {
        stack = 1,
        value = 'coin',
        price = 10,
        tooltip = 'Land Boom Danger',
        upgrade = false,
        static = true
    }
    main_market_items['raw-fish'] = {
        stack = 1,
        value = 'coin',
        price = 4,
        tooltip = 'Flappy Fish',
        upgrade = false,
        static = true
    }
    main_market_items['firearm-magazine'] = {
        stack = 1,
        value = 'coin',
        price = 5,
        tooltip = 'Firearm Pew',
        upgrade = false,
        static = true
    }
    main_market_items['crude-oil-barrel'] = {
        stack = 1,
        value = 'coin',
        price = 8,
        tooltip = 'Crude Oil Flame',
        upgrade = false,
        static = true
    }
    return main_market_items
end

function Public.transfer_pollution()
    local locomotive = WPT.get('locomotive')
    local active_surface_index = WPT.get('active_surface_index')
    local icw_locomotive = WPT.get('icw_locomotive')
    local surface = icw_locomotive.surface
    if not surface then
        return
    end

    local total_interior_pollution = surface.get_total_pollution()

    local pollution = surface.get_total_pollution() * (3 / (4 / 3 + 1)) * Difficulty.get().difficulty_vote_value
    game.surfaces[active_surface_index].pollute(locomotive.position, pollution)
    game.pollution_statistics.on_flow('locomotive', pollution - total_interior_pollution)
    surface.clear_pollution()
end

function Public.enable_poison_defense()
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end
    local pos = locomotive.position
    create_poison_cloud({x = pos.x, y = pos.y})
    if math.random(1, 3) == 1 then
        local random_angles = {math.rad(math.random(359))}
        create_poison_cloud({x = pos.x + 24 * math.cos(random_angles[1]), y = pos.y + -24 * math.sin(random_angles[1])})
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

return Public
