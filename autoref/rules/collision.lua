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

local Collision = {}

local World = require "base/world"
local Event = require "gameevents"

local COLLISION_SPEED = 1.5
local COLLISION_SPEED_DIFF = 0.3
local ASSUMED_BREAK_SPEED_DIFF = 0.3

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

-- dont stop calling the occuring function once the event triggered
Collision.shouldAlwaysExecute = true
Collision.runOnInvisibleBall = true

local collidingRobots = {} -- robot -> time
function Collision.occuring()
    -- go through old collision times
    local COLLISION_COUNT_TIME = 3
    for robot, time in pairs(collidingRobots) do
        if World.Time - time > COLLISION_COUNT_TIME then
            collidingRobots[robot] = nil
        end
    end

    Collision.ignore = false
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
        for _, offRobot in ipairs(World[offense.."Robots"]) do
            for _, defRobot in ipairs(World[defense.."Robots"]) do
                local speedDiff = offRobot.speed - defRobot.speed
                local projectedSpeed = (offRobot.pos + speedDiff):orthogonalProjection(offRobot.pos,
                    defRobot.pos):distanceTo(offRobot.pos) - ASSUMED_BREAK_SPEED_DIFF
                local defSpeed = math.max(0, defRobot.speed:length() - ASSUMED_BREAK_SPEED_DIFF)
                local offSpeed = math.max(0, offRobot.speed:length() - ASSUMED_BREAK_SPEED_DIFF)
                local collisionPoint = (offRobot.pos + defRobot.pos) / 2
                if offRobot.pos:distanceTo(defRobot.pos) <= 2*offRobot.radius
                        and projectedSpeed > COLLISION_SPEED and offSpeed > defSpeed
                        and not collidingRobots[offRobot] and not collidingRobots[defRobot] then
                    
                    collidingRobots[offRobot] = World.Time
                    collidingRobots[defRobot] = World.Time
                    if offSpeed - defSpeed > COLLISION_SPEED_DIFF then
                        local speed = math.round(offRobot.speed:length() - ASSUMED_BREAK_SPEED_DIFF, 2)
                        local message = "Collision foul by " .. World[offense.."ColorStr"] .. " " ..
                            offRobot.id .. "<br>while traveling at " .. speed .. " m/s"
                        Collision.message = message
                        Collision.event = Event.botCrash(offRobot.isYellow, offRobot.id, defRobot.id, collisionPoint, speed, speedDiff)
                        return true
                    else
                        local message = "Collision by both teams ("..
                            offense.." "..offRobot.id..", "..defense.." "..defRobot.id..")"
                        Collision.message = message
                        -- TODO: angle is not provided
                        Collision.event = Event.botCrashBoth(offRobot.isYellow and offRobot.id or defRobot.id, offRobot.isYellow and defRobot.id or offRobot.id,
                            collisionPoint, speedDiff)
                        return true
                    end
                end
            end
        end
    end

    return false
end

return Collision
