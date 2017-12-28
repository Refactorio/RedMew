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


-- sl_utils.lua
-- 20170923
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.

-- Credit:
--  Oarc

--------------------------------------------------------------------------------
-- GUI Label Styles
--------------------------------------------------------------------------------
my_color_red = {r=1,g=0.1,b=0.1}


--------------------------------------------------------------------------------
-- General Helper Functions
--------------------------------------------------------------------------------

-- Print debug only to me while testing.
-- Should remove this if you are hosting it yourself.
function debugPrint(msg)
    if ((game.players["SL"]) and (global.slDebugEnabled)) then
        game.players["SL"].print("DEBUG: " .. msg)
    end
end

-- Prints flying text.
-- Color is optional
function flyingText(msg, pos, color) 
    local surface = game.surfaces["nauvis"]
    if color then
        surface.create_entity({ name = "flying-text", position = pos, text = msg, color = color })
    else
        surface.create_entity({ name = "flying-text", position = pos, text = msg })
    end
end

-- SL-extended message
function slSaysAll(msg)
    game.print(":: SL ::   " .. tostring(msg))
end

-- SL-extended message
function slSays(player, msg)
    player.print(":: SL ::   " .. tostring(msg))
end

function formattime(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local seconds = math.floor(seconds - 60*minutes)
  return string.format("%dm:%02ds", minutes, seconds)
end

-- Simple function to get total number of items in table
function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Start slapping a player.
function startSlapping(targetPlayer, fromPlayer, amount)
    -- check if fromPlayer has the rights to slap playername..
    if targetPlayer and targetPlayer.valid and targetPlayer.connected then

        slSaysAll(fromPlayer.name .. " slapped " .. targetPlayer.name .. " " .. amount .. " times" )

        -- only remember the last ordered slapping for each player
        global = global or {}
        global["config-pers"] = global["config-pers"] or {}
        global["config-pers"][targetPlayer.name] = global["config-pers"][targetPlayer.name] or {}
        global["config-pers"][targetPlayer.name]["slaps-left"] = amount

    end
end

-- Slaps left.
function slapsLeft(player)
        -- only remember the last ordered slapping for each player
        global = global or {}
        global["config-pers"] = global["config-pers"] or {}
        global["config-pers"][player.name] = global["config-pers"][player.name] or {}
        return global["config-pers"][player.name]["slaps-left"] or 0
end

-- one Slap received.
function slapReceived(player)
        global = global or {}
        global["config-pers"] = global["config-pers"] or {}
        global["config-pers"][player.name] = global["config-pers"][player.name] or {}
        if global["config-pers"][player.name]["slaps-left"] and global["config-pers"][player.name]["slaps-left"] > 1 then
            global["config-pers"][player.name]["slaps-left"] = global["config-pers"][player.name]["slaps-left"] -1
        else
            global["config-pers"][player.name]["slaps-left"] = nil
        end
end

-- Teleport the player.
function slap(player)
    return slapTill(player, 10)
end

-- till parameter is to make sure there is no infinite loop. eg When the player has no other place to reach.
function slapTill(player, till)
    if player and player.valid and player.connected then
        local randomXdirection = randomPosOrNeg()
        local randomX =  randomXdirection * math.random(10)
        local randomYdirection = randomPosOrNeg()
        local randomY = randomYdirection * math.random(10)

        local newPosition = {x = player.position.x + randomX, y = player.position.y + randomY}
        if player.surface.can_place_entity({name="player", position=newPosition, direction=nil, force=player.force}) then
            local success = player.teleport(newPosition)
            if success then 
                slapReceived(player)
                return true
            else
                return false
            end
        else
            if till > 1 then
                return slapTill(player, till-1)
            else
                return false
            end

        end
    end
    return false
end

function randomPosOrNeg()
    if math.random(2) == 1 then 
        return -1 
    else 
        return 1 
    end
end

-- Slay a player.
function slay(targetPlayer, fromPlayer)
    -- check if fromPlayer has the rights to slap playername..
    if targetPlayer and targetPlayer.valid and targetPlayer.connected then
        slSaysAll(fromPlayer.name .. " slayed " .. targetPlayer.name)
        targetPlayer.character.die()
    end
end

-- Give player these default items.
function givePlayerItems(player)
    local axe = {name="steel-axe", count=2}
    if player.get_inventory(defines.inventory.player_tools).can_insert(axe) then
        player.insert(axe)
    end

    local armorname = "power-armor-mk2"
    if player.get_inventory(defines.inventory.player_armor).can_insert(armorname) then
        player.insert(armorname)
    end
    local armorSlot = player.get_inventory(defines.inventory.player_armor)
        if (not armorSlot.is_empty()) then
            for j = 1, #armorSlot do
            if armorSlot[j].valid_for_read and armorSlot[j].name == armorname then
                local armorgrid = armorSlot[j].grid
                armorgrid.put({name="fusion-reactor-equipment"})
                armorgrid.put({name="personal-roboport-mk2-equipment"})
                armorgrid.put({name="fusion-reactor-equipment"})
                armorgrid.put({name="personal-roboport-mk2-equipment"})
                armorgrid.put({name="personal-roboport-mk2-equipment"})
                armorgrid.put({name="personal-roboport-mk2-equipment"})
                armorgrid.put({name="night-vision-equipment"})
                armorgrid.put({name="personal-roboport-mk2-equipment"})
                armorgrid.put({name="personal-roboport-mk2-equipment"})
                armorgrid.put({name="fusion-reactor-equipment"})
                armorgrid.put({name="battery-mk2-equipment"})
                armorgrid.put({name="battery-mk2-equipment"})
                armorgrid.put({name="fusion-reactor-equipment"})
                armorgrid.put({name="battery-mk2-equipment"})
                armorgrid.put({name="battery-mk2-equipment"})
            end
        end
    end

    player.insert{name="construction-robot", count=150}

    player.get_quickbar().insert{name="deconstruction-planner"}
end

-- Additional starter only items
function givePlayerStarterItems(player)
    givePlayerItems(player)
    player.insert{name="iron-plate", count=25}
    player.insert{name="stone", count=25}
end

-- Ceasefire
-- All forces are always neutral
function setCeaseFireBetweenAllForces()
    for name,team in pairs(game.forces) do
        if name ~= "neutral" and name ~= "enemy" then
            for x,y in pairs(game.forces) do
                if x ~= "neutral" and x ~= "enemy" then
                    team.set_cease_fire(x,true)
                end
            end
        end
    end
end

-- Undecorator
function removeDecorationsArea(surface, area)
    for _, entity in pairs(surface.find_entities_filtered{area = area, type="decorative"}) do
        entity.destroy()
    end
end

-- Remove fish
function removeFish(surface, area)
    for _, entity in pairs(surface.find_entities_filtered{area = area, type="fish"}) do
        entity.destroy()
    end
end

-- Get a random 1 or -1
function randomNegPos()
    if (math.random(0,1) == 1) then
        return 1
    else
        return -1
    end
end
 
-- Add Long Reach to Character
function givePlayerLongReach(player)
    player.character.character_build_distance_bonus = BUILD_DIST_BONUS
    player.character.character_reach_distance_bonus = REACH_DIST_BONUS
    player.character.character_resource_reach_distance_bonus  = RESOURCE_DIST_BONUS
    player.character.character_item_drop_distance_bonus  = ITEM_DROP_DIST_BONUS
end

-- Add Character upgrade
function givePlayerCharacterPlusPlus(player)
    player.character.character_crafting_speed_modifier = CHARACTER_CRAFTING_SPEED_BONUS
    player.character.character_mining_speed_modifier = CHARACTER_MINING_SPEED_BONUS
end


-- Transfer Items Between Inventory
-- Returns the number of items that were successfully transferred.
-- Returns -1 if item not available.
-- Returns -2 if can't place item into destInv (ERROR)
function transferItems(srcInv, destEntity, itemStack)
    -- Check if item is in srcInv
    if (srcInv.get_item_count(itemStack.name) == 0) then
        return -1
    end

    -- Check if can insert into destInv
    if (not destEntity.can_insert(itemStack)) then
        return -2
    end
    
    -- Insert items
    local itemsRemoved = srcInv.remove(itemStack)
    itemStack.count = itemsRemoved
    return destEntity.insert(itemStack)
end

-- Attempts to transfer at least some of one type of item from an array of items.
-- Use this to try transferring several items in order
-- It returns once it successfully inserts at least some of one type.
function transferItemMultipleTypes(srcInv, destEntity, itemNameArray, itemCount)
    local ret = 0
    for _,itemName in pairs(itemNameArray) do
        ret = transferItems(srcInv, destEntity, {name=itemName, count=itemCount})
        if (ret > 0) then
            return ret -- Return the value succesfully transferred
        end
    end
    return ret -- Return the last error code
end

function autofillTurret(player, turret)
    local mainInv = player.get_inventory(defines.inventory.player_main)

    -- Attempt to transfer some ammo
    local ret = transferItemMultipleTypes(mainInv, turret, {"firearm-magazine", "piercing-rounds-magazine", "uranium-rounds-magazine"}, AUTOFILL_TURRET_AMMO_QUANTITY)

    -- Check the result and print the right text to inform the user what happened.
    if (ret > 0) then
        -- Inserted ammo successfully
        -- flyingText("Inserted ammo x" .. ret, turret.position, my_color_red)
    elseif (ret == -1) then
        flyingText("Out of ammo!", turret.position, my_color_red) 
    elseif (ret == -2) then
        flyingText("Autofill ERROR! - Report this bug!", turret.position, my_color_red)
    end
end

function autofillBurner(player, burner)
    local mainInv = player.get_inventory(defines.inventory.player_main)

    -- Attempt to transfer some fuel
    if ((burner.name == "boiler") or (burner.name == "stone-furnace") or (burner.name == "steel-furnace") or (burner.name == "burner-mining-drill")) then
        transferItemMultipleTypes(mainInv, burner, {"raw-wood", "coal", "solid-fuel"}, AUTOFILL_BURNER_FUEL_QUANTITY)
    end
end

function autoFillVehicle(player, vehicle)
    local mainInv = player.get_inventory(defines.inventory.player_main)

    -- Attempt to transfer some fuel
    if ((vehicle.name == "car") or (vehicle.name == "tank") or (vehicle.name == "locomotive")) then
        transferItemMultipleTypes(mainInv, vehicle, {"raw-wood", "coal", "solid-fuel"}, 50)
    end

    -- Attempt to transfer some ammo
    if ((vehicle.name == "car") or (vehicle.name == "tank")) then
        transferItemMultipleTypes(mainInv, vehicle, {"firearm-magazine", "piercing-rounds-magazine", "uranium-rounds-magazine"}, 100)
    end

    -- Attempt to transfer some tank shells
    if (vehicle.name == "tank") then
        transferItemMultipleTypes(mainInv, vehicle, {"explosive-cannon-shell", "cannon-shell", "explosive-uranium-cannon-shell", "uranium-cannon-shell"}, 100)
    end
end


--------------------------------------------------------------------------------
-- EVENT SPECIFIC FUNCTIONS
--------------------------------------------------------------------------------

-- Display messages to a user everytime they join
function playerJoinedMessages(event)
    local player = game.players[event.player_index]
    slSays(player, WELCOME_MSG)
    slSays(player, MODULES_ENABLED)
end

-- Remove decor to save on file size
function undecorateOnChunkGenerate(event)
    local surface = event.surface
    local chunkArea = event.area
    removeDecorationsArea(surface, chunkArea)
    removeFish(surface, chunkArea)
end

-- Give player items on respawn
-- Intended to be the default behavior when not using separate spawns
function playerRespawnItems(event)
    givePlayerItems(game.players[event.player_index])
end

function playerSpawnItems(event)
    givePlayerStarterItems(game.players[event.player_index])
end

-- Autofill softmod
function autofill(event)
    local player = game.players[event.player_index]
    local eventEntity = event.created_entity

    if (eventEntity.name == "gun-turret") then
        autofillTurret(player, eventEntity)
    end

    if ((eventEntity.name == "boiler") or (eventEntity.name == "stone-furnace") or (eventEntity.name == "steel-furnace") or (eventEntity.name == "burner-mining-drill")) then
        autofillBurner(player, eventEntity)
    end

    if ((eventEntity.name == "car") or (eventEntity.name == "tank") or (eventEntity.name == "locomotive")) then
        autoFillVehicle(player, eventEntity)
    end
end

function sl_on_gui_click(event)
    if event and event.player_index and event.element and event.element.valid then
        local player = game.players[event.player_index]
     
        if event.element.name == "sl-extended-train-btn" then
            guiTrain(player)
        elseif event.element.name == "sl-extended-train-station-cancel-btn" then
            guiTrainStationCancel(player)
        elseif event.element.name == "sl-extended-train-station-add-btn" then
            guiTrainStationAdd(player)
        elseif event.element.name == "sl-extended-train-station-finish-btn" then
            setTrainSchedule(player)
        elseif event.element.name == "sl-extended-bp-request-chest-btn" or event.element.name == "sl-extended-bp-request-char-btn" then
            guiBlueprintrequest(player)
        end
    end
end

function sl_on_gui_selection_state_changed(event)
    if event and event.player_index and event.element and event.element.valid then
        local player = game.players[event.player_index]
     
        if event.element.name == "sl-extended-train-stations" then
            guiTrainStationSelection(player, event.element)
        end

        -- if event.element.name == "sl-extended-train-type" then
      --    slSaysAll("selection_state_changed  selected_index:  " .. event.element.selected_index .. "  /  " .. global["config-pers"][player.name]["trainsetup"]["dropdowntype"].get_item(event.element.selected_index))
      --    end

    end
end

function sl_on_on_entity_renamed(event)
    if event and event.entity and event.entity.valid then
        local name = event.entity.backer_name
        if name and name ~= event.old_name then
            -- Change an entire string to Title Case (i.e. capitalise the first letter of each word)
            -- source: http://lua-users.org/wiki/StringRecipes
            local function tchelper(first, rest)
                return first:upper()..rest:lower()
            end
            -- Add extra characters to the pattern if you need to. _ and ' are
            --  found in the middle of identifiers and English words.
            -- We must also put %w_' into [%w_'] to make it handle normal stuff
            -- and extra stuff the same.
            -- This also turns hex numbers into, eg. 0Xa7d4
            name = string.gsub(name, "(%a)([%w_']*)", tchelper)
            event.entity.backer_name = name
        end
    end
