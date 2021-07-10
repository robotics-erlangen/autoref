--[[***********************************************************************
*   Copyright 2021 Andreas Wendler                                        *
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
local FreekickDistance = Class("ValidationRules.FreekickDistance", Rule)

local World = require "validation-rules/trueworld"
local Event = require "gameevents"

local STOP_BALL_DISTANCE = 0.5 -- as specified by the rules

FreekickDistance.possibleRefStates = {
	Direct = true,
	Indirect = true,
	Kickoff = true
}

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
	for _, robot in ipairs(World[defense.."Robots"]) do
		local d = robot.pos:distanceTo(World.Ball.pos) - robot.shootRadius - World.Ball.radius
		if d < STOP_BALL_DISTANCE then
			local event = Event.freeKickDistance(robot.isYellow, robot.id, robot.pos, d)
			return event
		end
	end
end

return FreekickDistance
