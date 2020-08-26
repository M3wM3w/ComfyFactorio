-- by Tom Fyuri, based on player_list, map_info, alert and some other modules and utils.
local Global = require 'utils.global'
local Tabs = require 'comfy_panel.main'
local Event = require 'utils.event'

local alert_log_delete_on_leave = false -- should be fine to keep on any game mode that can soft-reset, otherwise might as well put 'true'

local alert_log = {
    --localised_category = "alert_log",
    main_caption = {"alert_log" .. '.alert_log_main_caption'},
    main_caption_color = {r = 150, g = 150, b = 0},
    sub_caption = {"alert_log" .. '.alert_log_sub_caption'},
    sub_caption_color = {r = 0, g = 150, b = 0},
    global_alert_caption = {"alert_log" .. '.global_alert_caption'},
    personal_alert_caption = {"alert_log" .. '.personal_alert_caption'},
}
local alert_log_global = {}
local alert_log_personal = {}

local alert_log_max_entries = 1000 -- for now just prune it if it reaches ever this
local last_round_reset_tick = 0 -- if there is softreset, store the tick upon which softreset happened last

local function increment(t, v)
    t[#t + 1] = (v or 1)
end

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

--function Public.Pop_log()
--    return alert_log
--end

function Public.Reset_Global_Log()
    alert_log_global = {}
    alert_log_personal = {}
    last_round_reset_tick = game.tick
    for _, player in pairs(game.connected_players) do
      alert_log_personal[player.index] = {}
    end
    -- note: if upon clearing personal alerts - player still had Alert Log tab opened, they can see old alerts until they recieve the new one and refresh() clears the old ones from their screen.
end

local create_alert_log = (function(player, frame)
    frame.clear()
    frame.style.padding = 4
    frame.style.margin = 0

    local t = frame.add {type = 'table', column_count = 1}

    local line = t.add {type = 'line'}
    line.style.top_margin = 4
    line.style.bottom_margin = 4

    --[[local caption = alert_log.main_caption or {alert_log.localised_category .. '.alert_log_main_caption'}
    local sub_caption = alert_log.sub_caption or {alert_log.localised_category .. '.alert_log_sub_caption'}
    local global_alert_caption = alert_log.global_alert_caption or {alert_log.localised_category .. '.global_alert_caption'}
    local personal_alert_caption  = alert_log.personal_alert_caption or {alert_log.localised_category .. '.personal_alert_caption'}
    if alert_log.localised_category then
        alert_log.main_caption = caption
        alert_log.sub_caption = sub_caption
        alert_log.global_alert_caption = global_alert_caption
        alert_log.personal_alert_caption = personal_alert_caption
    end]]--

    local text = ""
    local ptext = ""
    --for i = #alert_log_global, 1, -1 do -- normal order
    for i = 1, #alert_log_global, 1 do -- reversed order
        text = alert_log_global[i].."\n"..text
    end
    local player_index = player.index
    -- handling recreation of personal log (if needed) at: connection/disconnection and at round soft-reset
    for i = 1, #alert_log_personal[player_index], 1 do -- reversed order
        ptext = alert_log_personal[player_index][i].."\n"..ptext
    end

    local l = t.add {type = 'label', caption = alert_log.main_caption}
    l.style.font = 'heading-1'
    l.style.font_color = alert_log.main_caption_color
    l.style.minimal_width = 780
    l.style.horizontal_align = 'center'
    l.style.vertical_align = 'center'

    local l_2 = t.add {type = 'label', caption = alert_log.sub_caption}
    l_2.style.font = 'heading-2'
    l_2.style.font_color = alert_log.sub_caption_color
    l_2.style.minimal_width = 780
    l_2.style.horizontal_align = 'center'
    l_2.style.vertical_align = 'center'

    local line_2 = t.add {type = 'line'}
    line_2.style.top_margin = 4
    line_2.style.bottom_margin = 4

    local ts = frame.add({type = 'table', column_count = 2})
    local headings = {
        { alert_log.global_alert_caption, 380},
        { alert_log.personal_alert_caption, 380},
    }
    for _, h in pairs(headings) do
        local l = ts.add({type = 'label', caption = h[1]})
        l.style.font_color = {r = 0, g = 150, b = 0}
        l.style.font = 'default-listbox'
        l.style.top_padding = 4
        l.style.minimal_height = 20
        l.style.minimal_width = h[2]
        l.style.maximal_width = h[2]
    end

    local t2 = frame.add {type = 'table', column_count = 2}

    local scroll_pane =
        t2.add {
        type = 'scroll-pane',
        name = 'scroll_pane',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto'
    }
    scroll_pane.style.maximal_height = 300
    scroll_pane.style.minimal_height = 300

    local l_3 = scroll_pane.add {type = 'label', caption = text}
    l_3.style.font = 'heading-2'
    l_3.style.single_line = false
    l_3.style.font_color = {r = 0.85, g = 0.85, b = 0.88}
    l_3.style.minimal_width = 380
    l_3.style.horizontal_align = 'left'
    l_3.style.vertical_align = 'top'

    local scroll_paneb =
        t2.add {
        type = 'scroll-pane',
        name = 'scroll_paneb',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto'
    }
    scroll_paneb.style.maximal_height = 300
    scroll_paneb.style.minimal_height = 300

    local l_3b = scroll_paneb.add {type = 'label', caption = ptext}
    l_3b.style.font = 'heading-2'
    l_3b.style.single_line = false
    l_3b.style.font_color = {r = 0.85, g = 0.85, b = 0.88}
    l_3b.style.minimal_width = 380
    l_3b.style.horizontal_align = 'left'
    l_3b.style.vertical_align = 'top'

    local b = frame.add {type = 'button', caption = 'CLOSE', name = 'close_alert_log'}
    b.style.font = 'heading-2'
    b.style.padding = 2
    b.style.top_margin = 3
    b.style.left_margin = 333
    b.style.horizontal_align = 'center'
    b.style.vertical_align = 'center'
end)

local function refresh()
    for _, player in pairs(game.connected_players) do
        local frame = Tabs.comfy_panel_get_active_frame(player)
        if frame then
            if frame.name ~= 'Alert Log' then
                return
            end
            create_alert_log(player, frame)
        end
    end
end

function Public.Push_log_entry(entry)
    if #alert_log_global > alert_log_max_entries then
        alert_log_global = {}
    end
    local ticks = game.tick - last_round_reset_tick
    local seconds = math.floor(ticks / 60)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local days = math.floor(hours / 24)
    if (minutes <= 0) then
      increment(alert_log_global,"["..math.floor(seconds%60).."s] "..entry)
    elseif (minutes < 60) then
      increment(alert_log_global,"["..math.floor(minutes%60).."m:"..math.floor(seconds%60).."s] "..entry)
    elseif (hours < 24) then
      increment(alert_log_global,"["..math.floor(hours%60).."h:"..math.floor(minutes%60).."m:"..math.floor(seconds%60).."s] "..entry)
    else
      increment(alert_log_global,"["..math.floor(days%60).."d:"..math.floor(hours%60).."h:"..math.floor(minutes%60).."m:"..math.floor(seconds%60).."s] "..entry)
    end
    refresh()
end

function Public.Push_personal_log_entry(player_index, entry)
    if alert_log_personal[player_index] == nil then
        alert_log_personal[player_index] = {}
    elseif #alert_log_personal[player_index] > alert_log_max_entries then
        alert_log_personal[player_index] = {}
    end
    local ticks = game.tick - last_round_reset_tick
    local seconds = math.floor(ticks / 60)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local days = math.floor(hours / 24)
    if (minutes <= 0) then
      increment(alert_log_personal[player_index],"["..math.floor(seconds%60).."s] "..entry)
    elseif (minutes < 60) then
      increment(alert_log_personal[player_index],"["..math.floor(minutes%60).."m:"..math.floor(seconds%60).."s] "..entry)
    elseif (hours < 24) then
      increment(alert_log_personal[player_index],"["..math.floor(hours%60).."h:"..math.floor(minutes%60).."m:"..math.floor(seconds%60).."s] "..entry)
    else
      increment(alert_log_personal[player_index],"["..math.floor(days%60).."d:"..math.floor(hours%60).."h:"..math.floor(minutes%60).."m:"..math.floor(seconds%60).."s] "..entry)
    end
    refresh()
end

local function on_player_joined_game(event)
    --local player = game.players[event.player_index]
    if not alert_log_personal[event.player_index] then
        alert_log_personal[event.player_index] = {}
    end
end

local function on_pre_player_left_game(event)
    if alert_log_delete_on_leave then
        alert_log_personal[event.player_index] = {}
    end
end

local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    if event.element.name == 'close_alert_log' then
        game.players[event.player_index].gui.left.comfy_panel.destroy()
        return
    end
end

comfy_panel_tabs['Alert Log'] = {gui = create_alert_log, admin = false}

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.add(defines.events.on_gui_click, on_gui_click)

return Public
