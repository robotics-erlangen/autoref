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

local DoubleTouch = {}

local World = require "validation-rules/trueworld"
local Event = require "gameevents"

DoubleTouch.possibleRefStates = {
    Kickoff = true,
    Direct = true,
    Indirect = true,
	Game = true,
}

local lastTouchRobot = nil
local firstTouchPos = nil
function DoubleTouch.occuring()
	for _, robot in pairs(World.Robots) do
		if robot.isTouchingBall then
			if lastTouchRobot == nil then
				lastTouchRobot = robot
				firstTouchPos = World.Ball.pos
			elseif lastTouchRobot ~= robot then
				lastTouchRobot = nil
				firstTouchPos = nil
			else
				if firstTouchPos:distanceTo(World.Ball.pos) > 0.05 then
					local offenseTeam = robot.isYellow and "Yellow" or "Blue"
					DoubleTouch.message = "(truth) Double touch by " .. offenseTeam .. " " .. robot.id
                	DoubleTouch.event = Event.doubleTouch(robot.isYellow, robot.id, firstTouchPos)
					return true
				end
			end
		end
	end
end

function DoubleTouch.reset()
	lastTouchRobot = nil
	firstTouchPos = nil
end

return DoubleTouch