--[[***********************************************************************
*   Copyright 2018 Alexander Danzer, Andreas Wendler                      *
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
local StopSpeed = Class("Rules.StopSpeed", Rule)

local Event = require "gameevents"

local STOP_SPEED = 1.5 -- as specified by the rules
local GRACE_PERIOD = 2 -- as specified by rules
-- not used when this is a validation rule
local SPEED_TOLERANCE = 0.1

StopSpeed.possibleRefStates = {
	Stop = true
}
StopSpeed.shouldAlwaysExecute = true
StopSpeed.runOnInvisibleBall = true

function StopSpeed:init(worldInjection)
	self.World = worldInjection or (require "base/world")
	self.enterStopTime = self.World.Time
	self.fastRobotsInThisStop = {}
end

function StopSpeed:occuring()
	if self.World.Time - self.enterStopTime < GRACE_PERIOD then
		return
	end

	for _, robot in ipairs(self.World.Robots) do
		local tolerance = self.World.IsSimulatorTruth and 0 or SPEED_TOLERANCE
		if robot.speed:length() > STOP_SPEED + tolerance and not self.fastRobotsInThisStop[robot] then
			local event = Event.stopSpeed(robot.isYellow, robot.id, robot.pos, robot.speed:length())
			self.fastRobotsInThisStop[robot] = true
			return event
		end
	end
end

function StopSpeed:reset()
	self.fastRobotsInThisStop = {}
	self.enterStopTime = self.World.Time
end

return StopSpeed
