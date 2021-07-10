--[[***********************************************************************
*   Copyright 2015 Alexander Danzer                                       *
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
local AttackerDefAreaDist = Class("Rules.AttackerDefAreaDist", Rule)

local Field = require "base/field"
local Event = require "gameevents"

AttackerDefAreaDist.possibleRefStates = {
    Stop = true,
    Indirect = true,
    Direct = true,
}
AttackerDefAreaDist.shouldAlwaysExecute = true
AttackerDefAreaDist.runOnInvisibleBall = true

local BUFFER_TIME = 2 -- as given by the rules

function AttackerDefAreaDist:init(worldInjection)
	self.World = worldInjection or (require "base/world")
	self:reset()
end

function AttackerDefAreaDist:occuring()

    if self.World.Time - self.startTime < BUFFER_TIME then
        return
    end

    for offense, defense in pairs({Blue = "Yellow", Yellow = "Blue"}) do
        for _, robot in ipairs(self.World[offense.."Robots"]) do
			local distance = Field["distanceTo"..defense.."DefenseArea"](robot.pos, robot.radius)
			if distance <= 0.2 and not self.closeRobotsInThisState[robot] then
				local event = Event.attackerDefAreaDist(robot.isYellow, robot.id, robot.pos, distance)
				self.closeRobotsInThisState[robot] = true
				return event
			end
		end
    end
end

function AttackerDefAreaDist:reset()
    self.startTime = self.World.Time
    self.closeRobotsInThisState = {}
end

return AttackerDefAreaDist
