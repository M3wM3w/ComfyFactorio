local Public = {}

local shuffle = table.shuffle_table
local insert = table.insert
local random = math.random

local item_worths = {
    ['wooden-chest'] = 2,
    ['iron-chest'] = 8,
    ['steel-chest'] = 32,
    ['storage-tank'] = 64,
    ['transport-belt'] = 2,
    ['fast-transport-belt'] = 16,
    ['express-transport-belt'] = 64,
    ['underground-belt'] = 8,
    ['fast-underground-belt'] = 64,
    ['express-underground-belt'] = 256,
    ['splitter'] = 16,
    ['fast-splitter'] = 64,
    ['express-splitter'] = 256,
    ['loader'] = 128,
    ['fast-loader'] = 256,
    ['express-loader'] = 1024,
    ['burner-inserter'] = 2,
    ['inserter'] = 4,
    ['long-handed-inserter'] = 8,
    ['fast-inserter'] = 16,
    ['filter-inserter'] = 32,
    ['stack-inserter'] = 128,
    ['stack-filter-inserter'] = 160,
    ['small-electric-pole'] = 2,
    ['medium-electric-pole'] = 32,
    ['big-electric-pole'] = 64,
    ['substation'] = 256,
    ['pipe'] = 1,
    ['pipe-to-ground'] = 8,
    ['pump'] = 32,
    ['rail'] = 4,
    ['train-stop'] = 64,
    ['rail-signal'] = 8,
    ['rail-chain-signal'] = 8,
    ['locomotive'] = 512,
    ['cargo-wagon'] = 256,
    ['fluid-wagon'] = 256,
    ['artillery-wagon'] = 16384,
    ['car'] = 128,
    ['tank'] = 4096,
    ['logistic-robot'] = 256,
    ['construction-robot'] = 256,
    ['logistic-chest-active-provider'] = 256,
    ['logistic-chest-passive-provider'] = 256,
    ['logistic-chest-storage'] = 256,
    ['logistic-chest-buffer'] = 512,
    ['logistic-chest-requester'] = 512,
    ['roboport'] = 2048,
    ['small-lamp'] = 4,
    ['red-wire'] = 4,
    ['green-wire'] = 4,
    ['arithmetic-combinator'] = 16,
    ['decider-combinator'] = 16,
    ['constant-combinator'] = 8,
    ['power-switch'] = 16,
    ['programmable-speaker'] = 16,
    ['stone-brick'] = 2,
    ['concrete'] = 1,
    ['hazard-concrete'] = 1,
    ['refined-concrete'] = 2,
    ['refined-hazard-concrete'] = 2,
    ['cliff-explosives'] = 32,
    ['repair-pack'] = 8,
    ['boiler'] = 8,
    ['steam-engine'] = 32,
    ['solar-panel'] = 64,
    ['accumulator'] = 64,
    ['nuclear-reactor'] = 8192,
    ['heat-pipe'] = 128,
    ['heat-exchanger'] = 256,
    ['steam-turbine'] = 256,
    ['burner-mining-drill'] = 8,
    ['electric-mining-drill'] = 32,
    ['offshore-pump'] = 16,
    ['pumpjack'] = 64,
    ['stone-furnace'] = 4,
    ['steel-furnace'] = 64,
    ['electric-furnace'] = 256,
    ['assembling-machine-1'] = 32,
    ['assembling-machine-2'] = 128,
    ['assembling-machine-3'] = 512,
    ['oil-refinery'] = 256,
    ['chemical-plant'] = 128,
    ['centrifuge'] = 2048,
    ['lab'] = 64,
    ['beacon'] = 512,
    ['speed-module'] = 128,
    ['speed-module-2'] = 512,
    ['speed-module-3'] = 2048,
    ['effectivity-module'] = 128,
    ['effectivity-module-2'] = 512,
    ['effectivity-module-3'] = 2048,
    ['productivity-module'] = 128,
    ['productivity-module-2'] = 512,
    ['productivity-module-3'] = 2048,
    ['wood'] = 1,
    ['raw-fish'] = 10,
    ['iron-plate'] = 1,
    ['copper-plate'] = 1,
    ['solid-fuel'] = 16,
    ['steel-plate'] = 8,
    ['plastic-bar'] = 8,
    ['sulfur'] = 4,
    ['battery'] = 16,
    ['explosives'] = 3,
    ['crude-oil-barrel'] = 8,
    ['heavy-oil-barrel'] = 16,
    ['light-oil-barrel'] = 16,
    ['lubricant-barrel'] = 16,
    ['petroleum-gas-barrel'] = 16,
    ['sulfuric-acid-barrel'] = 16,
    ['water-barrel'] = 4,
    ['copper-cable'] = 1,
    ['iron-stick'] = 1,
    ['iron-gear-wheel'] = 2,
    ['empty-barrel'] = 4,
    ['electronic-circuit'] = 4,
    ['advanced-circuit'] = 16,
    ['processing-unit'] = 128,
    ['engine-unit'] = 8,
    ['electric-engine-unit'] = 64,
    ['flying-robot-frame'] = 128,
    ['satellite'] = 32768,
    ['rocket-control-unit'] = 256,
    ['low-density-structure'] = 64,
    ['rocket-fuel'] = 256,
    ['nuclear-fuel'] = 1024,
    ['uranium-235'] = 1024,
    ['uranium-238'] = 32,
    ['uranium-fuel-cell'] = 128,
    ['used-up-uranium-fuel-cell'] = 8,
    ['automation-science-pack'] = 4,
    ['logistic-science-pack'] = 16,
    ['military-science-pack'] = 64,
    ['chemical-science-pack'] = 128,
    ['production-science-pack'] = 256,
    ['utility-science-pack'] = 256,
    ['space-science-pack'] = 512,
    ['pistol'] = 10,
    ['submachine-gun'] = 32,
    ['shotgun'] = 16,
    ['combat-shotgun'] = 256,
    ['rocket-launcher'] = 128,
    ['flamethrower'] = 512,
    ['land-mine'] = 2,
    ['landfill'] = 20,
    ['firearm-magazine'] = 4,
    ['piercing-rounds-magazine'] = 8,
    ['uranium-rounds-magazine'] = 64,
    ['shotgun-shell'] = 4,
    ['piercing-shotgun-shell'] = 16,
    ['cannon-shell'] = 8,
    ['explosive-cannon-shell'] = 16,
    ['uranium-cannon-shell'] = 64,
    ['explosive-uranium-cannon-shell'] = 64,
    ['artillery-shell'] = 128,
    ['rocket'] = 6,
    ['explosive-rocket'] = 8,
    ['atomic-bomb'] = 8192,
    ['flamethrower-ammo'] = 32,
    ['grenade'] = 16,
    ['cluster-grenade'] = 64,
    ['poison-capsule'] = 32,
    ['slowdown-capsule'] = 16,
    ['defender-capsule'] = 48,
    ['distractor-capsule'] = 256,
    ['destroyer-capsule'] = 1024,
    ['light-armor'] = 50,
    ['heavy-armor'] = 250,
    ['modular-armor'] = 512,
    ['power-armor'] = 2048,
    ['power-armor-mk2'] = 32768,
    ['solar-panel-equipment'] = 256,
    ['fusion-reactor-equipment'] = 15000,
    ['energy-shield-equipment'] = 128,
    ['energy-shield-mk2-equipment'] = 2048,
    ['battery-equipment'] = 96,
    ['battery-mk2-equipment'] = 2048,
    ['personal-laser-defense-equipment'] = 1500,
    ['discharge-defense-equipment'] = 2048,
    ['discharge-defense-remote'] = 32,
    ['belt-immunity-equipment'] = 128,
    ['exoskeleton-equipment'] = 1500,
    ['personal-roboport-equipment'] = 512,
    ['personal-roboport-mk2-equipment'] = 4096,
    ['night-vision-equipment'] = 256,
    ['stone-wall'] = 5,
    ['gate'] = 16,
    ['gun-turret'] = 64,
    ['laser-turret'] = 1024,
    ['flamethrower-turret'] = 2048,
    ['artillery-turret'] = 1024,
    ['radar'] = 32,
    ['rocket-silo'] = 65536
}

