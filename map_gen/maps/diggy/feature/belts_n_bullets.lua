-- This module disables some technologies to focus on belts and bullets
local Event = require 'utils.event'
local Token = require 'utils.token'
local ScenarioInfo = require 'features.gui.info'

local BeltsnBullets = {}


function BeltsnBullets.register (config)
	local disabled_technologies = config.disabled_technologies
	Event.on_init(function ()
	    for i, dis_tech in ipairs(disabled_technologies) do
		    game.forces.player.technologies[dis_tech].enabled = false
		end
	end)
	
end

return BeltsnBullets
