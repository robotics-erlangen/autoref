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
local DoubleTouch = Class("ValidationRules.DoubleTouch", Rule)

local World = require "validation-rules/trueworld"
local Event = require "gameevents"

DoubleTouch.possibleRefStates = {
    Kickoff = true,
    Direct = true,
    Indirect = true,
	Game = true,
}

function DoubleTouch:init()
	self.lastTouchRobot = nil
	self.firstTouchPos = nil
end

function DoubleTouch:occuring()
	for _, robot in pairs(World.Robots) do
		if robot.isTouchingBall then
			if self.lastTouchRobot == nil and World.RefereeState ~= "Game" and World.RefereeState ~= "GameForce" then
				self.lastTouchRobot = robot
				self.firstTouchPos = World.Ball.pos
			elseif self.lastTouchRobot ~= robot then
				self.lastTouchRobot = nil
				self.firstTouchPos = nil
			else
				-- TODO: the last touch reporting does not seem to be perfect just yet
				if self.firstTouchPos and self.firstTouchPos:distanceTo(World.Ball.pos) > 0.05 then
					local offenseTeam = robot.isYellow and "Yellow" or "Blue"
					local message = "(truth) Double touch by " .. offenseTeam .. " " .. robot.id
                	local event = Event.doubleTouch(robot.isYellow, robot.id, self.firstTouchPos)
					return event, message
				end
			end
		end
	end
end

function DoubleTouch:reset()
	self.lastTouchRobot = nil
	self.firstTouchPos = nil
end

return DoubleTouch