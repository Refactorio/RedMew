    -- Copyright (c) 2016-2017 SL

    -- This file is part of SL-extended.

    -- SL-extended is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU Affero General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.

    -- SL-extended is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU Affero General Public License for more details.

    -- You should have received a copy of the GNU Affero General Public License
    -- along with SL-extended.  If not, see <http://www.gnu.org/licenses/>.


-- sl_upgradeplanner.lua
-- 20170602
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.

-- Credit:
--  malk0lm & Klonan

require("sl_utils")


function updateUpVisibility(player)
    local visible = global["config-pers"][player.name]["upgrade-planner-active"]
    local upFrame = player.gui.top["sl-extended-frame"]["upgrade-planner-status-frame"]
    upFrame["upgrade-planner-vanilla-radio"].state = not visible
    upFrame["upgrade-planner-up++-radio"].state = visible

    upFrame["upgrade-planner-tree-btn"].style.visible = visible and isHolding("deconstruction-planner", player)
    upFrame["upgrade-planner-rock-btn"].style.visible = visible and isHolding("deconstruction-planner", player)
    upFrame["upgrade-planner-dropped-btn"].style.visible = visible and isHolding("deconstruction-planner", player)
    upFrame["upgrade-planner-turret-btn"].style.visible = visible and isHolding("deconstruction-planner", player)
    upFrame["upgrade-planner-upgrade-btn"].style.visible = visible and isHolding("deconstruction-planner", player)
    upFrame["upgrade-planner-dig-btn"].style.visible = visible and (isHolding("hazard-concrete", player) or isHolding("concrete", player) or isHolding("stone-brick", player))
end

function upgradeplanner_on_gui_click(event)
    local element = event.element
    if not element.valid then
        return
    end
    local player = game.players[event.player_index]

    if element.name == "upgrade-planner-vanilla-radio" then
        global["config-pers"][player.name]["upgrade-planner-active"] = false
        updateUpVisibility(player)
    elseif element.name == "upgrade-planner-up++-radio" then
        global["config-pers"][player.name]["upgrade-planner-active"] = true
        updateUpVisibility(player)
    elseif element.name == "upgrade-planner-tree-btn" then
        guiToggleUpgradePlannerSub(player, "tree")
    elseif element.name == "upgrade-planner-rock-btn" then
        guiToggleUpgradePlannerSub(player, "rock")
    elseif element.name == "upgrade-planner-dropped-btn" then
        guiToggleUpgradePlannerSub(player, "dropped")
    elseif element.name == "upgrade-planner-turret-btn" then
        guiToggleUpgradePlannerSub(player, "turret")
    elseif element.name == "upgrade-planner-upgrade-btn" then
        guiToggleUpgradePlannerSub(player, "upgrade")
    elseif element.name == "upgrade-planner-dig-btn" then
        guiToggleUpgradePlannerSub(player, "dig")
    elseif element.name == "upgrade-planner-edit-button" then
        upGuiOpenFrame(player)
    elseif element.name == "upgrade-planner-apply" then
        guiApply(player)
    elseif element.name == "upgrade-planner-clear-all" then
        guiClearAll(player)
    else
        local type, index = string.match(element.name, "upgrade%-planner%-(%a+)%-(%d+)")
        if type and index then
            if type == "from" or type == "to" then
                guiSetRule(player, type, tonumber(index))
            elseif type == "clear" then
                guiClearRule(player, tonumber(index))
            end
        end
    end
end

function upgradeplanner_player_joined(event)
    local player = game.players[event.player_index] 
    global = global or {}
    
    global["config-tmp"] = global["config-tmp"] or {}
    
    global["config"] = global["config"] or {}
    global["config"][player.name] = global["config"][player.name] or {}

    global["config-pers"] = global["config-pers"] or {}
    global["config-pers"][player.name] = global["config-pers"][player.name] or {}
    global["config-pers"][player.name]["upgrade-planner-active"] = global["config-pers"][player.name]["upgrade-planner-active"] or false
    global["config-pers"][player.name]["tree"] = global["config-pers"][player.name]["tree"] or true
    global["config-pers"][player.name]["rock"] = global["config-pers"][player.name]["rock"] or true
    global["config-pers"][player.name]["dropped"] = global["config-pers"][player.name]["dropped"] or true
    global["config-pers"][player.name]["turret"] = global["config-pers"][player.name]["turret"] or false
    global["config-pers"][player.name]["upgrade"] = global["config-pers"][player.name]["upgrade"] or true
    global["config-pers"][player.name]["dig"] = global["config-pers"][player.name]["dig"] or false

    upInitGui(player)
