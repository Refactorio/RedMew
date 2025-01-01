-- This feature replaces placed linked-chests with buffer chests that can automatically trade items

local Buckets = require 'utils.buckets'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Retailer = require 'features.retailer'
local config = require 'config'.market_chest

local floor = math.floor
local b_get = Buckets.get
local b_add = Buckets.add
local b_remove = Buckets.remove
local b_bucket = Buckets.get_bucket
local register_on_object_destroyed = script.register_on_object_destroyed

local relative_frame_name = Gui.uid_name()
local offer_tag_name = Gui.uid_name()
local request_tag_name = Gui.uid_name()
local standard_market_name = 'fish_market'

-- What market provides
local DEFAULT_OFFERS = {
  ['coal'] = 2,
  ['copper-ore'] = 2,
  ['iron-ore'] = 2,
  ['stone'] = 2,
  ['uranium-ore'] = 10,
}
-- What market requests
local DEFAULT_REQUESTS = {
  ['coal'] = 1,
  ['copper-ore'] = 1,
  ['iron-ore'] = 1,
  ['stone'] = 1,
  ['uranium-ore'] = 5,
}

local this = {
  chests = Buckets.new(),
  enabled = config.enabled or false,
  offers = config.offers or DEFAULT_OFFERS,
  requests = config.requests or DEFAULT_REQUESTS,
  relative_gui = {},
}

Global.register(this, function(tbl) this = tbl end)

local function update_entity(entity)
  if not (entity and entity.valid) then
    return
  end

  local data = b_get(this.chests, entity.unit_number)
  local offer, request, ratio = data.offer, data.request, data.ratio
  if not offer or not request or not ratio then
    return
  end

  local inv = entity.get_inventory(defines.inventory.chest)
  if not (inv and inv.valid) then
    return
  end

  local r_count = inv.get_item_count(request)
  local o_count = floor(r_count * ratio)
  if o_count == 0 or r_count == 0 then
    return
  end

  local removed = inv.remove {
    name = request,
    quality = request.quality,
    count = o_count / ratio,
  }
  if removed > 0 then
    local inserted = inv.insert {
      name = offer,
      count = o_count,
    }
    if inserted < o_count then
      inv.insert {
        name = request,
        count = floor((o_count - inserted) / ratio),
      }
    end
  end
end

local function update_market(enabled, price)
  if enabled then
    if not price then
      local chest = Retailer.get_items(standard_market_name)['linked-chest']
      price = chest and chest.price or 3000
    end
    Retailer.set_item(standard_market_name, { name = 'linked-chest', price = price })
  else
    Retailer.remove_item(standard_market_name, 'linked-chest')
  end
end

Event.on_built(function(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.name == 'linked-chest') then
    return
  end

  -- Replace with buffer chest
  local force = entity.force
  local position = entity.position
  local surface = entity.surface
  entity.destroy()

  local chest = surface.create_entity{
    name = 'buffer-chest',
    position = position,
    force = force,
  }

  chest.destructible = false
  b_add(this.chests, chest.unit_number, { entity = chest })
  register_on_object_destroyed(chest)
  update_entity(chest)
  rendering.draw_sprite {
    sprite = 'entity.market',
    surface = chest.surface,
    only_in_alt_mode = true,
    target = {
      entity = chest,
      offset = { 0, 0 },
    },
  }
end)

Event.on_destroyed(function(event)
  local id = event.useful_id or event.entity.unit_number
  local data = b_get(this.chests, id)
  local inv = event.buffer
  if data and inv and inv.valid and inv.get_item_count { name = 'buffer-chest' } > 0 then
    update_entity(data.entity)
    b_remove(this.chests, id)
    inv.remove { name = 'buffer-chest', count = 1 }
    inv.insert { name = 'linked-chest', count = 1 }
  end
end)

Event.add(defines.events.on_tick, function(event)
  if not this.enabled then
    return
  end

  for unit_number, data in pairs(b_bucket(this.chests, event.tick)) do
    local entity = data.entity
    if entity.valid then
      update_entity(entity)
    else
      b_remove(this.chests, unit_number)
    end
  end
end)

