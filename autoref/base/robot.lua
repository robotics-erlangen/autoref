--[[
--- Robot class.
module "Robot"
]]--

--[[***********************************************************************
*   Copyright 2015 Alexander Danzer, Michael Eischer, Philipp Nordhus     *
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

local Robot = (require "base/class")("Robot")

local Constants = require "base/constants"
local Coordinates = require "base/coordinates"


--- Values provided by a robot object.
--- Fields marked with * are only available for own robots
-- @class table
-- @name Robot
-- @field constants table - robot specific constants *(empty for opponents)
-- @field id number - robot id
-- @field pos Vector - current position
-- @field dir number - current direction faced
-- @field isYellow bool - true if yellow robot
-- @field speed Vector - current speed (movement direction doesn't have to match with dir)
-- @field angularSpeed number - rotation speed of the robot
-- @field isVisible bool - True if robot is tracked
-- @field radius number - the robot's radius (defaults to 0.09m)
-- @field height number - the robot's height *
-- @field shootRadius number
-- @field dribblerWidth number - Width of the dribbler
Robot.constants = {
	hasBallDistance = 0.04, -- 4 cm, robots where the balls distance to the dribbler is less than 2cm are considered to have the ball [m]
	passSpeed = 3, -- speed with which the ball should arrive at the pass target  [m/s]
	shootDriveSpeed = 0.2, -- how fast the shoot task drives at the ball [m/s]
	minAngleError = 4/180 * math.pi -- minimal angular precision that the shoot task guarantees [in radians]
}

--- Creates a new robot object.
-- Init function must be called for EVERY robot.
-- @param id number - the robot id
-- @param isYellow boolean - true if yellow robot
function Robot:init(id, isYellow)
    self.id = id
	self.radius = 0.09 -- set default radius if no specs are available
    self.dribblerWidth = 0.07 --just a good default guess
    self.shootRadius = 0.067 -- shoot radius of 2014 generation
	self.lostSince = 0
	self.lastResponseTime = 0
	self.isYellow = isYellow
	self._hasBall = {}
	self._currentTime = 0
	self._toStringCache = ""
	self.isVisible = nil
	self.pos = nil
	self.dir = nil
	self.speed = nil
	self.angularSpeed = nil
end

function Robot:__tostring()
	if self._toStringCache ~= "" then
		return self._toStringCache
	end
	if not self.pos or not self.id then
		self._toStringCache = string.format("Robot(%s)", self.id and tostring(self.id) or "?")
	else
		self._toStringCache = string.format("Robot(%d, pos%s)", self.id, tostring(self.pos))
	end
	return self._toStringCache
end

-- reset robot commands and update data
function Robot:_update(state, time)

	-- check if robot is tracked
	if not state then
		if self.isVisible ~= false then
			self.isVisible = false
			self.lostSince = time
		end
		return
	end

	self._toStringCache = ""
	self.isVisible = true
	self.pos = Coordinates.toLocal(Vector.createReadOnly(state.p_x, state.p_y))
	self.dir = Coordinates.toLocal(state.phi)
	self.speed = Coordinates.toLocal(Vector.createReadOnly(state.v_x, state.v_y))
	self.angularSpeed = state.omega -- do not invert!
end

--- Check whether the robot has the given ball.
-- Checks whether the ball is in rectangle in front of the dribbler with hasBallDistance depth. Uses hysteresis for the left and right side of that rectangle
-- @param ball Ball - must be World.Ball to make sure hysteresis will work
-- @param [sideOffset number - extends the hasBall area sidewards]
-- @return boolean - has ball
function Robot:hasBall(ball, sideOffset, manualHasBallDistance)
	sideOffset = sideOffset or 0
	local hasBallDistance = (manualHasBallDistance or self.constants.hasBallDistance)

	-- handle sidewards balls, add extra time for strategy timing jitter
	local latencyCompensation = (ball.speed - self.speed):scaleLength(Constants.systemLatency + 0.03)
	local lclen = latencyCompensation:length()

	-- fast fail
	local approxMaxDist = lclen + hasBallDistance + self.shootRadius + ball.radius + self.dribblerWidth / 2 + sideOffset
	if ball.pos:distanceToSq(self.pos) > approxMaxDist * approxMaxDist then
		-- reset hystersis
		self._hasBall[sideOffset] = false
		return false
	end

	-- interpolate vector used for correction to circumvent noise
	local MIN_COMPENSATION = 0.005
	local BOUND_COMPENSATION_ANGLE = 70/180*math.pi
	if lclen < MIN_COMPENSATION then
		latencyCompensation = Vector(0, 0)
	elseif lclen < 2*MIN_COMPENSATION then
		local scale = (lclen - MIN_COMPENSATION) / MIN_COMPENSATION
		latencyCompensation:scaleLength(scale)
	end
	-- local coordinate system
	latencyCompensation = latencyCompensation:rotate(-self.dir)
	-- let the vector point away from the robot
	if latencyCompensation.x < 0 then
		latencyCompensation:scaleLength(-1)
	end
	-- bound angle
	lclen = latencyCompensation:length()
	if lclen > 0.001 and math.abs(latencyCompensation:angle()) > BOUND_COMPENSATION_ANGLE then
		local boundAngle = math.bound(-BOUND_COMPENSATION_ANGLE, latencyCompensation:angle(), BOUND_COMPENSATION_ANGLE)
		latencyCompensation = Vector.fromAngle(boundAngle):scaleLength(lclen)
	end

	-- add hasBallDistance
	if lclen <= 0.001 then
		latencyCompensation = Vector(hasBallDistance, 0)
	else
		latencyCompensation = latencyCompensation:setLength(lclen + hasBallDistance)
	end

	-- Ball position relative to dribbler mid
	local relpos = (ball.pos - self.pos):rotate(-self.dir)
	relpos.x = relpos.x - self.shootRadius - ball.radius
	-- calculate position on the dribbler that would have been hit
	local offset = math.abs(relpos.y - relpos.x * latencyCompensation.y / latencyCompensation.x)
	-- local debug = require "base/debug"
	-- debug.set("latencyCompensation", latencyCompensation)
	-- debug.set("offset", offset)

	-- if too far to the sides
	if offset > self.dribblerWidth / 2 + sideOffset then
		-- reset hystersis
		self._hasBall[sideOffset] = false
		return false
	-- in hysteresis area without having had the ball
	elseif offset >= self.dribblerWidth / 2 - 2*Constants.positionError + sideOffset
			and not self._hasBall[sideOffset] then
		return false
	end

	self._hasBall[sideOffset] = relpos.x > self.shootRadius * (-1.5)
			and relpos.x < latencyCompensation.x and ball.posZ < Constants.maxRobotHeight*1.2 --*1.2 to compensate for vision error
	return self._hasBall[sideOffset]
end

return Robot
