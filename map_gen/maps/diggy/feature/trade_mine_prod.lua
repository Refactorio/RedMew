--[[
  Disables mining productivity technology and adds 2 items in market:
  1. mining-productivity-plus
  2. mining-productivity-minus
  to buy mining productivity increase/decrease. Cost = 2500 * L.
]]

local Event = require 'utils.event'
local Global = require 'utils.global'
local Retailer = require 'features.retailer'

local mining_productivity_plus = 'mining-productivity-plus'
local mining_productivity_minus = 'mining-productivity-minus'

local mining_productivity = {
  level = 0,
  upkeep = 2500,
}

Global.register(mining_productivity, function(tbl) mining_productivity = tbl end)

local this = {}

local function update_mining_prod(market, level)
  -- Mining prod plus item
  Retailer.set_item(market, {
    name = mining_productivity_plus,
    name_label = {'diggy.mining_productivity_item', level + 1},
    description = {'diggy.mining_productivity_plus'},
    sprite = 'technology/mining-productivity-1',
    type = 'technology',
    price = mining_productivity.upkeep * (level + 1),
    stack_limit = 1,
  })
  -- Mining prod minus item
  Retailer.set_item(market, {
    name = mining_productivity_minus,
    name_label = {'diggy.mining_productivity_item', level - 1},
    description = {'diggy.mining_productivity_minus'},
    sprite = 'technology/mining-productivity-1',
    type = 'technology',
    price = mining_productivity.upkeep * level,
    disabled = (level < 1),
    stack_limit = 1,
  })
end

function this.register(config)
  mining_productivity.level = config.level or mining_productivity.level
  mining_productivity.upkeep = config.upkeep or mining_productivity.upkeep

  Event.add(Retailer.events.on_market_purchase, function(event)
    local name = event.item and event.item.name
    local market = event.group_name
    local force = event.player and event.player.force

    if not market or not force then
      return
    end

    if name == mining_productivity_plus then
      mining_productivity.level = mining_productivity.level + 1
      update_mining_prod(market, mining_productivity.level)
      force.mining_drill_productivity_bonus = mining_productivity.level * 0.1

    elseif name == mining_productivity_minus then
      mining_productivity.level = mining_productivity.level - 1
      update_mining_prod(market, mining_productivity.level)
      force.mining_drill_productivity_bonus = mining_productivity.level * 0.1
    end
  end)
end

function this.on_init()
  game.forces.player.mining_drill_productivity_bonus = mining_productivity.level * 0.1
  update_mining_prod('player', mining_productivity.level)

  local techs = game.forces.player.technologies
  techs['mining-productivity-1'].enabled = false
  techs['mining-productivity-2'].enabled = false
  techs['mining-productivity-3'].enabled = false
  techs['mining-productivity-4'].enabled = false
end

return this