end

function upgradeplanner_on_marked_for_deconstruction(event)
    -- Acceptable bug: When this upgrade planner is used on an item the entity.last_user will change.
    if not event.player_index or not global["config-pers"][game.players[event.player_index].name]["upgrade-planner-active"] then 
        return
    end
    local player = game.players[event.player_index]
    local upActive = global["config-pers"][player.name]["upgrade-planner-active"]


    if upActive then
        -- ONLY when UP-on. Otherwise the default deconstruction behavior should be applied.
        local e = event.entity
        -- Undo the deconstruction and go ahead with upgrading task.
        e.cancel_deconstruction("player")  -- currently all players are in force players... if player are in other forces this should be changed.

        if isUpgradePlannerSubActive(player,"tree") then
            if removeTree(event) then
                return
            end
        end

        if isUpgradePlannerSubActive(player,"rock") then
            if removeRock(event) then
                return
            end
        end

        if isUpgradePlannerSubActive(player,"dropped") then
            if pickupItemOnGround(event) then
                return
            end
        end

        if isUpgradePlannerSubActive(player, "turret") then
            if pickupTurret(event) then
                return
            end
        end

        if isUpgradePlannerSubActive(player, "upgrade") then
            if onMarkedForUpgrade(event) then
                return
            end
        end
    end
end

function upgradeplanner_on_player_built_tile(event)
    -- Acceptable bug: When this upgrade planner is used on an item the entity.last_user will change.
    if not event.player_index or not global["config-pers"][game.players[event.player_index].name]["upgrade-planner-active"] then 
        return
    end
    local player = game.players[event.player_index]
    local upActive = global["config-pers"][player.name]["upgrade-planner-active"]

    if upActive and isUpgradePlannerSubActive(player, "dig") and (isHolding("hazard-concrete", player) or isHolding("concrete", player) or isHolding("stone-brick", player))then
          -- only when square size is 1x1
        if #event.positions == 1 then
            
            local x = event.positions[1].x
            local y = event.positions[1].y

            -- increase the size to a 7x7
            local dig_positions = {}
            table.insert(dig_positions, {name = "water", position = {x-3, y-3}})
            table.insert(dig_positions, {name = "water", position = {x-2, y-3}})
            table.insert(dig_positions, {name = "water", position = {x-1, y-3}})
            table.insert(dig_positions, {name = "water", position = {x  , y-3}})
            table.insert(dig_positions, {name = "water", position = {x+1, y-3}})
            table.insert(dig_positions, {name = "water", position = {x+2, y-3}})
            table.insert(dig_positions, {name = "water", position = {x+3, y-3}})
            table.insert(dig_positions, {name = "water", position = {x-3, y-2}})
            table.insert(dig_positions, {name = "water", position = {x-2, y-2}})
            table.insert(dig_positions, {name = "water", position = {x-1, y-2}})
            table.insert(dig_positions, {name = "water", position = {x  , y-2}})
            table.insert(dig_positions, {name = "water", position = {x+1, y-2}})
            table.insert(dig_positions, {name = "water", position = {x+2, y-2}})
            table.insert(dig_positions, {name = "water", position = {x+3, y-2}})
            table.insert(dig_positions, {name = "water", position = {x-3, y-1}})
            table.insert(dig_positions, {name = "water", position = {x-2, y-1}})
            table.insert(dig_positions, {name = "water", position = {x-1, y-1}})
            table.insert(dig_positions, {name = "water", position = {x  , y-1}})
            table.insert(dig_positions, {name = "water", position = {x+1, y-1}})
            table.insert(dig_positions, {name = "water", position = {x+2, y-1}})
            table.insert(dig_positions, {name = "water", position = {x+3, y-1}})
            table.insert(dig_positions, {name = "water", position = {x-3, y  }})
            table.insert(dig_positions, {name = "water", position = {x-2, y  }})
            table.insert(dig_positions, {name = "water", position = {x-1, y  }})
            table.insert(dig_positions, {name = "water", position = {x  , y  }})
            table.insert(dig_positions, {name = "water", position = {x+1, y  }})
            table.insert(dig_positions, {name = "water", position = {x+2, y  }})
            table.insert(dig_positions, {name = "water", position = {x+3, y  }})
            table.insert(dig_positions, {name = "water", position = {x-3, y+1}})
            table.insert(dig_positions, {name = "water", position = {x-2, y+1}})
            table.insert(dig_positions, {name = "water", position = {x-1, y+1}})
            table.insert(dig_positions, {name = "water", position = {x  , y+1}})
            table.insert(dig_positions, {name = "water", position = {x+1, y+1}})
            table.insert(dig_positions, {name = "water", position = {x+2, y+1}})
            table.insert(dig_positions, {name = "water", position = {x+3, y+1}})
            table.insert(dig_positions, {name = "water", position = {x-3, y+2}})
            table.insert(dig_positions, {name = "water", position = {x-2, y+2}})
            table.insert(dig_positions, {name = "water", position = {x-1, y+2}})
            table.insert(dig_positions, {name = "water", position = {x  , y+2}})
            table.insert(dig_positions, {name = "water", position = {x+1, y+2}})
            table.insert(dig_positions, {name = "water", position = {x+2, y+2}})
            table.insert(dig_positions, {name = "water", position = {x+3, y+2}})
            table.insert(dig_positions, {name = "water", position = {x-3, y+3}})
            table.insert(dig_positions, {name = "water", position = {x-2, y+3}})
            table.insert(dig_positions, {name = "water", position = {x-1, y+3}})
            table.insert(dig_positions, {name = "water", position = {x  , y+3}})
            table.insert(dig_positions, {name = "water", position = {x+1, y+3}})
            table.insert(dig_positions, {name = "water", position = {x+2, y+3}})
            table.insert(dig_positions, {name = "water", position = {x+3, y+3}})

            for index, record in pairs(dig_positions) do
                if not game.surfaces[1].can_place_entity({name="steel-chest", position=record.position}) then
                    return nil
                end
            end
                   
            game.surfaces[1].set_tiles(dig_positions, true)

            slSaysAll("I dug a hole @ " .. x .. " x " .. y)
        end

    end
