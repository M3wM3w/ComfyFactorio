local Event = require 'utils.event'
local Difficulty = require 'modules.difficulty_vote'

local Public = {}

Public.events = {breached_wall = Event.generate_event_name('breached_wall')}

function Public.init_enemy_weapon_damage()
    local data = {
        ['artillery-shell'] = -0.85,
        ['biological'] = 0,
        ['bullet'] = 0,
        ['cannon-shell'] = 0,
        ['capsule'] = 0,
        ['combat-robot-beam'] = 0,
        ['combat-robot-laser'] = 0,
        ['electric'] = 0,
        ['flamethrower'] = 0,
        ['grenade'] = 0,
        ['landmine'] = 0,
        ['laser-turret'] = 0,
        ['melee'] = 0,
        ['railgun'] = 0,
        ['rocket'] = 0,
        ['shotgun-shell'] = 0
    }

    local e = game.forces.enemy

    e.technologies['refined-flammables-1'].researched = true
    e.technologies['refined-flammables-2'].researched = true
    e.technologies['energy-weapons-damage-1'].researched = true

    for k, v in pairs(data) do
        e.set_ammo_damage_modifier(k, v)
    end
end

local function enemy_weapon_damage()
    local e = game.forces.enemy

    local data = {
        ['artillery-shell'] = 0.001,
        ['biological'] = 0.08,
        ['bullet'] = 0.08,
        ['capsule'] = 0.08,
        ['combat-robot-beam'] = 0.08,
        ['combat-robot-laser'] = 0.08,
        ['electric'] = 0.08,
        ['flamethrower'] = 0.08,
        --['grenade'] = 0.08,
        ['landmine'] = 0.08,
        ['laser-turret'] = 0.08,
        ['melee'] = 0.08
        --['railgun'] = 0.08,
        --['rocket'] = 0.08,
        --['shotgun-shell'] = 0.08
    }

    for k, v in pairs(data) do
        local new = Difficulty.get().difficulty_vote_value * v

        local e_old = e.get_ammo_damage_modifier(k)

        e.set_ammo_damage_modifier(k, new + e_old)
    end
end

Event.add(Public.events.breached_wall, enemy_weapon_damage)

--Event.on_nth_tick(54000, enemy_weapon_damage)

return Public
