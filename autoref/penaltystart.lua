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

local PenaltyStart = {}

local debug = require "../base/debug"
local World = require "../base/world"
local Event = require "gameevent2019"

PenaltyStart.possibleRefStates = {
    Penalty = true
}

local PENALTY_EXTRA_WAIT = 1

local allCorrectTime = nil
local startTime = World.Time
function PenaltyStart.occuring()
	if World.RefereeState ~= "PenaltyBluePrepare" and World.RefereeState ~= "PenaltyYellowPrepare" then
		return false
	end
	-- check if the ball is in roughly the right position
	local defendingTeam = World.RefereeState == "PenaltyBluePrepare" and "Yellow" or "Blue"
	local attackingTeam = World.RefereeState == "PenaltyBluePrepare" and "Blue" or "Yellow"
	local desiredPos = World.Geometry[defendingTeam .. "PenaltySpot"]
	if World.Ball.speed:length() > 0.2 or World.Ball.pos:distanceTo(desiredPos) > 0.1 then
		return false
	end
    -- check if the keeper (if present) touches the goal line
    local waitingForRobots = {} -- robot -> distance to valid position
    local defendingKeeper = World[defendingTeam .. "Keeper"]
    if defendingKeeper then
        local dist = math.abs(defendingKeeper.pos.y - World.Geometry[defendingTeam .. "Goal"].y)
    	if dist > defendingKeeper.radius then
    		waitingForRobots[defendingKeeper] = dist - defendingKeeper.radius
    	end
    end

    -- check if all robots are far enough away from the penalty spot
    -- this does not apply to the keeper and one attacking robot
    local attackingRobot = nil
    local distanceLine = math.sign(desiredPos.y) * (math.abs(desiredPos.y) - 0.4)
    for _, robot in ipairs(World[attackingTeam .. "Robots"]) do
    	if (distanceLine < 0 and robot.pos.y - robot.radius < distanceLine) or
    			(distanceLine > 0 and robot.pos.y + robot.radius > distanceLine) then
    		if not attackingRobot then
    			attackingRobot = robot
    		else
                local dist = distanceLine < 0 and (distanceLine - (robot.pos.y - robot.radius))
                    or (robot.pos.y + robot.radius - distanceLine)
                waitingForRobots[robot] = dist
    		end
    	end
    end
    for _, robot in ipairs(World[defendingTeam .. "Robots"]) do
    	if robot ~= defendingKeeper then
	    	if (distanceLine < 0 and robot.pos.y - robot.radius < distanceLine) or
	    			(distanceLine > 0 and robot.pos.y + robot.radius > distanceLine) then
	    		local dist = distanceLine < 0 and (distanceLine - (robot.pos.y - robot.radius))
                    or (robot.pos.y + robot.radius - distanceLine)
                waitingForRobots[robot] = dist
	    	end
	    end
    end

    if table.count(waitingForRobots) > 0 then
        PenaltyStart.waitingForRobots = waitingForRobots
        return false
    end

    -- check if the shooting robot is standing still
    if not attackingRobot or attackingRobot.speed:length() > 0.1 then
    	return false
    end

    -- wait some small extra time for all robots to get ready
    allCorrectTime = allCorrectTime or World.Time
    if World.Time - allCorrectTime < PENALTY_EXTRA_WAIT then
		return false
    end
    allCorrectTime = nil

    PenaltyStart.message = "Starting penalty"
    PenaltyStart.event = Event.prepared(World.Time - startTime)
    return true
end

function PenaltyStart.reset()
	startTime = World.Time
	allCorrectTime = nil
end

return PenaltyStart
