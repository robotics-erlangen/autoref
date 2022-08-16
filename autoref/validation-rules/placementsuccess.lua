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

local Event = require "gameevents"

local Rule = require "rules/rule"
local Class = require "base/class"
local BallPlacement = Class("ValidationRules.BallPlacement", Rule)
local World = require "validation-rules/trueworld"

BallPlacement.possibleRefStates = {
	Ball = true
}

local ACCEPTABLE_RADIUS = 0.15 - World.Ball.radius
local SLOW_BALL_SPEED = 0.05

function BallPlacement:init()
	self:reset()
end

function BallPlacement:occuring()
	if World.BallPlacementPos then
		local ballDistance = World.BallPlacementPos:distanceTo(World.Ball.pos)
		if ballDistance > ACCEPTABLE_RADIUS or World.Ball.speed:length() > SLOW_BALL_SPEED then
			return
		end

		local isYellowFreekick = World.NextRefereeState and (World.NextRefereeState == "DirectYellow" or World.NextRefereeState == "IndirectYellow")
		local isBlueFreekick = World.NextRefereeState and (World.NextRefereeState == "DirectBlue" or World.NextRefereeState == "IndirectBlue")
		local allowedYellowDistance = isYellowFreekick and 0.05 or 0.5
		local allowedBlueDistance = isBlueFreekick and 0.05 or 0.5
		for _, robot in ipairs(World.Robots) do
			local allowedDistance = robot.isYellow and allowedYellowDistance or allowedBlueDistance
			local maxBallDistance = allowedDistance + robot.shootRadius + World.Ball.radius
			if robot.pos:distanceTo(World.Ball.pos) < maxBallDistance then
				return
			end
		end
		return Event.placementSuccess(World.RefereeState == "BallPlacementYellow", World.Time - self.startTime,
					ballDistance, self.startingBallPos:distanceTo(World.Ball.pos))
	end
end

function BallPlacement:reset()
	self.startingBallPos = World.Ball.pos
	self.startTime = World.Time
end

return BallPlacement
