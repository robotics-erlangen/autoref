--[[***********************************************************************
*   Copyright 2019 Andreas Wendler                                        *
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

local World = require "../base/world"
local Event = require "gameevent2019"

local BallPlacement = {}

BallPlacement.possibleRefStates = {
    Ball = true
}

BallPlacement.runOnInvisibleBall = true

local ACCEPTABLE_RADIUS = 0.15 - World.Ball.radius
local SLOW_BALL_SPEED = 0.2
local inRadiusTime = nil
local IN_RADIUS_WAIT_TIME = 0.7

local startingBallPos = World.Ball.pos
local startTime = World.Time
function BallPlacement.occuring()
    if World.BallPlacementPos then
        local ballDistance = World.BallPlacementPos:distanceTo(World.Ball.pos)
        if World.ActionTimeRemaining < 0 then
            BallPlacement.event = Event.placementFailed(World.RefereeState == "BallPlacementYellow", ballDistance)
            return true
		end
		
		if not World.Ball:isPositionValid() then
			return false
		end
        
        local noRobotNearBall = true
        local isYellowFreekick = World.NextRefereeState and (World.NextRefereeState == "DirectYellow" or World.NextRefereeState == "IndirectYellow")
        local isBlueFreekick = World.NextRefereeState and (World.NextRefereeState == "DirectBlue" or World.NextRefereeState == "IndirectBlue")
        local allowedYellowDistance = isYellowFreekick and 0.05 or 0.5
        local allowedBlueDistance = isBlueFreekick and 0.05 or 0.5
        for _, robot in ipairs(World.Robots) do
            local allowedDistance = robot.isYellow and allowedYellowDistance or allowedBlueDistance
            if robot.pos:distanceTo(World.Ball.pos) < allowedDistance + robot.shootRadius then
                noRobotNearBall = false
            end
        end
        if ballDistance < ACCEPTABLE_RADIUS and World.Ball.speed:length() < SLOW_BALL_SPEED and noRobotNearBall then
            if not inRadiusTime then
                inRadiusTime = World.Time
            end
            if World.Time - inRadiusTime > IN_RADIUS_WAIT_TIME then
                BallPlacement.event = Event.placementSuccess(World.RefereeState == "BallPlacementYellow", World.Time - startTime,
                    ballDistance, startingBallPos:distanceTo(World.Ball.pos))
                return true
            end
        else
            inRadiusTime = nil
        end
    end
    return false
end

function BallPlacement.reset()
    startingBallPos = World.Ball.pos
    startTime = World.Time
    inRadiusTime = nil
end

return BallPlacement
