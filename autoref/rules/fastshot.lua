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
local FastShot = Class("Rules.FastShot", Rule)

local Referee = require "base/referee"
local World = require "base/world"
local Event = require "gameevents"
local plot = require "base/plot"

FastShot.possibleRefStates = {
	Game = true,
	GameForce = true,
	Kickoff = true,
	Penalty = true,
	Direct = true,
	Indirect = true
}

local MAX_SHOOT_SPEED = 6.5
local MAX_FRAME_DISTANCE = 1.5
local MAX_INVISIBLE_TIME = 0.8

function FastShot:init()
	self.lastRealisticBallPos = nil
	self.lastRealisticBallTime = 0

	self.lastSpeed = World.Ball.speed:length()
	self.wasInvisible = false

	self.lastSpeeds = {}
	self.maxSpeed = 0
end

function FastShot:updateLastRealisticBall()
	if not self.lastRealisticBallPos or self.lastRealisticBallPos:distanceTo(World.Ball.pos) < MAX_FRAME_DISTANCE
		or World.Time - self.lastRealisticBallTime > MAX_INVISIBLE_TIME then
		self.lastRealisticBallPos = World.Ball.pos:copy()
		self.lastRealisticBallTime = World.Time
	end
end

-- returns the smoothed and filtered ball speed
local FILTER_FACTOR = 0.7
local MAX_REALISTIC_SPEED = 10
function FastShot:smoothBallSpeed()
	self:updateLastRealisticBall()
	local positionValid = World.Ball:isPositionValid() and World.Ball.pos == self.lastRealisticBallPos
	if positionValid and self.wasInvisible then
		self.lastSpeed = World.Ball.speed:length()
	end
	self.wasInvisible = not positionValid
	if not positionValid then
		plot.addPlot("filteredBallSpeed", self.lastSpeed)
		return self.lastSpeed
	end
	local speed = World.Ball.speed:length()
	if speed < MAX_REALISTIC_SPEED then
		speed = speed * FILTER_FACTOR + self.lastSpeed * (1 - FILTER_FACTOR)
	else
		speed = self.lastSpeed
	end

	self.lastSpeed = speed
	plot.addPlot("filteredBallSpeed", speed)
	return speed
end

function FastShot:occuring()
	local speed = self:smoothBallSpeed()
	if speed > MAX_SHOOT_SPEED then
		table.insert(self.lastSpeeds, speed)
		local maxVal = 0
		-- we take the maximum from the 5 last frames above 8m/s
		if #self.lastSpeeds > 4 then
			for _, val in ipairs(self.lastSpeeds) do
				if val > maxVal then
					maxVal = val
				end
			end
		end
		if maxVal ~= 0 then
			self.maxSpeed = maxVal
			self.lastSpeeds = {}
			local lastTouchingRobot, shootPosition = Referee.robotAndPosOfLastBallTouch()
			if lastTouchingRobot then
				-- TODO: max ball height is not set
				local event = Event.fastShot(lastTouchingRobot.isYellow, lastTouchingRobot.id, shootPosition, self.maxSpeed)
				self.maxSpeed = 0
				return event
			end
		end
	else -- don't keep single values from flickering
		self.lastSpeeds = {}
	end
end

function FastShot:reset()
	self.lastSpeed = World.Ball.speed:length()
end

return FastShot