end

function sl_init(event)
    local player = game.players[event.player_index] 
    global = global or {}
    global["config-pers"] = global["config-pers"] or {}
    global["config-pers"][player.name] = global["config-pers"][player.name] or {}
    global["config-pers"][player.name]["trainsetup"] = global["config-pers"][player.name]["trainsetup"] or {}
    global["config-pers"][player.name]["bprequest"] = global["config-pers"][player.name]["bprequest"] or {}

    global["config-pers"][player.name]["bonus"] = global["config-pers"][player.name]["bonus"] or {}
    global["config-pers"][player.name]["bonus"]["character_running_speed_modifier"] = global["config-pers"][player.name]["bonus"]["character_running_speed_modifier"] or player.character.character_running_speed_modifier
    global["config-pers"][player.name]["bonus"]["quickbar_count_bonus"] = global["config-pers"][player.name]["bonus"]["quickbar_count_bonus"] or player.character.quickbar_count_bonus
    global["config-pers"][player.name]["bonus"]["character_health_bonus"] = global["config-pers"][player.name]["bonus"]["character_health_bonus"] or player.character.character_health_bonus
    global["config-pers"][player.name]["bonus"]["character_logistic_slot_count_bonus"] = global["config-pers"][player.name]["bonus"]["character_logistic_slot_count_bonus"] or player.character.character_logistic_slot_count_bonus
    global["config-pers"][player.name]["bonus"]["character_inventory_slots_bonus"] = global["config-pers"][player.name]["bonus"]["character_inventory_slots_bonus"] or player.character.character_inventory_slots_bonus
    player.character.character_running_speed_modifier  = global["config-pers"][player.name]["bonus"]["character_running_speed_modifier"]
    player.character.quickbar_count_bonus  = global["config-pers"][player.name]["bonus"]["quickbar_count_bonus"]
    player.character.character_health_bonus  = global["config-pers"][player.name]["bonus"]["character_health_bonus"]
    player.character.character_logistic_slot_count_bonus  = global["config-pers"][player.name]["bonus"]["character_logistic_slot_count_bonus"]
    player.character.character_inventory_slots_bonus  = global["config-pers"][player.name]["bonus"]["character_inventory_slots_bonus"]

    sl_gui_update_frame(player)
