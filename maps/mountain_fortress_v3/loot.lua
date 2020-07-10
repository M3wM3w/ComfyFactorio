local LootRaffle = require 'functions.loot_raffle'

local Public = {}

local blacklist = {
    ['atomic-bomb'] = true,
    ['cargo-wagon'] = true,
    ['locomotive'] = true,
    ['artillery-wagon'] = true,
    ['fluid-wagon'] = true
}

function Public.add(surface, position, chest)
    local budget = 48 + math.abs(position.y) * 1.75
    budget = budget * math.random(25, 175) * 0.01

    if math.random(1, 128) == 1 then
        budget = budget * 4
        chest = 'crash-site-chest-' .. math.random(1, 2)
    end
    if math.random(1, 256) == 1 then
        budget = budget * 4
        chest = 'crash-site-chest-' .. math.random(1, 2)
    end

    budget = math.floor(budget) + 1

    local item_stacks = LootRaffle.roll(budget, 8, blacklist)
    local container = surface.create_entity({name = chest, position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false

    for _ = 1, 3, 1 do
        if math.random(1, 8) == 1 then
            container.insert({name = 'explosives', count = math.random(25, 50)})
        else
            break
        end
    end
end

function Public.add_rare(surface, position, chest, magic)
    local budget = magic * 48 + math.abs(position.y) * 1.75
    budget = budget * math.random(25, 175) * 0.01

    if math.random(1, 128) == 1 then
        budget = budget * 6
        chest = 'crash-site-chest-' .. math.random(1, 2)
    end
    if math.random(1, 128) == 1 then
        budget = budget * 6
        chest = 'crash-site-chest-' .. math.random(1, 2)
    end

    budget = math.floor(budget) + 1

    local item_stacks = LootRaffle.roll(budget, 8, blacklist)
    local container = surface.create_entity({name = chest, position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false

    for _ = 1, 3, 1 do
        if math.random(1, 8) == 1 then
            container.insert({name = 'explosives', count = math.random(25, 50)})
        else
            break
        end
    end
end

return Public
