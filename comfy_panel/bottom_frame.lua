local Misc = require 'commands.misc'
local Event = require 'utils.event'
local Global = require 'utils.global'
local ComfyGui = require 'comfy_panel.main'
local Gui = require 'utils.gui'

local this = {
    players = {},
    activate_custom_buttons = false,
    bottom_right = false,
    bottom_quickbar_button = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

local bottom_guis_frame = Gui.uid_name()
local clear_corpse_button_name = Gui.uid_name()
local bottom_quickbar_button_name = Gui.uid_name()

function Public.get_player_data(player, remove_user_data)
    if remove_user_data then
        if this.players[player.index] then
            this.players[player.index] = nil
        end
        return
    end
    if not this.players[player.index] then
        this.players[player.index] = {}
    end
    return this.players[player.index]
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.on_init(
    function()
        this.players = {}
    end
)

function Public.reset()
    this.players = {}
end

----! Gui Functions ! ----

local function create_frame(player, rebuild)
    local gui = player.gui
    local frame = gui.screen[bottom_guis_frame]
    if frame and frame.valid then
        if rebuild then
            frame.destroy()
        else
            return frame
        end
    end

    frame =
        player.gui.screen.add {
        type = 'frame',
        name = bottom_guis_frame,
        direction = 'vertical'
    }
    frame.style.padding = 3
    frame.style.minimal_height = 96
    frame.style.top_padding = 4

    local inner_frame =
        frame.add {
        type = 'frame',
        direction = 'vertical'
    }
    inner_frame.style = 'quick_bar_inner_panel'

    inner_frame.add {
        type = 'sprite-button',
        sprite = 'entity/behemoth-biter',
        name = clear_corpse_button_name,
        tooltip = {'commands.clear_corpse'},
        style = 'quick_bar_page_button'
    }

    local bottom_quickbar_button =
        inner_frame.add {
        type = 'sprite-button',
        name = bottom_quickbar_button_name,
        style = 'quick_bar_page_button'
    }

    this.bottom_quickbar_button[player.index] = {name = bottom_quickbar_button_name, frame = bottom_quickbar_button}

    if this.bottom_quickbar_button.sprite and this.bottom_quickbar_button.tooltip then
        bottom_quickbar_button.sprite = this.bottom_quickbar_button.sprite
        bottom_quickbar_button.tooltip = this.bottom_quickbar_button.tooltip
    end

    return frame
end

local function set_location(player)
    local frame = create_frame(player)
    local resolution = player.display_resolution
    local scale = player.display_scale

    if this.players[player.index] and this.players[player.index].bottom_left then
        frame.location = {
            x = (resolution.width / 2) - ((54 + 445) * scale),
            y = (resolution.height - (96 * scale))
        }
        return
    end

    if this.bottom_right then
        frame.location = {
            x = (resolution.width / 2) - ((54 + -528) * scale),
            y = (resolution.height - (96 * scale))
        }
    else
        local experimental = get_game_version()
        if experimental then
            frame.location = {
                x = (resolution.width / 2) - ((54 + 445) * scale),
                y = (resolution.height - (96 * scale))
            }
        else
            frame.location = {
                x = (resolution.width / 2) - ((54 + 258) * scale),
                y = (resolution.height - (96 * scale))
            }
        end
    end
end

--- Activates the custom buttons
---@param boolean
function Public.activate_custom_buttons(value)
    if value then
        this.activate_custom_buttons = value
    else
        this.activate_custom_buttons = false
    end
end

--- Fetches if the custom buttons are activated
function Public.is_custom_buttons_enabled()
    return this.activate_custom_buttons
end

--- Sets the buttons to be aligned bottom right
---@param boolean
function Public.bottom_right(value)
    if value then
        this.bottom_right = value
    else
        this.bottom_right = false
    end
end

Gui.on_click(
    clear_corpse_button_name,
    function(event)
        Misc.clear_corpses(event)
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.players[event.player_index]
        if this.activate_custom_buttons then
            set_location(player)
        end
    end
)

Event.add(
    defines.events.on_player_display_resolution_changed,
    function(event)
        local player = game.get_player(event.player_index)
        if this.activate_custom_buttons then
            set_location(player)
        end
    end
)

Event.add(
    defines.events.on_player_respawned,
    function(event)
        local player = game.get_player(event.player_index)
        if this.activate_custom_buttons then
            set_location(player)
        end
    end
)

Event.add(
    defines.events.on_player_died,
    function(event)
        local player = game.get_player(event.player_index)
        if this.activate_custom_buttons then
            local frame = player.gui.screen[bottom_guis_frame]
            if frame and frame.valid then
                frame.destroy()
            end
        end
    end
)

Event.add(
    defines.events.on_player_display_scale_changed,
    function(event)
        local player = game.get_player(event.player_index)
        if this.activate_custom_buttons then
            set_location(player)
        end
    end
)

Public.bottom_guis_frame = bottom_guis_frame
Public.set_location = set_location
ComfyGui.screen_to_bypass(bottom_guis_frame)

return Public