end

function guiTrain(player)
    if player.opened and player.opened.valid and (player.opened.type == "locomotive" or player.opened.type == "cargo-wagon" or player.opened.type == "fluid-wagon") and player.opened.train then
        local train = player.opened.train
        global["config-pers"][player.name]["trainsetup"]["train"] = train
        if train and train.valid then
            -- force close window
            player.opened = nil
            guiSelectStation(player)
        end
    else
        slSays(player, "Train not selected.")
    end
end

function guiSelectStation(player)
    guiTrainStationHide(player)

    local frame = player.gui.center.add{
        type = "frame",
        name = "sl-extended-train-station-frame",
        caption = "Select Station & Type:",
        direction = "vertical"
    }

    local dropDownStations = frame.add{ 
        type = "drop-down",
        name = "sl-extended-train-stations",
        caption = "station:"
    }
    for i, station in pairs(findStations()) do
        dropDownStations.add_item(station)
    end
    global["config-pers"][player.name]["trainsetup"]["dropdownstation"] = dropDownStations

    local dropDownType = frame.add{ 
        type = "drop-down",
        name = "sl-extended-train-type",
        caption = "type:"
    }
    DROPDOWN_TYPE_UNLOAD_INDEX = 1
    dropDownType.add_item("Unloading")
    DROPDOWN_TYPE_LOAD_INDEX = 2
    dropDownType.add_item("Loading")
    global["config-pers"][player.name]["trainsetup"]["dropdowntype"] = dropDownType
    dropDownType.style.visible = false

    local frameBottom = frame.add{
        type = "frame",
        name = "sl-extended-train-station-frame",
        direction = "horizontal"
    }
    frameBottom.add{ 
        type = "button",
        name = "sl-extended-train-station-cancel-btn",
        caption = "cancel"
    }
    frameBottom.add{ 
        type = "button",
        name = "sl-extended-train-station-add-btn",
        caption = "add"
    }
    frameBottom.add{ 
        type = "button",
        name = "sl-extended-train-station-finish-btn",
        caption = "finish"
    }
