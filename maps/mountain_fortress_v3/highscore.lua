local Event = require 'utils.event'
local Global = require 'utils.global'
local Server = require 'utils.server'
local Token = require 'utils.token'
local Tabs = require 'comfy_panel.main'
local Score = require 'comfy_panel.score'
local WPT = require 'maps.mountain_fortress_v3.table'
local WD = require 'modules.wave_defense.table'
local Core = require 'utils.core'

local score_dataset = 'highscores'
local score_key = 'mountain_fortress_v3_scores'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}
local insert = table.insert
local random = math.random
local this = {
    score_table = {},
    sort_by = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local biters = {
    'small-biter',
    'medium-biter',
    'big-biter',
    'behemoth-biter',
    'small-spitter',
    'medium-spitter',
    'big-spitter',
    'behemoth-spitter'
}

local function get_lowest(tbl, column_name)
    local t = {}
    for _, value in pairs(tbl) do
        insert(t, value[column_name])
    end
    table.sort(
        t,
        function(a, b)
            return a < b
        end
    )
    if t[1] then
        return t[1]
    else
        return 100
    end
end

local function get_highest(tbl, column_name)
    local t = {}
    for _, value in pairs(tbl) do
        insert(t, value[column_name])
    end
    table.sort(
        t,
        function(a, b)
            return a > b
        end
    )
    if t[1] then
        return t[1]
    else
        return 10
    end
end

local function contains(tbl, key, string, rtn)
    for index, value in pairs(tbl) do
        if value[key] and value[key] == string then
            if rtn then
                return index
            else
                return true
            end
        end
    end
    return false
end

local function sort_list(method, column_name, score_list)
    local comparators = {
        ['ascending'] = function(a, b)
            return a[column_name] < b[column_name]
        end,
        ['descending'] = function(a, b)
            return a[column_name] > b[column_name]
        end
    }
    table.sort(score_list, comparators[method])
    return score_list
end

local function get_sorted_list(column_name, score_list)
    local sl = {}
    local i = 0
    score_list = sort_list('descending', column_name, score_list)

    for key, player in ipairs(score_list) do
        sl[key] = player
        i = i + 1
        if i == 20 then
            return sl
        end
    end
    return sl
end

local function get_mvps()
    local new_score_table = Score.get_table().score_table
    if not new_score_table['player'] then
        return false
    end
    local old_score = this.score_table['player']
    local score = new_score_table['player']
    local score_list = {}
    local mvp = old_score.players

    for _, p in pairs(game.players) do
        if score.players[p.name] then
            local killscore = 0
            if score.players[p.name].killscore then
                killscore = score.players[p.name].killscore
            end
            local built_entities = 0
            if score.players[p.name].built_entities then
                built_entities = score.players[p.name].built_entities
            end
            local mined_entities = 0
            if score.players[p.name].mined_entities then
                mined_entities = score.players[p.name].mined_entities
            end
            local deaths = 0
            if score.players[p.name].deaths then
                deaths = score.players[p.name].deaths
            end

            insert(score_list, {name = p.name, killscore = killscore, built_entities = built_entities, deaths = deaths, mined_entities = mined_entities})
        end
    end

    local score_list_k = get_sorted_list('killscore', score_list)
    local score_list_m = get_sorted_list('mined_entities', score_list)
    local score_list_b = get_sorted_list('built_entities', score_list)
    local score_list_d = get_sorted_list('deaths', score_list)
    local lowest_k = get_lowest(mvp, 'killscore')
    local lowest_m = get_lowest(mvp, 'mined_entities')
    local lowest_b = get_lowest(mvp, 'built_entities')
    local highest_d = get_highest(mvp, 'deaths')

    for i = 1, 30 do
        local kill_list = score_list_k[i]
        local mined_list = score_list_m[i]
        local build_list = score_list_b[i]
        local death_list = score_list_d[i]

        if kill_list then
            if not contains(mvp, 'name', kill_list.name) then
                if kill_list.killscore >= lowest_k then
                    if death_list and death_list.deaths < highest_d then
                        insert(
                            mvp,
                            {
                                name = kill_list.name,
                                killscore = kill_list.killscore,
                                deaths = death_list.deaths
                            }
                        )
                    else
                        insert(
                            mvp,
                            {
                                name = kill_list.name,
                                killscore = kill_list.killscore
                            }
                        )
                    end
                end
            else
                local index = contains(mvp, 'name', kill_list.name, true)
                if index then
                    if mvp[index].killscore and kill_list.killscore > mvp[index].killscore then
                        mvp[index].killscore = kill_list.killscore
                    end
                    if death_list and mvp[index].deaths and death_list.deaths < mvp[index].deaths then
                        mvp[index].deaths = death_list.deaths
                    end
                end
            end
        end
        if mined_list then
            if not contains(mvp, 'name', mined_list.name) then
                if mined_list.mined_entities >= lowest_m then
                    if death_list and death_list.deaths < highest_d then
                        insert(
                            mvp,
                            {
                                name = mined_list.name,
                                mined_entities = mined_list.mined_entities,
                                deaths = death_list.deaths
                            }
                        )
                    else
                        insert(
                            mvp,
                            {
                                name = mined_list.name,
                                mined_entities = mined_list.mined_entities
                            }
                        )
                    end
                end
            else
                local index = contains(mvp, 'name', mined_list.name, true)
                if index then
                    if mvp[index].mined_entities and mined_list.mined_entities > mvp[index].mined_entities then
                        mvp[index].mined_entities = mined_list.mined_entities
                    end
                    if death_list and mvp[index].deaths and death_list.deaths < mvp[index].deaths then
                        mvp[index].deaths = death_list.deaths
                    end
                end
            end
        end
        if build_list then
            if not contains(mvp, 'name', build_list.name) then
                if build_list.built_entities >= lowest_b then
                    if death_list and death_list.deaths < highest_d then
                        insert(
                            mvp,
                            {
                                name = build_list.name,
                                built_entities = build_list.built_entities,
                                deaths = death_list.deaths
                            }
                        )
                    else
                        insert(
                            mvp,
                            {
                                name = build_list.name,
                                built_entities = build_list.built_entities
                            }
                        )
                    end
                end
            else
                local index = contains(mvp, 'name', build_list.name, true)
                if index then
                    if mvp[index].built_entities and build_list.built_entities > mvp[index].built_entities then
                        mvp[index].built_entities = build_list.built_entities
                    end
                    if death_list and mvp[index].deaths and death_list.deaths < mvp[index].deaths then
                        mvp[index].deaths = death_list.deaths
                    end
                end
            end
        end

        if mvp['GodGamer'] then
            mvp['GodGamer'] = nil
        end
    end

    if #mvp <= 0 then
        return false
    end

    return mvp
end

local function get_total_biter_killcount(force)
    local count = 0
    for _, biter in pairs(biters) do
        count = count + force.kill_count_statistics.get_input_count(biter)
    end
    return count
end

local function write_additional_stats(key, difficulty)
    local player = game.forces.player
    local new_breached_zone = WPT.get('breached_wall')
    local new_wave_number = WD.get('wave_number')
    local new_biters_killed = get_total_biter_killcount(player)
    local new_rockets_launched = player.rockets_launched
    local new_total_time = game.ticks_played
    local t = this.score_table['player']

    if this.score_table['player'] then
        local old_wave = this.score_table['player'].wave_number
        local old_biters_killed = this.score_table['player'].biters_killed
        local old_breached_zone = this.score_table['player'].breached_zone
        local old_rockets_launched = this.score_table['player'].rockets_launched
        local old_total_time = this.score_table['player'].total_time
        local old_players = this.score_table['player'].players
        if new_wave_number > old_wave then
            t.wave_number = new_wave_number
        else
            t.wave_number = old_wave
        end
        if new_biters_killed > old_biters_killed then
            t.biters_killed = new_biters_killed
        else
            t.biters_killed = old_biters_killed
        end
        if new_breached_zone > old_breached_zone then
            t.breached_zone = new_breached_zone
        else
            t.breached_zone = old_breached_zone
        end
        if new_rockets_launched > old_rockets_launched then
            t.rockets_launched = new_rockets_launched
        else
            t.rockets_launched = old_rockets_launched
        end
        if new_total_time > old_total_time then
            t.total_time = new_total_time
        else
            t.total_time = old_total_time
        end

        if difficulty then
            t.difficulty = difficulty
        end

        local new_stats = get_mvps()
        if new_stats then
            t.players = new_stats
        else
            t.players = old_players
        end
    end

    this.score_table['player'] = t

    if key then
        set_data(score_dataset, key, t)
    end
end

local get_scores =
    Token.register(
    function(data)
        local value = data.value
        if not this.score_table['player'] then
            this.score_table['player'] = {}
        end

        this.score_table['player'] = value
    end
)

function Public.get_scores()
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        if is_game_modded() then
            score_key = 'mountain_fortress_v3_scores_modded'
        end
        try_get_data(score_dataset, score_key, get_scores)
    end
end

function Public.set_scores(difficulty)
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        if is_game_modded() then
            score_key = 'mountain_fortress_v3_scores_modded'
        end
        write_additional_stats(score_key, difficulty)
    end
end

local function on_init()
    local secs = Server.get_current_time()
    if not secs then
        write_additional_stats()
        return
    end
end

local sorting_symbol = {ascending = '▲', descending = '▼'}

local function get_score_list()
    local score_force = this.score_table['player']
    local score_list = {}
    if not score_force then
        score_list[#score_list + 1] = {
            name = 'Nothing here yet',
            killscore = 0,
            deaths = 0,
            built_entities = 0,
            mined_entities = 0
        }
        return score_list
    end

    for p, _ in pairs(score_force.players) do
        local score = score_force.players[p]
        insert(
            score_list,
            {
                name = score and score.name,
                killscore = score and score.killscore or 0,
                deaths = score and score.deaths or 20,
                built_entities = score and score.built_entities or 0,
                mined_entities = score and score.mined_entities or 0
            }
        )
    end
    return score_list
end

local function add_global_stats(frame)
    local score = this.score_table['player']

    local t = frame.add {type = 'table', column_count = 6}

    local l = t.add {type = 'label', caption = 'Rockets: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 175, g = 75, b = 255}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = score.rockets_launched}
    l.style.font = 'heading-2'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = 'Dead bugs: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 0.90, g = 0.3, b = 0.3}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = score.biters_killed}
    l.style.font = 'heading-2'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = 'Breached zones: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 0, g = 128, b = 0}
    l.style.minimal_width = 100
    local zone = score.breached_zone - 1
    if score.breached_zone == 0 then
        zone = 0
    end
    local l = t.add {type = 'label', caption = zone}
    l.style.font = 'heading-2'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = 'Highest wave: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 128, g = 128, b = 0.9}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = score.wave_number}
    l.style.font = 'heading-2'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = 'Last run total time: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 0.9, g = 128, b = 128}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = Core.format_time(score.total_time)}
    l.style.font = 'heading-2'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 100
end

local show_score = (function(player, frame)
    frame.clear()

    local flow = frame.add {type = 'flow'}
    local sFlow = flow.style
    sFlow.horizontally_stretchable = true
    sFlow.horizontal_align = 'center'
    sFlow.vertical_align = 'center'

    local stats = flow.add {type = 'label', caption = 'Highest score so far:'}
    local s_stats = stats.style
    s_stats.font = 'heading-1'
    s_stats.font_color = {r = 0.98, g = 0.66, b = 0.22}
    s_stats.horizontal_align = 'center'
    s_stats.vertical_align = 'center'

    -- Global stats : rockets, biters kills
    add_global_stats(frame)

    -- Separator
    local line = frame.add {type = 'line'}
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    -- Score per player
    local t = frame.add {type = 'table', column_count = 5}

    -- Score headers
    local headers = {
        {name = 'score_player', caption = 'Player'},
        {column = 'killscore', name = 'score_killscore', caption = 'Killscore'},
        {column = 'deaths', name = 'score_deaths', caption = 'Deaths'},
        {column = 'built_entities', name = 'score_built_entities', caption = 'Built structures'},
        {column = 'mined_entities', name = 'score_mined_entities', caption = 'Mined entities'}
    }

    local sorting_pref = this.sort_by[player.index]
    for _, header in ipairs(headers) do
        local cap = header.caption

        -- Add sorting symbol if any
        if header.column and sorting_pref.column == header.column then
            local symbol = sorting_symbol[sorting_pref.method]
            cap = symbol .. cap
        end

        -- Header
        local label =
            t.add {
            type = 'label',
            caption = cap,
            name = header.name
        }
        label.style.font = 'default-listbox'
        label.style.font_color = {r = 0.98, g = 0.66, b = 0.22} -- yellow
        label.style.minimal_width = 150
        label.style.horizontal_align = 'right'
    end

    -- Score list
    local score_list = get_score_list()

    score_list = sort_list(sorting_pref.method, sorting_pref.column, score_list)

    -- New pane for scores (while keeping headers at same position)
    local scroll_pane =
        frame.add(
        {
            type = 'scroll-pane',
            name = 'score_scroll_pane',
            direction = 'vertical',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto'
        }
    )
    scroll_pane.style.maximal_height = 400
    local t = scroll_pane.add {type = 'table', column_count = 5}

    -- Score entries
    for _, entry in pairs(score_list) do
        local p
        if not (entry and entry.name) then
            p = {color = {r = random(1, 255), g = random(1, 255), b = random(1, 255)}}
        else
            p = game.players[entry.name]
            if not p then
                p = {color = {r = random(1, 255), g = random(1, 255), b = random(1, 255)}}
            end
        end
        local special_color = {
            r = p.color.r * 0.6 + 0.4,
            g = p.color.g * 0.6 + 0.4,
            b = p.color.b * 0.6 + 0.4,
            a = 1
        }

        local k = entry.killscore > 0 and entry.killscore or 'Not MVP'
        local d = entry.deaths < 10 and entry.deaths or 'Not MVP'
        local b = entry.built_entities > 0 and entry.built_entities or 'Not MVP'
        local m = entry.mined_entities > 0 and entry.mined_entities or 'Not MVP'

        local line = {
            {caption = entry.name, color = special_color},
            {caption = tostring(k)},
            {caption = tostring(d)},
            {caption = tostring(b)},
            {caption = tostring(m)}
        }
        local default_color = {r = 0.9, g = 0.9, b = 0.9}

        for _, column in ipairs(line) do
            local label =
                t.add {
                type = 'label',
                caption = column.caption,
                color = column.color or default_color
            }
            label.style.font = 'default'
            label.style.minimal_width = 150
            label.style.maximal_width = 150
            label.style.horizontal_align = 'right'
        end -- foreach column
    end -- foreach entry
end) -- show_score

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

    local player = game.players[event.element.player_index]
    local frame = Tabs.comfy_panel_get_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'Highscore' then
        return
    end

    local name = event.element.name

    -- Handles click on a score header
    local element_to_column = {
        ['score_killscore'] = 'killscore',
        ['score_deaths'] = 'deaths',
        ['score_built_entities'] = 'built_entities',
        ['score_mined_entities'] = 'mined_entities'
    }
    local column = element_to_column[name]
    if column then
        local sorting_pref = this.sort_by[player.index]
        if sorting_pref.column == column and sorting_pref.method == 'descending' then
            sorting_pref.method = 'ascending'
        else
            sorting_pref.method = 'descending'
            sorting_pref.column = column
        end
        show_score(player, frame)
        return
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not this.sort_by[player.index] then
        this.sort_by[player.index] = {method = 'descending', column = 'killscore'}
    end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
    if this.sort_by[player.index] then
        this.sort_by[player.index] = nil
    end
end

Server.on_data_set_changed(
    score_dataset,
    function(data)
        if data.key == score_key then
            if data.value then
                this.score_table['player'] = data.value
            end
        end
    end
)

comfy_panel_tabs['Highscore'] = {gui = show_score, admin = false, only_server_sided = true}

Event.on_init(on_init)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(Server.events.on_server_started, Public.get_scores)

return Public