end

function getType(entity)
    if game.entity_prototypes[entity] then
        return game.entity_prototypes[entity].type
    end
    return ""
end

function getConfigItem(player, index, type)
    if not global["config-tmp"][player.name] or index > #global["config-tmp"][player.name] or global["config-tmp"][player.name][index][type] == "" then
        return "not set"
    end
    if not game.item_prototypes[global["config-tmp"][player.name][index][type]] then
        gui_remove(player, index)
        return "not set"
    end
    if not game.item_prototypes[global["config-tmp"][player.name][index][type]].valid then
        gui_remove(player, index)
        return "not set"
    end
      
    return game.item_prototypes[global["config-tmp"][player.name][index][type]].name
end

function upInitGui(player)
    local upeditframe = player.gui.left["upgrade-planner-edit-frame"]
    if upeditframe then
        upeditframe.destroy()
    end
    local editbutton = player.gui.top["upgrade-planner-edit-button"]
    if editbutton then
        editbutton.destroy()
    end
    player.gui.top.add{
        type = "button", 
        name = "upgrade-planner-edit-button", 
        caption = "UP-edit" 
    }
end

-- Open the player's UP gui's
-- @param player target player
function upGuiOpenFrame(player)
    local upeditframe = player.gui.left["upgrade-planner-edit-frame"]

    if upeditframe then
        upeditframe.destroy()
        global["config-tmp"][player.name] = nil
        return
    end

    -- Temporary config lives as long as the frame is open, so it has to be created
    -- every time the frame is opened.

    global["config-tmp"][player.name] = {}

    -- We need to copy all items from normal config to temporary config.

    local i = 0

    for i = 1, UP_MAX_RECORD_SIZE do

        if i > #global["config"][player.name] then
            global["config-tmp"][player.name][i] = { from = "", to = "" }
        else
            global["config-tmp"][player.name][i] = {
                from = global["config"][player.name][i].from, 
                to = global["config"][player.name][i].to
            }
        end
        
    end

    -- Now we can build the GUI.

    upeditframe = player.gui.left.add{
        type = "frame",
        caption = "Upgrade planner editor",
        name = "upgrade-planner-edit-frame",
        direction = "vertical"
    }

    local error_label = upeditframe.add{ 
        type = "label",
        caption = "---",
        name = "upgrade-planner-error-label"
    }

    error_label.style.minimal_width = 200

    local ruleset_grid = upeditframe.add{
        type = "table",
        colspan = 3,
        name = "upgrade-planner-ruleset-grid"
    }

    ruleset_grid.add{
        type = "label",
        name = "upgrade-planner-grid-header-1",
        caption = "upgrade from:"
    }
    ruleset_grid.add{
        type = "label",
        name = "upgrade-planner-grid-header-2",
        caption = "upgrade to:"
    }
    ruleset_grid.add{
        type = "label",
        name = "upgrade-planner-grid-header-3",
        caption = ""
    }

    for i = 1, UP_MAX_RECORD_SIZE do
        ruleset_grid.add{ 
            type = "button",
            name = "upgrade-planner-from-" .. i,
            caption = getConfigItem(player, i, "from")
        }
        ruleset_grid.add{
            type = "button",
            name = "upgrade-planner-to-" .. i,
            caption = getConfigItem(player, i, "to")
        }
        ruleset_grid.add{
            type = "button",
            name = "upgrade-planner-clear-" .. i,
            caption = "clear"
        }
    end

    local button_grid = upeditframe.add{
        type = "table",
        colspan = 2,
        name = "upgrade-planner-button-grid"
    }

    button_grid.add{
        type = "button",
        name = "upgrade-planner-apply",
        caption = "Apply"
    }
    button_grid.add{
        type = "button",
        name = "upgrade-planner-clear-all",
        caption = "Clear all"
    }
