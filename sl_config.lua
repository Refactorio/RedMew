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


-- sl_config.lua
-- 20170603
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.

-- Credit:
-- 	Oarc

-- Configuration Options

--[[
SERVER SETTINGS:
[EU] trains | SL-extended automods | all Welcome
]]

-- Achievements work in freeplay not in scenario: freeplay(save a map, add files to save-file, host it)
HACK_GAME_IS_MULTIPLAYER_FREEPLAY_NOT_SCENARIO = true

--------------------------------------------------------------------------------
-- Messages
--------------------------------------------------------------------------------

WELCOME_MSG = "Welcome to [EU] trains | SL-extended automods | all Welcome"
MODULES_ENABLED = "Powered by SL-extended(see forum) Features: Long-Reach, Character++, Autofill, Upgrade Planner ++, Itemcount, Trash, Train Scheduler, Commands, Blueprint Requests, Train Color, Auto Hide Minimap, ..."

--------------------------------------------------------------------------------
-- Module Enables
--------------------------------------------------------------------------------

-- Enable Undecorator
ENABLE_UNDECORATOR = true

-- Enable Long Reach
ENABLE_LONGREACH = true

-- Enable Character++
ENABLE_CHARACTERPLUSPLUS = true

-- Enable Autofill
ENABLE_AUTOFILL = true

-- Enable Autodeconstruct
ENABLE_AUTODECONSTRUCT = true

-- Enable Autohideminimap
ENABLE_AUTO_HIDE_MINI_MAP = true

-- Enable Upgrade Planner
ENABLE_UPGRADE_PLANNER = true

-- Enable Itemcount
ENABLE_ITEMCOUNT = true

-- Enable Traincolor
ENABLE_TRAIN_COLOR = true


--------------------------------------------------------------------------------
-- Long Reach Options
--------------------------------------------------------------------------------

BUILD_DIST_BONUS = 5000
REACH_DIST_BONUS = BUILD_DIST_BONUS
RESOURCE_DIST_BONUS = 10
ITEM_DROP_DIST_BONUS = 25


--------------------------------------------------------------------------------
-- Character++ Options
--------------------------------------------------------------------------------

CHARACTER_CRAFTING_SPEED_BONUS = 1.5
CHARACTER_MINING_SPEED_BONUS = 0.5


--------------------------------------------------------------------------------
-- Autofill Options
--------------------------------------------------------------------------------

AUTOFILL_TURRET_AMMO_QUANTITY = 25
AUTOFILL_BURNER_FUEL_QUANTITY = 20


--------------------------------------------------------------------------------
-- Upgrade planner Options
--------------------------------------------------------------------------------

UP_MAX_RECORD_SIZE = 10


--------------------------------------------------------------------------------
-- Vanilla blueprint string for the SL-blueprint-book
--------------------------------------------------------------------------------

BPS_SLBOOK = ""


--------------------------------------------------------------------------------
-- SL commands
--------------------------------------------------------------------------------

TICKS_BETWEEN_SLAPS = 15
SLAP_DEFAULT_AMOUNT = 5
AFK_AFTER_TICKS = 60 * 60 * 2   -- 2 minutes
INVENTORY_ROWS_MAX = 100
LOGISTIC_SLOTS_MAX = 18
HP_MAX = 1000
TOOLBAR_MAX = 3
RUNNING_MAX = 3
ZOOM_MAX = 100


--------------------------------------------------------------------------------
-- Auto Hide Mini Map
--------------------------------------------------------------------------------

TICKS_BETWEEN_CHECKS_AUTOHIDEMINIMAP = 27


--------------------------------------------------------------------------------
-- Player's Gui Opened
--------------------------------------------------------------------------------

TICKS_BETWEEN_CHECKS_PLAYERGUIOPENED = 23


-------------------------------------------------------------------------------
-- DEBUG
--------------------------------------------------------------------------------

-- DEBUG prints for me
global.slDebugEnabled = false
