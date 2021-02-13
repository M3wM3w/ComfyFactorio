local Event = require 'utils.event'
local RPG_Settings = require 'modules.rpg.table'
local WPT = require 'maps.mountain_fortress_v3.table'
local IC_Gui = require 'maps.mountain_fortress_v3.ic.gui'
local IC_Minimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'

local format_number = require 'util'.format_number

local Public = {}
Public.events = {reset_map = Event.generate_event_name('reset_map')}

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local floor = math.floor

local function validate_entity(entity)
    if not (entity and entity.valid) then
        return false
    end

    return true
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

local function create_button(player)
    local b =
        player.gui.top.add(
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'item/dummy-steel-axe',
            tooltip = 'Shows statistics!'
        }
    )
    b.style.minimal_height = 38
    b.style.maximal_height = 38
end

local function create_main_frame(player)
    local label
    local line
    if player.gui.top['wave_defense'] then
        player.gui.top['wave_defense'].visible = true
    end

    local frame = player.gui.top.add({type = 'frame', name = main_frame_name})
    frame.location = {x = 1, y = 40}
    frame.style.minimal_height = 37
    frame.style.maximal_height = 37

    label = frame.add({type = 'label', caption = ' ', name = 'label'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'

    label = frame.add({type = 'label', caption = ' ', name = 'global_pool'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'scrap_mined'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'pickaxe_tier'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'biters_killed'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'landmine'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'flame_turret'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'train_upgrades'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'chest_upgrades'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end

    if not player.gui.top[main_button_name] then
        create_button(player)
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element.valid then
        return
    end

    local name = element.name

    if name == main_button_name then
        local player = game.players[event.player_index]
        if not validate_player(player) then
            return
        end
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Mtn Gui Click')
        if is_spamming then
            return
        end

        local locomotive = WPT.get('locomotive')
        if not validate_entity(locomotive) then
            return
        end

        if not player or not player.valid then
            return
        end
        if not player.surface or not player.surface.valid then
            return
        end
        if player.surface ~= locomotive.surface then
            local minimap = player.gui.left.icw_main_frame
            if minimap and minimap.visible then
                minimap.visible = false
                return
            elseif minimap and not minimap.visible then
                minimap.visible = true
                return
            end
            return
        end
        if player.gui.top[main_frame_name] then
            local info = player.gui.top[main_frame_name]
            local wd = player.gui.top['wave_defense']
            local diff = player.gui.top['difficulty_gui']

            if info and info.visible then
                if wd then
                    wd.visible = false
                end
                if diff then
                    diff.visible = false
                end
                info.visible = false
                return
            elseif wd and not wd.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                if wd then
                    wd.visible = true
                end
                if diff then
                    diff.visible = true
                end
                return
            elseif info and not info.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                if wd then
                    wd.visible = true
                end
                if diff then
                    diff.visible = true
                end
                info.visible = true
                return
            end
        else
            for _, child in pairs(player.gui.left.children) do
                child.destroy()
            end
            create_main_frame(player)
        end
    end
end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local rpg_button = RPG_Settings.draw_main_frame_name
    local rpg_frame = RPG_Settings.main_frame_name
    local rpg_settings = RPG_Settings.settings_frame_name
    local main = WPT.get('locomotive')
    local icw_locomotive = WPT.get('icw_locomotive')
    local wagon_surface = icw_locomotive.surface
    local info = player.gui.top[main_button_name]
    local wd = player.gui.top['wave_defense']
    local rpg_b = player.gui.top[rpg_button]
    local rpg_f = player.gui.screen[rpg_frame]
    local rpg_s = player.gui.screen[rpg_settings]
    local diff = player.gui.top['difficulty_gui']
    local charging = player.gui.top['charging_station']
    local frame = player.gui.top[main_frame_name]

    if info then
        info.tooltip = ({'gui.info_tooltip'})
        info.sprite = 'item/dummy-steel-axe'
    end

    if not main then
        return
    end
    if not main.valid then
        return
    end

    if not wagon_surface then
        return
    end
    if not wagon_surface.valid then
        return
    end

    if player.surface == main.surface then
        local minimap = player.gui.left.icw_main_frame
        if minimap and minimap.visible then
            minimap.visible = false
        end
        if rpg_b and not rpg_b.visible then
            rpg_b.visible = true
        end
        if diff and not diff.visible then
            diff.visible = true
        end
        if wd and not wd.visible then
            wd.visible = true
        end
        if charging and not charging.visible then
            charging.visible = true
        end
        if info then
            info.tooltip = ({'gui.info_tooltip'})
            info.sprite = 'item/dummy-steel-axe'
            info.visible = true
        end
    elseif player.surface == wagon_surface then
        if wd then
            wd.visible = false
        end
        if rpg_b then
            rpg_b.visible = false
        end
        if rpg_f then
            rpg_f.destroy()
        end
        if rpg_s then
            rpg_s.destroy()
        end
        if diff then
            diff.visible = false
        end
        if charging then
            charging.visible = false
        end
        if info then
            info.tooltip = ({'gui.hide_minimap'})
            info.sprite = 'utility/map'
            info.visible = true
        end
        if player.gui.top[main_frame_name] then
            if frame then
                frame.visible = false
                return
            end
        end
    else
        if info and info.visible then
            info.visible = false
        end
    end
end

local function enable_guis(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local rpg_button = RPG_Settings.draw_main_frame_name
    local info = player.gui.top[main_button_name]
    local wd = player.gui.top['wave_defense']
    local rpg_b = player.gui.top[rpg_button]
    local diff = player.gui.top['difficulty_gui']
    local charging = player.gui.top['charging_station']

    IC_Gui.remove_toolbar(player)
    IC_Minimap.toggle_button(player)

    if info then
        info.tooltip = ({'gui.info_tooltip'})
        info.sprite = 'item/dummy-steel-axe'
    end

    local minimap = player.gui.left.icw_main_frame
    if minimap and minimap.visible then
        minimap.visible = false
    end
    if rpg_b and not rpg_b.visible then
        rpg_b.visible = true
    end
    if diff and not diff.visible then
        diff.visible = true
    end
    if wd and not wd.visible then
        wd.visible = true
    end
    if charging and not charging.visible then
        charging.visible = true
    end
    if info then
        info.tooltip = ({'gui.info_tooltip'})
        info.sprite = 'item/dummy-steel-axe'
        info.visible = true
    end
end

function Public.update_gui(player)
    if not validate_player(player) then
        return
    end

    if not player.gui.top[main_frame_name] then
        return
    end

    if not player.gui.top[main_frame_name].visible then
        return
    end
    local gui = player.gui.top[main_frame_name]

    local rpg_extra = RPG_Settings.get('rpg_extra')
    local mined_scrap = WPT.get('mined_scrap')
    local biters_killed = WPT.get('biters_killed')
    local upgrades = WPT.get('upgrades')
    local train_upgrades = WPT.get('train_upgrades')
    local chest_limit_outside_upgrades = WPT.get('chest_limit_outside_upgrades')

    if rpg_extra.global_pool == 0 then
        gui.global_pool.caption = 'XP: 0'
        gui.global_pool.tooltip = ({'gui.global_pool_tooltip'})
    elseif rpg_extra.global_pool >= 0 then
        gui.global_pool.caption = 'XP: ' .. format_number(floor(rpg_extra.global_pool), true)
        gui.global_pool.tooltip = ({'gui.global_pool_amount', floor(rpg_extra.global_pool)})
    end

    gui.scrap_mined.caption = ' [img=entity.tree-01][img=entity.rock-huge]: ' .. format_number(mined_scrap, true)
    gui.scrap_mined.tooltip = ({'gui.amount_harvested'})

    local pickaxe_tiers = WPT.pickaxe_upgrades
    local tier = WPT.get('pickaxe_tier')
    local pick_tier = pickaxe_tiers[tier]
    local speed = math.round((player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100)

    gui.pickaxe_tier.caption = ' [img=item.dummy-steel-axe]: ' .. pick_tier .. ' (' .. tier .. ')'
    gui.pickaxe_tier.tooltip = ({'gui.current_pickaxe_tier', pick_tier, speed})

    gui.biters_killed.caption = ' [img=entity.small-biter]: ' .. format_number(biters_killed, true)
    gui.biters_killed.tooltip = ({'gui.biters_killed'})

    gui.landmine.caption = ' [img=entity.land-mine]: ' .. format_number(upgrades.landmine.built, true) .. ' / ' .. format_number(upgrades.landmine.limit, true)
    gui.landmine.tooltip = ({'gui.land_mine_placed'})

    gui.flame_turret.caption =
        ' [img=entity.flamethrower-turret]: ' .. format_number(upgrades.flame_turret.built, true) .. ' / ' .. format_number(upgrades.flame_turret.limit, true)
    gui.flame_turret.tooltip = ({'gui.flamethrowers_placed'})

    gui.train_upgrades.caption = ' [img=entity.locomotive]: ' .. format_number(train_upgrades, true)
    gui.train_upgrades.tooltip = ({'gui.train_upgrades'})

    gui.chest_upgrades.caption = ' [img=entity.steel-chest]: ' .. format_number(chest_limit_outside_upgrades, true)
    gui.chest_upgrades.tooltip = ({'gui.chest_placed'})
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(Public.events.reset_map, enable_guis)

return Public
