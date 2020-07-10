local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Token = require 'utils.token'
local Color = require 'utils.color_presets'

local pairs = pairs
local next = next

local Public = {}

local active_alerts = {}
local id_counter = {0}
local alert_zoom_to_pos = Gui.uid_name()

local on_tick

Global.register(
    {active_alerts = active_alerts, id_counter = id_counter},
    function(tbl)
        active_alerts = tbl.active_alerts
        id_counter = tbl.id_counter
    end,
    'alert'
)

local alert_frame_name = Gui.uid_name()
local alert_container_name = Gui.uid_name()
local alert_progress_name = Gui.uid_name()
local close_alert_name = Gui.uid_name()

--- Apply this name to an element to have it close the alert when clicked.
-- Two elements in the same parent cannot have the same name. If you need your
-- own name you can use Public.close_alert(element)
Public.close_alert_name = close_alert_name

---Creates a unique ID for a alert message
local function autoincrement()
    local id = id_counter[1] + 1
    id_counter[1] = id
    return id
end

---Attempts to get a alert based on the element, will traverse through parents to find it.
---@param element LuaGuiElement
local function get_alert(element)
    if not element or not element.valid then
        return nil
    end

    if element.name == alert_frame_name then
        return element.parent
    end

    return get_alert(element.parent)
end

--- Closes the alert for the element.
--@param element LuaGuiElement
function Public.close_alert(element)
    local alert = get_alert(element)
    if not alert then
        return
    end

    local data = Gui.get_data(alert)
    active_alerts[data.alert_id] = nil
    Gui.destroy(alert)
end

---Message to a specific player
---@param player LuaPlayer
---@param duration number in seconds
---@param sound string sound to play, nil to not play anything
local function alert_to(player, duration, sound, volume)
    local frame_holder = player.gui.left.add({type = 'flow'})

    local frame =
        frame_holder.add({type = 'frame', name = alert_frame_name, direction = 'vertical', style = 'captionless_frame'})
    frame.style.width = 300

    local container = frame.add({type = 'flow', name = alert_container_name, direction = 'horizontal'})
    container.style.horizontally_stretchable = true

    local progressbar = frame.add({type = 'progressbar', name = alert_progress_name})
    local style = progressbar.style
    style.width = 290
    style.height = 4
    style.color = Color.orange
    progressbar.value = 1 -- it starts full

    local id = autoincrement()
    local tick = game.tick
    if not duration then
        duration = 15
    end

    Gui.set_data(
        frame_holder,
        {
            alert_id = id,
            progressbar = progressbar,
            start_tick = tick,
            end_tick = tick + duration * 60
        }
    )

    if not next(active_alerts) then
        Event.add_removable_nth_tick(2, on_tick)
    end

    active_alerts[id] = frame_holder

    if sound then
        volume = volume or 0.80
        player.play_sound({path = sound, volume_modifier = volume})
    end

    return container
end

local function zoom_to_pos(event)
    local player = event.player
    local element = event.element
    local position = Gui.get_data(element)

    player.zoom_to_world(position, 0.5)
end

local close_alert = Public.close_alert
local function on_click_close_alert(event)
    close_alert(event.element)
end

Gui.on_click(alert_zoom_to_pos, zoom_to_pos)
Gui.on_click(alert_frame_name, on_click_close_alert)
Gui.on_click(alert_container_name, on_click_close_alert)
Gui.on_click(alert_progress_name, on_click_close_alert)
Gui.on_click(close_alert_name, on_click_close_alert)

local function update_alert(id, frame, tick)
    if not frame.valid then
        active_alerts[id] = nil
        return
    end

    local data = Gui.get_data(frame)
    local end_tick = data.end_tick

    if tick > end_tick then
        Gui.destroy(frame)
        active_alerts[data.alert_id] = nil
    else
        local limit = end_tick - data.start_tick
        local current = end_tick - tick
        data.progressbar.value = current / limit
    end
end

on_tick =
    Token.register(
    function(event)
        if not next(active_alerts) then
            Event.remove_removable_nth_tick(2, on_tick)
            return
        end

        local tick = event.tick

        for id, frame in pairs(active_alerts) do
            update_alert(id, frame, tick)
        end
    end
)

---Message a specific player, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param player LuaPlayer
---@param duration table
---@param template function
---@param sound string sound to play, nil to not play anything
function Public.alert_player_template(player, duration, template, sound, volume)
    sound = sound or 'utility/new_objective'
    local container = alert_to(player, duration, sound, volume)
    if container then
        template(container, player)
    end
end