end

function findStations()
    local surface = game.surfaces["nauvis"]
    local stations = {}
    local deduplication = {}
    for _, station in ipairs(surface.find_entities_filtered{type="train-stop"}) do
       if (not deduplication[station.backer_name]) then
           stations[#stations+1] = station.backer_name
           deduplication[station.backer_name] = true
        end
    end
    table.sort(stations)
    return stations
end

function starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function contains(String,Contain)
   return String:find(Contain)
end

function guiTrainStationSelection(player, element)
    local dropdownstationid = global["config-pers"][player.name]["trainsetup"]["dropdownstation"].selected_index
    if dropdownstationid == 0 then
        global["config-pers"][player.name]["trainsetup"]["dropdowntype"].style.visible = false

    else
        local index = 0
        global["config-pers"][player.name]["trainsetup"]["dropdowntype"].style.visible = true

        local name = global["config-pers"][player.name]["trainsetup"]["dropdownstation"].get_item(dropdownstationid)
        name = name:lower()

        if contains(name, "unload") then
            -- 'Depot Unload', 'Depot Oil Unload', 'Depot Acid Unload', ..
            index = DROPDOWN_TYPE_UNLOAD_INDEX
        elseif starts(name,"iron") or starts(name,"copper") or starts(name,"stone") or starts(name,"coal") or starts(name,"uranium") or starts(name,"oil") then
            -- 'Iron 05', 'Copper 02', 'Uranium 05', 'Oil 01', 'Oil 02', ..
            index = DROPDOWN_TYPE_LOAD_INDEX
        elseif starts(name,"rocket") and contains(name, "science") then
            -- 'Rocket 01 Space Science','Rocket 02 Space Science', ..
            index = DROPDOWN_TYPE_LOAD_INDEX
        elseif starts(name,"base") and contains(name, "acid") then
            -- 'Base Acid'
            index = DROPDOWN_TYPE_LOAD_INDEX
        elseif starts(name,"acid") then
            -- 'Acid 01', 'Acid 09', ..
            index = DROPDOWN_TYPE_UNLOAD_INDEX
        elseif starts(name,"base") then
            -- 'Base Iron', 'Base Copper', 'Base Space Science', 'Base Coal', 'Base Uranium', 'Base Stone', 'Base Oil', ..
            index = DROPDOWN_TYPE_UNLOAD_INDEX
        elseif starts(name,"science") then
            -- 'Science 01 Iron', 'Science 01 Copper', 'Science 01 Space Science', 'Science 01 Oil', ..
            index = DROPDOWN_TYPE_UNLOAD_INDEX
        elseif starts(name,"rocket") then
            -- 'Rocket 01 Iron', 'Rocket 01 Copper', 'Rocket 01 Oil', ..
            index = DROPDOWN_TYPE_UNLOAD_INDEX
        elseif starts(name,"depot") then
            -- 'Depot Iron', 'Depot Copper', 'Depot Coal', 'Depot Uranium', 'Depot Stone', 'Depot Space Science', 'Depot Oil', 'Depot Acid', ..
            index = DROPDOWN_TYPE_LOAD_INDEX
        end
    
        global["config-pers"][player.name]["trainsetup"]["dropdowntype"].selected_index = index
    end
end

function guiTrainStationCancel(player)
    guiTrainStationHide(player)
    global["config-pers"][player.name]["trainsetup"] = {}
    slSays(player, "train schedule canceled")

end

function guiTrainStationAdd(player)
    local previousstop = global["config-pers"][player.name]["trainsetup"]["stops"] or 0
    local currentstop = previousstop+1

    local dropdownstationid = global["config-pers"][player.name]["trainsetup"]["dropdownstation"].selected_index
    if dropdownstationid == 0 then
        slSays(player, "train add: " .. currentstop .. ")   station Name missing")
        return
    end
    local stationName = global["config-pers"][player.name]["trainsetup"]["dropdownstation"].get_item(dropdownstationid)

    local dropdowntypeid = global["config-pers"][player.name]["trainsetup"]["dropdowntype"].selected_index
    if dropdowntypeid == 0 then
        slSays(player, "train add: " .. currentstop .. ")   station Type missing")
        return
    end
    local stationType = global["config-pers"][player.name]["trainsetup"]["dropdowntype"].get_item(dropdowntypeid)
    
    global["config-pers"][player.name]["trainsetup"]["stops"] = currentstop
    global["config-pers"][player.name]["trainsetup"]["stoptype-"..currentstop] = stationType
    global["config-pers"][player.name]["trainsetup"]["stopname-"..currentstop] = stationName
    
    if stationType and stationName then
        slSays(player, "train add: " .. currentstop .. ")  " .. stationName .. "  [" .. stationType .. "]")
        guiSelectStation(player)
    else
        slSays(player, "train add: " .. currentstop .. ")   station Type or Name missing")
    end
end

function guiTrainStationHide(player)
    local frame = player.gui.center["sl-extended-train-station-frame"]
    if frame then
        frame.destroy()
    end
end

function setTrainSchedule(player)
    local train = global["config-pers"][player.name]["trainsetup"]["train"]

    local stations = global["config-pers"][player.name]["trainsetup"]["stops"] or 0
    if stations > 0 then
        local currentstop = 1
        local schedule = {}
        schedule.current = 1
        schedule.records = {}

        local stationsstring = ""

        while currentstop  <= stations do

            local stationType = global["config-pers"][player.name]["trainsetup"]["stoptype-"..currentstop]
            local stationName = global["config-pers"][player.name]["trainsetup"]["stopname-"..currentstop]
            if stationType == "Unloading" then
                addUnloading(player, stationName, schedule.records)
            else
                addLoading(player, stationName, schedule.records)
            end
            stationsstring = stationsstring .. "  " .. stationName .. " [" .. stationType .. "]" .. "  |"
            currentstop = currentstop + 1
        end
        train.schedule = schedule
                     
        slSaysAll(
            player.name ..
            ": train schedule changed:  " .. stationsstring
        )
    end

    guiTrainStationHide(player)
    global["config-pers"][player.name]["trainsetup"] = {}
end

function addUnloading(player, stationname, records)
    table.insert(records, 
    {
        station = stationname, 
        wait_conditions = {
            {
                type = "time",
                compare_type = "and",
                ticks = 300,
            },
            {
                type = "empty",
                compare_type = "and",
            },
            {
                type = "inactivity",
                compare_type = "or",
                ticks = 300,
            },
            {
                type = "time",
                compare_type = "or",
                ticks = 12000,
            },
        }
    })
end

function addLoading(player, stationname, records)
    table.insert(records, 
    {
        station = stationname, 
        wait_conditions = {
            {
                type = "full",
                compare_type = "and",
            },
            {
                type = "inactivity",
                compare_type = "or",
                ticks = 300,
            },
            {
                type = "time",
                compare_type = "or",
                ticks = 12000,
            },
        }
    })
end






-- Credit:
--  Apriori
function guiBlueprintrequest(player)
        local active_blueprint
        if isHolding("blueprint", player) then
            active_blueprint = player.cursor_stack
        elseif isHolding("blueprint-book", player) then
            active_blueprint = player.cursor_stack.get_inventory(defines.inventory.item_main)[1]
        end
        if player and player.connected and player.valid then
            if active_blueprint then
                setRequestedItemsForBlueprint(global["config-pers"][player.name]["bprequest"], active_blueprint, player)
            else
                slSays(player, "Please click while holding a blueprint or blueprintbook.")
            end
        end
end

function isHolding(name, player)
    local holding = player.cursor_stack
    if holding and holding.valid_for_read and (holding.name == name) then
        return true
    end
    return false
end

function setRequestedItemsForBlueprint(entity, blueprint_setup, player)
    local unrequested_items = getNeededItems(blueprint_setup)
    setRequestedItems(entity, unrequested_items, player)
end

function setRequestedItems(entity, unrequested_items, player)
    if not entity then
        -- use character
        entity = player.character
    end
    -- Make sure there are enough slots.
    if entity.request_slot_count < #unrequested_items then
        if entity.name ~= "logistic-chest-requester" then
            entity.character_logistic_slot_count_bonus  = entity.character_logistic_slot_count_bonus + #unrequested_items - entity.request_slot_count
        else
            slSays(player, "Error: The blueprint requires more slots than the chest has. Please use your character logistics slots instead.")
            return false
        end
    end
    -- Clear all logistics request slots.
    for slot_index = 1, entity.request_slot_count, 1 do
        if entity.get_request_slot(slot_index) then
            entity.clear_request_slot(slot_index)
        end
    end
    -- Request the blueprint's items.
    for i, item_needed in ipairs(unrequested_items) do
        entity.set_request_slot({name = item_needed.name, count = item_needed.count}, i)
    end
    -- force close window
    player.opened = nil
end

function getNeededItems(blueprint_setup)
    local copy = {}
    for name, count in pairs(blueprint_setup.cost_to_build) do
        table.insert(copy, {name = name, count = count})
    end
    return copy
end

function blueprintrequest_set_endgame(player)
    setRequestedItems(player.character, getEndgameSet(), player)
end

function getEndgameSet()
    local items = {}
    table.insert(items, {name = "express-transport-belt", count = 700})
    table.insert(items, {name = "express-underground-belt", count = 250})
    table.insert(items, {name = "express-splitter", count = 50})
    table.insert(items, {name = "pipe", count = 150})
    table.insert(items, {name = "pipe-to-ground", count = 100})
    table.insert(items, {name = "pump", count = 50})

    table.insert(items, {name = "rail", count = 2000})
    table.insert(items, {name = "train-stop", count = 10})
    table.insert(items, {name = "rail-signal", count = 100})
    table.insert(items, {name = "rail-chain-signal", count = 50})
    table.insert(items, {name = "fast-inserter", count = 100})
    table.insert(items, {name = "stack-inserter", count = 150})

    table.insert(items, {name = "locomotive", count = 10})
    table.insert(items, {name = "cargo-wagon", count = 20})
    table.insert(items, {name = "fluid-wagon", count = 4})
    table.insert(items, {name = "medium-electric-pole", count = 150})
    table.insert(items, {name = "big-electric-pole", count = 100})
    table.insert(items, {name = "substation", count = 50})

    table.insert(items, {name = "steel-chest", count = 150})
    table.insert(items, {name = "logistic-chest-active-provider", count = 50})
    table.insert(items, {name = "logistic-chest-passive-provider", count = 50})
    table.insert(items, {name = "logistic-chest-requester", count = 50})
    table.insert(items, {name = "logistic-chest-storage", count = 50})
    table.insert(items, {name = "roboport", count = 10})

    table.insert(items, {name = "concrete", count = 500})
    table.insert(items, {name = "landfill", count = 500})
    table.insert(items, {name = "small-lamp", count = 150})
    table.insert(items, {name = "arithmetic-combinator", count = 25})
    table.insert(items, {name = "repair-pack", count = 100})
    table.insert(items, {name = "construction-robot", count = 150})

    table.insert(items, {name = "electric-mining-drill", count = 250})
    table.insert(items, {name = "pumpjack", count = 40})
    table.insert(items, {name = "assembling-machine-3", count = 50})
    table.insert(items, {name = "beacon", count = 20})
    table.insert(items, {name = "speed-module-3", count = 100})
    table.insert(items, {name = "productivity-module-3", count = 100})

    table.insert(items, {name = "uranium-rounds-magazine", count = 1000})
    table.insert(items, {name = "gun-turret", count = 50})
    table.insert(items, {name = "laser-turret", count = 250})
    table.insert(items, {name = "stone-wall", count = 1000})
    table.insert(items, {name = "gate", count = 100})
    table.insert(items, {name = "radar", count = 40})

    table.insert(items, {name = "iron-plate", count = 200})
    table.insert(items, {name = "copper-plate", count = 100})
    table.insert(items, {name = "steel-plate", count = 200})
    table.insert(items, {name = "electronic-circuit", count = 400})
    table.insert(items, {name = "advanced-circuit", count = 200})
    table.insert(items, {name = "processing-unit", count = 100})
    
    table.insert(items, {name = "iron-gear-wheel", count = 100})

    return items
end

-- Show the player's SL gui
-- @param player target player
function sl_gui_update_frame(player)
    local slFrame = player.gui.top["sl-extended-frame"]
    if not slFrame then
        slFrame = player.gui.top.add{
            type = "frame",
            name = "sl-extended-frame",
            caption = "SL-extended",
            direction = "vertical"
        }
    end

    local entity = player.opened
   
    if entity and entity.valid then
        if entity.name == "logistic-chest-requester" and entity.type == "logistic-container" then
            global["config-pers"][player.name]["bprequest"] = entity
            if not slFrame["sl-extended-bp-request-chest-btn"] then
                slFrame.add{
                    type = "button",
                    name = "sl-extended-bp-request-chest-btn",
                    caption = "Chest"
                }
            end
        end
        if (entity.type == "locomotive" or entity.type == "cargo-wagon" or entity.type == "fluid-wagon") and entity.train then
            local train = entity.train
            global["config-pers"][player.name]["trainsetup"]["train"] = train
            if not slFrame["sl-extended-train-btn"] then
                slFrame.add{
                    type = "button",
                    name = "sl-extended-train-btn",
                    caption = "Scheduler"
                }
            end
        end
    else
        if slFrame["sl-extended-bp-request-chest-btn"] then
            slFrame["sl-extended-bp-request-chest-btn"].destroy()
        end 
        if slFrame["sl-extended-train-btn"] then
            slFrame["sl-extended-train-btn"].destroy()
        end 
    end
    if not (slFrame["sl-extended-bp-request-chest-btn"]) and (isHolding("blueprint", player) or isHolding("blueprint-book", player)) then
        global["config-pers"][player.name]["bprequest"] = nil
        if not slFrame["sl-extended-bp-request-char-btn"] then
            slFrame.add{
                type = "button",
                name = "sl-extended-bp-request-char-btn",
                caption = "Character"
            }
        end
    else
        if slFrame["sl-extended-bp-request-char-btn"] then
            slFrame["sl-extended-bp-request-char-btn"].destroy()
        end 
    end
end


-- TODO use icons instead of text for chest and character
    -- type = "logistic-container",
    -- name = "logistic-chest-requester",
    -- icon = "__base__/graphics/icons/logistic-chest-requester.png",

    --     slFrame.add{
    --         type = "sprite-button",
    --         name = "sl-extended-bp-request-chest-btn",
    --         sprite="technology/character-logistic-slots",
    --         tooltip="blueprint request"
    --     }

    -- icon = "__base__/graphics/icons/logistic-chest-requester.png",
    -- icon = "__base__/graphics/technology/character-logistic-slots.png",
            -- sprite = "technology/character-logistic-slots"