end

function guiToggleUp(player)
    local slFrame = player.gui.top["sl-extended-frame"]
    if slFrame["upgrade-planner-status-frame"] then
        slFrame["upgrade-planner-status-frame"].destroy()
    end
    upStatusFrame = slFrame.add{
        type = "frame",
        name = "upgrade-planner-status-frame",
        direction = "vertical"
    }

    upStatusFrame = slFrame["upgrade-planner-status-frame"]

    upStatusFrame.add{
        type = "radiobutton",
        state = not global["config-pers"][player.name]["upgrade-planner-active"],
        caption = "Vanilla",
        name = "upgrade-planner-vanilla-radio",
    }  
    upStatusFrame.add{
        type = "radiobutton",
        state = global["config-pers"][player.name]["upgrade-planner-active"],
        caption = "SL-extended",
        name = "upgrade-planner-up++-radio",
    }  

    upStatusFrame.add{
        type = "checkbox",
        state = isUpgradePlannerSubActive(player,"tree"),
        caption = getUpgradePlannerSubCaption(player, "tree"),
        name = "upgrade-planner-tree-btn",
    }
    upStatusFrame.add{
        type = "checkbox",
        state = isUpgradePlannerSubActive(player,"rock"),
        caption = getUpgradePlannerSubCaption(player, "rock"),
        name = "upgrade-planner-rock-btn",
    }
    upStatusFrame.add{
        type = "checkbox",
        state = isUpgradePlannerSubActive(player,"dropped"),
        caption = getUpgradePlannerSubCaption(player, "dropped"),
        name = "upgrade-planner-dropped-btn",
    }
    upStatusFrame.add{
        type = "checkbox",
        state = isUpgradePlannerSubActive(player,"turret"),
        caption = getUpgradePlannerSubCaption(player, "turret"),
        name = "upgrade-planner-turret-btn",
    }
    upStatusFrame.add{
        type = "checkbox",
        state = isUpgradePlannerSubActive(player,"upgrade"),
        caption = getUpgradePlannerSubCaption(player, "upgrade"),
        name = "upgrade-planner-upgrade-btn",
    }
    upStatusFrame.add{
        type = "checkbox",
        state = isUpgradePlannerSubActive(player,"dig"),
        caption = getUpgradePlannerSubCaption(player, "dig"),
        name = "upgrade-planner-dig-btn",
    }
    updateUpVisibility(player)
end

function guiToggleUpgradePlannerSub(player, tr)
    local upStatusFrame = player.gui.top["sl-extended-frame"]["upgrade-planner-status-frame"]

    -- toggle it
    global["config-pers"][player.name][tr] = not global["config-pers"][player.name][tr]

    -- update gui
    upStatusFrame["upgrade-planner-" .. tr .. "-btn"].caption = getUpgradePlannerSubCaption(player, tr)  
end

function isUpgradePlannerSubActive(player, tr)
    return global["config-pers"][player.name][tr]
end

