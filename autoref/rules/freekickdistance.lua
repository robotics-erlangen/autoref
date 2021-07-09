--[[***********************************************************************
*   Copyright 2015 Alexander Danzer, Lukas Wegmann                        *
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
local FreekickDistance = Class("Rules.FreekickDistance", Rule)

local World = require "base/world"
local Event = require "gameevents"

local STOP_BALL_DISTANCE = 0.5 -- as specified by the rules

FreekickDistance.possibleRefStates = {
    Direct = true,
    Indirect = true,
    Kickoff = true
}

function FreekickDistance:init()
	self.stopBallPos = nil
end

function FreekickDistance:occuring()
    local defenseTeamMap = {
        DirectBlue = "Yellow",
        DirectYellow = "Blue",
        IndirectBlue = "Yellow",
        IndirectYellow = "Blue",
        KickoffBluePrepare = "Yellow",
        KickoffYellowPrepare = "Blue",
        KickoffBlue = "Yellow",
        KickoffYellow = "Blue"
    }
    local defense = defenseTeamMap[World.RefereeState]
	if World.Ball.speed:length() > 1 then
		return
	end
    for _, robot in ipairs(World[defense.."Robots"]) do
        local d = robot.pos:distanceTo(self.stopBallPos)-robot.shootRadius
		local isCurrentlyTooClose = false
		if World.Ball:isPositionValid() then
			-- the ball could have been moved by a few centimeters from the initial position
			local extraDistance = 0.1
			local dist = robot.pos:distanceTo(World.Ball.pos)
			isCurrentlyTooClose = dist < STOP_BALL_DISTANCE - extraDistance
		end
        if isCurrentlyTooClose or d < STOP_BALL_DISTANCE then
            local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
            local message = color .. " " .. robot.id .. " did not keep "..tostring(STOP_BALL_DISTANCE*100).." cm distance<br>to ball during free kick"
            local event = Event.freeKickDistance(robot.isYellow, robot.id, robot.pos, d)
            return event, message
        end
    end
end

function FreekickDistance:reset()
    self.stopBallPos = World.Ball.pos
end

return FreekickDistance