Event.add(defines.events.on_gui_opened, function(event)
  if event.gui_type ~= defines.gui_type.entity then
    return
  end

  local old = this.relative_gui[event.player_index]
  if old and old.valid then
    Gui.destroy(old)
  end

  if not this.enabled then
    return
  end

  local entity = event.entity
  if not entity or entity.name ~= 'buffer-chest' then
    return
  end

  local data = b_get(this.chests, entity.unit_number)
  if not data then
    return
  end

  local player = game.get_player(event.player_index)
  local frame = player.gui.relative.add {
    type = 'frame',
    name = relative_frame_name,
    direction = 'vertical',
    anchor = {
      gui = defines.relative_gui_type.container_gui,
      position = defines.relative_gui_position.right,
    }
  }
  Gui.set_style(frame, { horizontally_stretchable = false, padding = 3 })

  local flow = frame.add { type = 'flow', direction = 'horizontal' }
  flow.add { type = 'label', style = 'frame_title' }

  local canvas = frame.add { type = 'frame', style = 'entity_frame', direction = 'vertical' }

  local info = canvas.add { type = 'frame', style = 'deep_frame_in_shallow_frame_for_description', direction = 'vertical' }
  info.add { type = 'label', caption = '[img=entity/market]  Market chest', style = 'tooltip_heading_label_category' }
  info.add { type = 'line', direction = 'horizontal', style = 'tooltip_category_line' }
  local description = info.add { type = 'label', caption = {'market_chest.description'} }
  Gui.set_style(description, { single_line = false, maximal_width = 184 })

  local tables = {}

  canvas.add { type = 'label', style = 'bold_label', caption = 'Requests [img=info]', tooltip = {'market_chest.requests_tooltip'} }
  tables.requests = canvas
    .add { type = 'frame', style = 'slot_button_deep_frame' }
    .add { type = 'table', style = 'filter_slot_table', column_count = 5 }
  for name, value in pairs(this.requests) do
    local button = tables.requests.add {
      type = 'sprite-button',
      sprite = 'item/'..name,
      number = value,
      tooltip = {'market_chest.item_tooltip', value},
      tags = { name = request_tag_name, item = name, id = entity.unit_number },
      toggled = data.request and data.request == name,
    }
    Gui.set_data(button, tables)
  end

  canvas.add { type = 'line', direction = 'horizontal' }
  canvas.add { type = 'label', style = 'bold_label', caption = 'Offers [img=info]', tooltip = {'market_chest.offers_tooltip'} }
  tables.offers = canvas
    .add { type = 'frame', style = 'slot_button_deep_frame' }
    .add { type = 'table', style = 'filter_slot_table', column_count = 5 }
  for name, value in pairs(this.offers) do
    local button = tables.offers.add {
      type = 'sprite-button',
      sprite = 'item/'..name,
      number = value,
      tooltip = {'market_chest.item_tooltip', value},
      tags = { name = offer_tag_name, item = name, id = entity.unit_number },
      toggled = data.offer and data.offer == name,
    }
    Gui.set_data(button, tables)
  end

  this.relative_gui[event.player_index] = frame
end)

Event.add(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local tag = element.tags and element.tags.name
  if not tag or not (tag == request_tag_name or tag == offer_tag_name) then
    return
  end

  local toggled = not element.toggled
  for _, button in pairs(element.parent.children) do
    button.toggled = false
  end
  element.toggled = toggled

  local item_name = element.tags.item
  local data = b_get(this.chests, element.tags.id)

  if tag == request_tag_name then
    data.request = toggled and item_name or nil
  elseif tag == offer_tag_name then
    data.offer = toggled and item_name or nil
  end

  if data.request == data.offer then
    data.request, data.offer = nil, nil
    for _, t in pairs(Gui.get_data(element)) do
      for _, button in pairs(t.children) do
        button.toggled = false
      end
    end
  end

  if data.request and data.offer then
    data.ratio = this.requests[data.request] / this.offers[data.offer]
  else
    data.ratio = nil
  end
end)

Event.on_init(function()
  update_market(config.market_provides_chests, 3000)
end)

local Public = {}

Public.get = function(key)
  return this[key]
end

Public.set = function(key, value)
  this[key] = value
end

Public.distribute_linked_chests = function(enabled, price)
  update_market(enabled, price)
end

Public.spread = function(ticks)
  Buckets.reallocate(this.chests, ticks)
end

return Public
