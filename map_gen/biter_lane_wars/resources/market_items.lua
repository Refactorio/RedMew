-- we likely want this just to be a table to send to Retailer to set up the market

Retailer.set_item('items', {price = 5, name = 'raw-fish'})
     Retailer.set_item('items', {price = 10, name = 'steel-axe'})
     Retailer.set_item('items', {price = 10, name = 'submachine-gun'})
     Retailer.set_item('items', {price = 10, name = 'combat-shotgun'})
     Retailer.set_item('items', {price = 10, name = 'railgun'})
     Retailer.set_item('items', {price = 10, name = 'flamethrower'})
     Retailer.set_item('items', {price = 10, name = 'rocket-launcher'})
     Retailer.set_item('items', {price = 10, name = 'tank-cannon'})
     Retailer.set_item('items', {price = 10, name = 'tank-machine-gun'})
     Retailer.set_item('items', {price = 10, name = 'firearm-magazine'})
     Retailer.set_item('items', {price = 10, name = 'piercing-rounds-magazine'})
     Retailer.set_item('items', {price = 10, name = 'uranium-rounds-magazine'})
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
     Retailer.set_item('items', {price = 10, name = 'cluster-grenade'})
     Retailer.set_item('items', {price = 10, name = 'slowdown-capsule'})
     Retailer.set_item('items', {price = 10, name = 'poison-capsule'})
     -- add more later

     -- Creep market items
    Retailer.set_item('creeps', {price = 10, name = 'raw-fish'})
    --local icon = require 'map_gen.presets.biter_lane_wars.assets.big-spitter.png'
    Retailer.set_item('creeps', {price = 5, name = 'grenade', sprite="entity/small-biter"})
    Retailer.set_item('creeps', {price = 5, name = 'poison-capsule', sprite="entity/medium-biter"})
    Retailer.set_item('creeps', {price = 5, name = 'atomic-bomb', sprite="entity/big-biter"})
    Retailer.set_item('creeps', {price = 5, name = 'rocket', sprite="entity/behemoth-biter"})
    Retailer.set_item('creeps', {price = 10, name = 'steel-axe'})
    Retailer.set_item('creeps', {price = 5, name = 'tank-cannon', sprite="entity/small-spitter"})
    Retailer.set_item('creeps', {price = 5, name = 'railgun', sprite="entity/medium-spitter"})
    Retailer.set_item('creeps', {price = 5, name = 'railgun-dart', sprite="entity/big-spitter"})
    Retailer.set_item('creeps', {price = 5, name = 'explosive-uranium-cannon-shell', sprite="entity/behemoth-spitter"})

     -- Tome market items
     Retailer.set_item('tomes', {price = 10, name = 'steel-axe'})

    --
     Retailer.set_market_group_label('items', 'Items Market')
     Retailer.set_market_group_label('creeps', 'Creeps Market')
     Retailer.set_market_group_label('tomes', 'Tomes Market')
