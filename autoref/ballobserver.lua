--[[***********************************************************************
*   Copyright 2025 Andreas Wendler, Paul Bergmann, Tobias Heineken        *
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

local BallObserver = {}

local World = require "base/world"
local debug = require "base/debug"

-- TODO: might be better to implement a more refined version in the tracking
local MAX_FRAME_DISTANCE = 1.5
local MAX_INVISIBLE_TIME = 1.5
local lastRealisticBallPos
local lastRealisticBallTime = 0

function BallObserver.getRealisticBallPos()
	return lastRealisticBallPos
end

local function uLRBCondition()
	debug.pushtop("last realistic ball")

	if lastRealisticBallPos == nil then
		debug.set(nil, "initial")
		debug.pop()
		return true -- always update if no previous data is known
	end

	if lastRealisticBallPos:distanceToSq(World.Ball.pos) < MAX_FRAME_DISTANCE * MAX_FRAME_DISTANCE then
		debug.set(nil, "close")
		debug.pop()
		return true -- do update if the position seems plausible
	end

	if World.Time - lastRealisticBallTime <= MAX_INVISIBLE_TIME then
		debug.set(nil, "waiting")
		debug.pop()
		return false -- we don't want to update the prediction with bad data too quickly,
		-- but we do need to update after some time to stay responsive,
		-- for example if the ball was moved by the referee
	end

	if World.Ball.detectionQuality > 0.2 then
		debug.set(nil, "good")
		debug.pop()
		return true -- if the data is good, we take it after some time
	end

	if World.RefereeState == "BallPlacementYellow" or World.RefereeState == "BallPlacementBlue" then
		debug.set(nil, "ball placement")
		debug.pop()
		return false -- we do not want to use bad data during Ballplacement, as it's not as important to be responsive
	end

	debug.set(nil, "default")
	debug.pop()

	return true -- during regular matches we need to be more responsive, so we take bad data.
	-- This is quite dangerous as false detections seem to be taken by the tracking eagerly if
	-- no other option is visible, but compared to ballplacement we need to be quicker.
	-- Also, the ball isn't as often invisible during normal play.
	-- Use this function during normal play AT YOUR OWN RISK.
end

local function updateLastRealisticBall()
	if uLRBCondition() then
		lastRealisticBallPos = World.Ball.pos
		lastRealisticBallTime = World.Time
	end
end

function BallObserver._update()
	updateLastRealisticBall()
end

return BallObserver