local item_names = {}
for k, _ in pairs(item_worths) do
    insert(item_names, k)
end
local size_of_item_names = #item_names

local function get_raffle_keys()
    local raffle_keys = {}
    for i = 1, size_of_item_names, 1 do
        raffle_keys[i] = i
    end
    shuffle(raffle_keys)
    return raffle_keys
end

local function roll_item_stack(entity, wave)
    if wave <= 0 then
        return
    end
    local raffle_keys = get_raffle_keys()
    local item_name = false
    local item_worth = 0
    for _, index in pairs(raffle_keys) do
        item_name = item_names[index]
        item_worth = item_worths[item_name]
        if item_worth <= wave then
            break
        end
    end

    local stack_size = game.item_prototypes[item_name].stack_size

    local item_count = 1

    for c = 1, random(1, stack_size), 1 do
        local price = c * item_worth
        if price <= wave then
            item_count = c
        else
            break
        end
    end

    entity.surface.spill_item_stack(entity.position, {name = item_name, count = random(1, item_count)}, true)

    return {name = item_name, count = item_count}
end

function Public.drop_loot(entity, wave)
    local returned_loot
    if wave >= 1 and wave < 50 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 50 and wave < 100 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 100 and wave < 200 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 100 and wave < 400 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 400 and wave < 800 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 800 and wave < 1200 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 1200 and wave < 2000 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 2000 and wave < 3000 then
        returned_loot = roll_item_stack(entity, wave)
    elseif wave >= 3000 and wave < 4000 then
        returned_loot = roll_item_stack(entity, wave)
    end
    return returned_loot
end

return Public