function getUpgradePlannerSubCaption(player, tr)
    if global["config-pers"][player.name][tr] then
        return tr .. "-on"
    else
        return tr .. "-off"
    end
end

function guiApply(player)
    -- Saving changes consists in:
    --   1. copying config-tmp to config
    --   2. removing config-tmp
    --   3. closing the frame

    if global["config-tmp"][player.name] then

        local i = 0
        global["config"][player.name] = {}

        for i = 1, #global["config-tmp"][player.name] do

            -- Rule can be saved only if both "from" and "to" fields are set.

            if global["config-tmp"][player.name][i].from == ""
                    or global["config-tmp"][player.name][i].to == "" then

                global["config"][player.name][i] = { from = "", to = "" }

            else
                global["config"][player.name][i] = {
                    from = global["config-tmp"][player.name][i].from,
                    to = global["config-tmp"][player.name][i].to
                }
            end
            
        end

        global["config-tmp"][player.name] = nil

    end

    local frame = player.gui.left["upgrade-planner-edit-frame"]

    if frame then
        frame.destroy()
    end
end

function guiClearAll(player)
    local i = 0
    local frame = player.gui.left["upgrade-planner-edit-frame"]

    if not frame then return end

    local ruleset_grid = frame["upgrade-planner-ruleset-grid"]

    for i = 1, UP_MAX_RECORD_SIZE do

        global["config-tmp"][player.name][i] = { from = "", to = "" }
        ruleset_grid["upgrade-planner-from-" .. i].caption = "not set"
        ruleset_grid["upgrade-planner-to-" .. i].caption = "not set"
        
    end
end

function guiDisplayMessage(frame, message)
    local label_name = "upgrade-planner-"
    label_name = label_name .. "error-label"

    local error_label = frame[label_name]
    if not error_label then return end

    if message ~= "---" then
        message = message
    end

    error_label.caption = message
end

function guiSetRule(player, type, index)
    local frame = player.gui.left["upgrade-planner-edit-frame"]
    if not frame or not global["config-tmp"][player.name] then return end

    local stack = player.cursor_stack

    if not stack.valid_for_read then
        guiDisplayMessage(frame, "Click the button with an item in your hand!")
        return
    end

    if stack.name ~= "deconstruction-planner" or type ~= "to" then

        local opposite = "from"
        local i = 0

        if type == "from" then

            opposite = "to"

            for i = 1, #global["config-tmp"][player.name] do
                if index ~= i and global["config-tmp"][player.name][i].from == stack.name then
                    guiDisplayMessage(frame, "This item is already set in 'upgrade from' column!")
                    return
                end
            end

        end

        local related = global["config-tmp"][player.name][index][opposite]

        if related ~= "" then

            if related == stack.name then
                guiDisplayMessage(frame, "You can't set the same item twice in one row!")
                return
            end

            if getType(stack.name) ~= getType(related) then
                guiDisplayMessage(frame, "Items in one row must be the same type!")
                return
            end

        end

    end

    global["config-tmp"][player.name][index][type] = stack.name

    local ruleset_grid = frame["upgrade-planner-ruleset-grid"]
    ruleset_grid["upgrade-planner-" .. type .. "-" .. index].caption = game.item_prototypes[stack.name].name
end

function guiClearRule(player, index)
    local frame = player.gui.left["upgrade-planner-edit-frame"]
    if not frame or not global["config-tmp"][player.name] then return end

    guiDisplayMessage(frame, "---")

    local ruleset_grid = frame["upgrade-planner-ruleset-grid"]

    global["config-tmp"][player.name][index] = { from = "", to = "" }
    ruleset_grid["upgrade-planner-from-" .. index].caption = "not set"
    ruleset_grid["upgrade-planner-to-" .. index].caption = "not set"
end

function onMarkedForUpgrade(event) 
  local player = game.players[event.player_index]
  local config = global["config"][player.name]
  if not config then return end
  local entity = event.entity

    if entity.valid then
      local index = 0
        for i = 1, #config do
          if config[i].from == entity.name then
              index = i
              break
          end
        end
      if index > 0 then
        local upgrade = config[index].to
        if upgrade then
          playerUpgrade(player,entity,upgrade,true)
        end
      end
    end

end

