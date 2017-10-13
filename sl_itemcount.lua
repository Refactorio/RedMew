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


-- sl_itemcount.lua
-- 20170118
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.

-- Credit:
--  ThaPear, Nexela

local function itemcount_setGUIText(player, count, vehicle_count)
	local text = tostring(count)
	if vehicle_count > 0 then
		text = text .. "  (".. tostring(vehicle_count) ..")"
	end
	if player.gui.center.itemcount then
		player.gui.center.itemcount.style.font = "default-bold"
		player.gui.center.itemcount.caption = text
	end
end

local function itemcount_openGUI(player)
	if not player.gui.center.itemcount then
		player.gui.center.add{type="label", name="itemcount", caption="0", direction = "vertical"}
		player.gui.center.itemcount.style.minimal_width=32
	end
end

local function itemcount_closeGUI(player)
	if player.gui.center.itemcount then
		player.gui.center.itemcount.destroy()
	end
end

local function itemcount_calculatetotal(player, item_name, vehicle)
	local inventory_count = player.get_item_count(item_name)
	local vehicle_count = 0
	if vehicle and vehicle.get_inventory(defines.inventory.car_trunk) then
		vehicle_count = vehicle.get_inventory(defines.inventory.car_trunk).get_item_count(item_name)
	end
	return inventory_count, vehicle_count
end

function itemcount_checkstack(event)
	local player=game.players[event.player_index]
	if player and player.cursor_stack.valid_for_read then
		itemcount_openGUI(player)
		itemcount_setGUIText(player, itemcount_calculatetotal(player, player.cursor_stack.name, player.vehicle))
	else
		itemcount_closeGUI(player)
	end
end
