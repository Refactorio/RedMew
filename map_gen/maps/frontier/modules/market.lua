local math = require 'utils.math'
local PriceRaffle = require 'features.price_raffle'
local Table = require 'utils.table'
local Public = require 'map_gen.maps.frontier.shared.core'
local math_ceil = math.ceil
local math_clamp = math.clamp
local math_min = math.min
local math_random = math.random
local math_sqrt = math.sqrt

local Market = {}

Market.market_items = {}
Market.cheap_items = {}
Market.expensive_items = {}

do
  local this = Public.get()
  local market_items = PriceRaffle.get_items_worth()
  for k, _ in pairs(this.banned_items) do
    market_items[k] = nil
  end
  market_items['car'] = 64
  market_items['tank-cannon'] = 2048
  market_items['tank-machine-gun'] = 1024
  market_items['light-armor'] = 16
  market_items['heavy-armor'] = 32
  market_items['modular-armor'] = 64
  for k, v in pairs(market_items) do
    if v > 127 then
      Market.expensive_items[k] = v
    else
      Market.cheap_items[k] = v
    end
  end
  Market.market_items = market_items
end

function Market.spawn_exchange_market(position)
  local this = Public.get()
  if position.x < this.left_boundary * 32 + this.wall_width then
    return
  end

  if position.y > this.height * 16 - 12 or position.y < -this.height * 16 + 12 then
    return
  end

  local surface = Public.surface()
  local market = surface.create_entity {
    name = 'market',
    position = position,
    force = 'neutral',
    create_build_effect_smoke = true,
    move_stuck_players = true,
  }
  market.minable_flag = false
  market.destructible = false

  local offers_count = 10 + math_random(10)
  local max_attempts = 10

  local most_expensive_item = { value = 0 }
  local unlocked_items = PriceRaffle.get_unlocked_item_names()
  for _ = 1, offers_count do
    local inserted = false
    local expensive = Table.get_random_dictionary_entry(Market.expensive_items, true)
    for _ = 1, max_attempts do
      local cheap = unlocked_items[math_random(#unlocked_items)]
      if cheap and expensive then
        local cheap_value = Market.market_items[cheap]
        local expensive_value = Market.market_items[expensive]
        local price = expensive_value / cheap_value
        local nerf = Public.PROD_PENALTY * math_clamp(math_sqrt(this.max_distance / (position.x * 10)), 1, 4.2) * (1 + math_random()) -- 1.4 = productivity, + some distance scaling. Further ) better offers
        price = math_min(math_ceil(price * nerf), 2^16-1)
        local stack_size = prototypes.item[cheap].stack_size
        if price / stack_size < 80 then
          market.add_market_item {
            offer = { type = 'give-item', item = expensive, count = 1 },
            price = {{ name = cheap, type = 'item', amount = price }},
          }
          if expensive_value > most_expensive_item.value then
            most_expensive_item.name = expensive
            most_expensive_item.value = expensive_value
          end
          inserted = true
          break
        end
      end
    end
    if not inserted then
      for _ = 1, max_attempts do
        local cheap = Table.get_random_dictionary_entry(Market.expensive_items, true)
        if cheap and expensive and cheap ~= expensive then
          local cheap_value = Market.market_items[cheap]
          local expensive_value = Market.market_items[expensive]
          local price = expensive_value / cheap_value
          local nerf = Public.PROD_PENALTY * math_clamp(math_sqrt(this.max_distance / (position.x * 10)), 1, 4) * (1 + math_random()) -- 1.4 = productivity, + some distance scaling. Further ) better offers
          price = math_min(math_ceil(price * nerf), 2^16-1)
          local stack_size = prototypes.item[cheap].stack_size
          if price / stack_size < 50 then
            market.add_market_item {
              offer = { type = 'give-item', item = expensive, count = 1 },
              price = {{ name = cheap, type = 'item', amount = price }},
            }
            if expensive_value > most_expensive_item.value then
              most_expensive_item.name = expensive
              most_expensive_item.value = expensive_value
            end
            break
          end
        end
      end
    end
  end

  if most_expensive_item.name then
    local icon_offset = { 0, 0 }
    local icon_scale = 1
    rendering.draw_sprite {
      sprite = 'utility/entity_info_dark_background',
      surface = surface,
      target = {
        entity = market,
        offset = icon_offset,
        position = market.position,
      },
      x_scale = icon_scale * 2,
      y_scale = icon_scale * 2,
      only_in_alt_mode = true
    }
    rendering.draw_sprite {
      sprite = 'item/' .. most_expensive_item.name,
      surface = surface,
      target = {
        entity = market,
        offset = icon_offset,
        position = market.position,
      },
      x_scale = icon_scale,
      y_scale = icon_scale,
      only_in_alt_mode = true
    }
  end
end

return Market