function playerUpgrade(player,entity,upgrade, bool)
    if not entity or not entity.valid then return end
    local surface = player.surface
    if player.get_item_count(upgrade) > 0 then 
        local d = entity.direction
        local f = entity.force
        local p = entity.position
        local n = entity.name
        local new_item
        script.raise_event(defines.events.on_preplayer_mined_item,{player_index = player.index, entity = entity})

        if entity.type == "underground-belt" then 
            if entity.neighbours and entity.neighbours and bool then
             if player.get_item_count(upgrade) > 1 then -- 2 items, sides
                 -- entity.neighbours.cancel_deconstruction(player.force)
                     playerUpgrade(player,entity.neighbours,upgrade,false)
             else
                    flyingText("Insufficient " .. entity.name, {entity.position.x-1.3,entity.position.y-0.5}, my_color_red)
                    return
             end
            end
            new_item = surface.create_entity
              {
              name = upgrade, 
              position = p, 
              force = f, 
              fast_replace = true, 
              direction = d, 
              type = entity.belt_to_ground_type, 
              spill=false
              }
            
        elseif entity.type == "loader" then 
            new_item = surface.create_entity
              {
              name = upgrade, 
              position = p, 
              force = f, 
              fast_replace = true, 
              direction = d, 
              type = entity.loader_type, 
              spill=false
              }
        else
            new_item = surface.create_entity
              {
              name = upgrade, 
              position = p, 
              force = f, 
              fast_replace = true, 
              direction = d, 
              spill=false
              }
        end
      
        player.remove_item{name = upgrade, count = 1}
        player.insert{name = n, count = 1}
        script.raise_event(defines.events.on_player_mined_item,{player_index = player.index, item_stack = {name = n, count = 1}})
        script.raise_event(defines.events.on_built_entity,{player_index = player.index, created_entity = new_item})
    else
        flyingText("Insufficient " .. entity.name, {entity.position.x-1.3,entity.position.y-0.5}, my_color_red) 
    end
end

function pickupTurret(event)
	if event.entity.valid and event.entity.type and event.entity.type == "ammo-turret" then
        local player = game.players[event.player_index]
        local turret = event.entity
        local mainInv = player.get_inventory(defines.inventory.player_main)
		local turretInv = turret.get_inventory(defines.inventory.turret_ammo)

        for name, count in pairs (turretInv.get_contents()) do
            script.raise_event(defines.events.on_preplayer_mined_item,{player_index = player.index, entity = name})
			local itemStack = {name = name, count = count}
        	mainInv.insert(itemStack)
        	script.raise_event(defines.events.on_player_mined_item,{player_index = player.index, item_stack = itemStack})
        end

        script.raise_event(defines.events.on_preplayer_mined_item,{player_index = player.index, entity = turret})
        player.insert({name= turret.name, count = 1})
        script.raise_event(defines.events.on_player_mined_item,{player_index = player.index, item_stack = {name= turret.name, count = 1}})
	    
	    turret.destroy()

    end
    return false
end

function removeTree(event)
    if event.entity.valid and event.entity.type and event.entity.type == "tree" then
        local player = game.players[event.player_index]
        local tree = event.entity

        for k, product in pairs (tree.prototype.mineable_properties.products) do
            local amount_wood = product.amount_max
            script.raise_event(defines.events.on_preplayer_mined_item,{player_index = player.index, entity = tree})
            player.insert({name= "raw-wood", count = amount_wood})
            script.raise_event(defines.events.on_player_mined_item,{player_index = player.index, item_stack = {name= "raw-wood", count = amount_wood}})
            tree.die()
            return true
        end
    end
    return false
end


function removeRock(event)
    if event.entity.valid and event.entity.type and event.entity.type == "simple-entity" then
        local player = game.players[event.player_index]
        local rock = event.entity

        for k, product in pairs (rock.prototype.mineable_properties.products) do
            local amount_stone = product.amount_max
            script.raise_event(defines.events.on_preplayer_mined_item,{player_index = player.index, entity = rock})
            player.insert({name= "stone", count = amount_stone})
            script.raise_event(defines.events.on_player_mined_item,{player_index = player.index, item_stack = {name= "stone", count = amount_stone}})
            rock.destroy()
            return true
        end
    end
    return false
end

function pickupItemOnGround(event)
    if event.entity.valid and event.entity.name and event.entity.name == "item-on-ground" and event.entity.type and event.entity.type == "item-entity" then
        local player = game.players[event.player_index]
        local stack = event.entity.stack

        if player.can_insert(stack) then
            player.insert(stack)
            event.entity.destroy()
        end

        return true
    end
    return false
end
