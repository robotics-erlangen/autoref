--[[***********************************************************************
*   Copyright 2019 Alexander Danzer, Andreas Wendler                      *
*   Robotics Erlangen e.V.                                                *
*   http://www.robotics-erlangen.de/                                      *
*   info@robotics-erlangen.de                                             *
*                                                                         *
*   This program is free software: you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation, either version 3 of the License, or     *
*   any later version.                                                    *
*                                                                         *
*   This program is distributed in the hope that it will be useful,       *
*   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
*   GNU General Public License for more details.                          *
*                                                                         *
*   You should have received a copy of the GNU General Public License     *
*   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
*************************************************************************]]

local Rule = require "rules/rule"
local Class = require "base/class"
local MultipleDefender = Class("Rules.MultipleDefender", Rule)

local Field = require "base/field"
local Event = require "gameevents"

MultipleDefender.possibleRefStates = {
	Game = true
}

function MultipleDefender:init(worldInjection)
	self.World = worldInjection or (require "base/world")
end

function MultipleDefender:occuring()
	local defense = "Yellow"
	if self.World.Ball.pos.y > 0 then -- on blue side of field
		defense = "Blue"
	end
	for _, robot in ipairs(self.World[defense.."Robots"]) do
		local distThreshold = -robot.radius
		if robot ~= self.World[defense.."Keeper"]
				and Field["isIn"..defense.."DefenseArea"](robot.pos, distThreshold)
				and self:ballTouchesRobot(robot) then
			local event = Event.multipleDefender(robot.isYellow, robot.id, robot.pos, nil)
			return event
		end
	end
end

return MultipleDefender
