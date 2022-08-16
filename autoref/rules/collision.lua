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
local Constants = require "base/constants"
local Collision = Class("Rules.Collision", Rule)

local Event = require "gameevents"

local COLLISION_SPEED = 1.5
local COLLISION_SPEED_DIFF = 0.3

-- collision between two robots, at least one of them being fast.

Collision.possibleRefStates = {
	Game = true,
	Kickoff = true,
	Penalty = true,
	Direct = true,
	Indirect = true,
	Ball = true,
	Stop = true,
}
Collision.shouldAlwaysExecute = true
Collision.runOnInvisibleBall = true

function Collision:init(worldInjection)
	self.World = worldInjection or (require "base/world")
	self.collidingRobots = {} -- robot -> time
	if worldInjection then
		-- when the true world information is used for the validation rule
		self.assumedBreakSpeedDiff = 0
		-- When the tracked world state is used, colliding robots are closer together than physically possible
		-- This is not the case for the true world state. Therefore, an additional distance is required
		self.collisionDistance = 2 * Constants.maxRobotRadius + 0.02
	else
		self.assumedBreakSpeedDiff = 0.3
		self.collisionDistance = 2 * Constants.maxRobotRadius
	end
end

function Collision:occuring()
	-- go through old collision times
	local COLLISION_COUNT_TIME = 3
	for robot, time in pairs(self.collidingRobots) do
		if self.World.Time - time > COLLISION_COUNT_TIME then
			self.collidingRobots[robot] = nil
		end
	end

	Collision.ignore = false
	for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
		for _, offRobot in ipairs(self.World[offense.."Robots"]) do
			for _, defRobot in ipairs(self.World[defense.."Robots"]) do
				local speedDiff = offRobot.speed - defRobot.speed
				local projectedSpeed = (offRobot.pos + speedDiff):orthogonalProjection(offRobot.pos,
					defRobot.pos):distanceTo(offRobot.pos) - self.assumedBreakSpeedDiff
				local defSpeed = math.max(0, defRobot.speed:length() - self.assumedBreakSpeedDiff)
				local offSpeed = math.max(0, offRobot.speed:length() - self.assumedBreakSpeedDiff)
				local collisionPoint = (offRobot.pos + defRobot.pos) / 2
				if offRobot.pos:distanceTo(defRobot.pos) <= self.collisionDistance
						and projectedSpeed > COLLISION_SPEED and offSpeed > defSpeed
						and not self.collidingRobots[offRobot] and not self.collidingRobots[defRobot] then

					self.collidingRobots[offRobot] = self.World.Time
					self.collidingRobots[defRobot] = self.World.Time
					if offSpeed - defSpeed > COLLISION_SPEED_DIFF then
						local speed = math.round(offRobot.speed:length() - self.assumedBreakSpeedDiff, 2)
						local event = Event.botCrash(offRobot.isYellow, offRobot.id, defRobot.id, collisionPoint, speed, speedDiff)
						return event
					else
						-- TODO: angle is not provided
						local event = Event.botCrashBoth(offRobot.isYellow and offRobot.id or defRobot.id, offRobot.isYellow and defRobot.id or offRobot.id,
							collisionPoint, speedDiff)
						return event
					end
				end
			end
		end
	end
end

return Collision