---Message all players of the given force, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param force LuaForce
---@param duration number
---@param template function
---@param sound string sound to play, nil to not play anything
function Public.alert_force_template(force, duration, template, sound)
    sound = sound or 'utility/new_objective'
    local players = force.connected_players
    for i = 1, #players do
        local player = players[i]
        template(alert_to(player, duration, sound), player)
    end
end

---Message all players, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param duration number
---@param template function
---@param sound string sound to play, nil to not play anything
function Public.alert_all_players_template(duration, template, sound)
    sound = sound or 'utility/new_objective'
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        template(alert_to(player, duration, sound), player)
    end
end

---Message all players at a given location
---@param player LuaPlayer
---@param message string
---@param color string
function Public.alert_all_players_location(player, message, color)
    Public.alert_all_players_template(
        15,
        function(container)
            local sprite =
                container.add {
                type = 'sprite-button',
                name = alert_zoom_to_pos,
                sprite = 'utility/search_icon',
                style = 'slot_button'
            }

            Gui.set_data(sprite, player.position)

            local label =
                container.add {
                type = 'label',
                name = Public.close_alert_name,
                caption = message
            }
            local label_style = label.style
            label_style.single_line = false
            label_style.font_color = color or Color.comfy
        end
    )
end

---Message to a specific player
---@param player LuaPlayer
---@param duration number
---@param message string
---@param color string
function Public.alert_player(player, duration, message, color, sprite, volume)
    Public.alert_player_template(
        player,
        duration,
        function(container)
            container.add {
                type = 'sprite-button',
                sprite = sprite or 'achievement/you-are-doing-it-right',
                style = 'slot_button'
            }
            local label = container.add({type = 'label', name = close_alert_name, caption = message})
            label.style.single_line = false
            label.style.font_color = color or Color.comfy
        end,
        nil,
        volume
    )
end

---Message to a specific player as warning
---@param player LuaPlayer
---@param duration number
---@param message string
---@param color string
function Public.alert_player_warning(player, duration, message, color)
    Public.alert_player_template(
        player,
        duration,
        function(container)
            container.add {
                type = 'sprite-button',
                sprite = 'achievement/golem',
                style = 'slot_button'
            }
            local label = container.add({type = 'label', name = close_alert_name, caption = message})
            label.style.single_line = false
            label.style.font_color = color or Color.comfy
        end
    )
end

---Message to all players of a given force
---@param force LuaForce
---@param duration number
---@param message string
function Public.alert_force(force, duration, message)
    local players = force.connected_players
    for i = 1, #players do
        local player = players[i]
        Public.alert_player(player, duration, message)
    end
end

---Message to all players
---@param duration number
---@param message string
---@param color string
function Public.alert_all_players(duration, message, color, sprite, volume)
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Public.alert_player(player, duration, message, color, sprite, volume)
    end
end

commands.add_command(
    'notify_all_players',
    'Usable only for admins - sends an alert message to all players!',
    function(cmd)
        local p
        local player = game.player
        local param = cmd.parameter

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end
                if not param then
                    return p('Valid arguments are: message_to_print')
                end
                local comfy = '[color=blue]' .. player.name .. ':[/color] \n'
                local message = comfy .. param
                Public.alert_all_players_location(player, message)
            end
        else
            p = log
            if not param then
                return p('Valid arguments are: message_to_print')
            end
            local comfy = '[color=blue]Server:[/color] \n'
            local message = comfy .. param
            p(param)
            Public.alert_all_players(15, message)
        end
    end
)

commands.add_command(
    'notify_player',
    'Usable only for admins - sends an alert message to a player!',
    function(cmd)
        local p
        local player = game.player
        local param = cmd.parameter

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end

                local t_player
                local t_message
                local target_player
                local str = ''

                if not param then
                    return p('[ERROR] Valid arguments are:\nplayer = player,\nmessage = message', Color.fail)
                end

                local t = {}
                for i in string.gmatch(param, '%S+') do
                    table.insert(t, i)
                end

                t_player = t[1]

                for i = 2, #t do
                    str = str .. t[i] .. ' '
                    t_message = str
                end

                if game.players[t_player] then
                    target_player = game.players[t_player]
                else
                    return p('[ERROR] No player was provided', Color.fail)
                end

                if t_message then
                    local comfy = '[color=blue]' .. player.name .. ':[/color] \n'
                    local message = comfy .. t_message
                    Public.alert_player_warning(target_player, 15, message)
                else
                    p('No message was provided', Color.fail)
                end
            end
        end
    end
)

return Public
