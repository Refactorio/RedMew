-- NOTE: None of these work as were moved out of the main file in refactoring

-- TO DO
-- Create a table to contain all of these values
-- Create a function in map_layout.lua which iterates through the table and creates each of the markets based on the market groups
-- Replace the retailer set_item things below with the table
-- Get custom sprites working (previously demonstrated by Linaori)
-- Set all of the tomes to have a maximum stack size of 1 (see PR #617)
-- Disable some of the tomes in events.on_market_purchase in biter_lane_wars.lua so that they can only be purchased once and then are disabled for that team

-- Items Market
Retailer.set_item('items', {price = 5, name = 'raw-fish'})
Retailer.set_item('items', {price = 10, name = 'submachine-gun'})
Retailer.set_item('items', {price = 20, name = 'combat-shotgun'})
Retailer.set_item('items', {price = 100, name = 'railgun'})
Retailer.set_item('items', {price = 100, name = 'flamethrower'})
Retailer.set_item('items', {price = 200, name = 'rocket-launcher'})
Retailer.set_item('items', {price = 500, name = 'tank-cannon'})
Retailer.set_item('items', {price = 500, name = 'tank-machine-gun'})
Retailer.set_item('items', {price = 1, name = 'firearm-magazine'})
Retailer.set_item('items', {price = 5, name = 'piercing-rounds-magazine'})
Retailer.set_item('items', {price = 20, name = 'uranium-rounds-magazine'})
Retailer.set_item('items', {price = 10, name = 'shotgun-shell'})
Retailer.set_item('items', {price = 10, name = 'piercing-shotgun-shell'})
Retailer.set_item('items', {price = 10, name = 'railgun-dart'})
Retailer.set_item('items', {price = 10, name = 'flamethrower-ammo'})
Retailer.set_item('items', {price = 10, name = 'rocket'})
Retailer.set_item('items', {price = 10, name = 'explosive-rocket'})
Retailer.set_item('items', {price = 10, name = 'atomic-bomb'})
Retailer.set_item('items', {price = 10, name = 'cannon-shell'})
Retailer.set_item('items', {price = 10, name = 'explosive-cannon-shell'})
Retailer.set_item('items', {price = 10, name = 'explosive-uranium-cannon-shell'})
Retailer.set_item('items', {price = 10, name = 'land-mine'})
Retailer.set_item('items', {price = 10, name = 'grenade'})
Retailer.set_item('items', {price = 50, name = 'cluster-grenade'})
Retailer.set_item('items', {price = 10, name = 'slowdown-capsule'})
Retailer.set_item('items', {price = 10, name = 'poison-capsule'})
-- add more later

-- Creeps Market
-- the names are placeholders, I've tested the sprite paths DO work, no event has been tested yet ~ Jay
Retailer.set_item('creeps', {
     price = 100,
     name = 'small-biter',
     name_label = 'Small Biter',
     sprite="entity/small-biter",
     description="+10 income. Adds 1 small biter to the enemy player team's creeps each wave."
})
Retailer.set_item('creeps', {
     price = 200,
     name = 'medium-biter',
     name_label = 'Medium Biter',
     sprite="entity/medium-biter",
     description="+22 income. Adds 1 medium biter to the enemy player team's creeps each wave."
})
Retailer.set_item('creeps', {
     price = 500,
     name = 'big-biter',
     name_label = 'Big Biter',
     sprite="entity/big-biter",
     description="+60 income. Adds 1 big biter to the enemy player team's creeps each wave."
})
Retailer.set_item('creeps', {
     price = 1000,
     name = 'behemoth-biter',
     name_label = 'Behemoth Biter',
     sprite="entity/behemoth-biter",
     description="+150 income. Adds 1 behemoth biter to the enemy player team's creeps each wave."
})
Retailer.set_item('creeps', {
     price = 150,
     name = 'small-spitter',
     name_label = 'Small Spitter',
     sprite="entity/small-spitter",
     description="+10 income. Adds 1 small spitter to the enemy player team's creeps each wave."
})
Retailer.set_item('creeps', {
     price = 300,
     name = 'medium-spitter',
     name_label = 'Medium Spitter',
     sprite="entity/medium-spitter",
     description="+22 income. Adds 1 medium spitter to the enemy player team's creeps each wave."
})
Retailer.set_item('creeps', {
     price = 750,
     name = 'big-spitter',
     name_label = 'Big Spitter',
     sprite="entity/big-spitter",
     description="+60 income. Adds 1 big spitter to the enemy player team's creeps each wave."
})
Retailer.set_item('creeps', {
     price = 1500,
     name = 'behemoth-spitter',
     name_label = 'Behemoth Spitter',
     sprite="entity/behemoth-spitter",
     description="+180 income. Adds 1 behemoth spitter to the enemy player team's creeps each wave."
})

-- Tome market items
-- some of these will have multiple levels. We could change the price for the second, third, fourth levels by overwriting the set_item when the event is triggered

Retailer.set_item('tomes', {
     price = 3000,
     name = 'hydra',
     name_label = 'Enable Hydra Mode',
     --sprite="fix this",
     description="Enemy team's creeps have a small chance to spawn more biters upon death"
})
Retailer.set_item('tomes', {
     price = 3000,
     name = 'hydra-chance',
     name_label = 'Buff Hydra Chance',
     --sprite="fix this",
     description="Increases the chance that enemy creeps will spawn more biters upon death"
})
Retailer.set_item('tomes', {
     price = 500,
     name = 'movement-speed',
     name_label = '+10% Team Run Speed',
     --sprite="fix this",
     description="Increases the movement speed of all team members by 10%"
})
Retailer.set_item('tomes', {
     price = 500,
     name = 'kill-all',
     name_label = 'Kill All',
     --sprite="fix this",
     description="Kills all creeps in your lane"
})
Retailer.set_item('tomes', {
     price = 500,
     name = 'increase-loot',
     name_label = 'Loot Buff',
     --sprite="fix this",
     description="Increases the amount of coins that biters drop upon death"
})
Retailer.set_item('tomes', {
     price = 10,
     name = 'reveal',
     name_label = 'Reveal Enemy Teams',
     --sprite="fix this",
     description="Removes fog of war from map for 30 seconds allowing you to spy on enemy teams"
})
-- team bullet damage
-- team bullet fire rate
-- biter coin drop chance/quantity
-- hydra mode - enables enemy creeps to spawn extras upon death, make this expensive but low chance
-- hydra rate - enabled when hydra mode enabled. Increases the chances of a biter death spawning another biter for the enemy team
-- Spy. Removes fog from around enemy teams. Cheap. Useful to see how they cope with the waves you're sending.
-- Biter damage. Increases enemy team's creep's damage by 1%
-- Biter health. Increases enemy team's creep's health by 1%

--
Retailer.set_market_group_label('items', 'Items Market')
Retailer.set_market_group_label('creeps', 'Creeps Market')
Retailer.set_market_group_label('tomes', 'Tomes Market')
