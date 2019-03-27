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

local World = require "../base/world"
local Field = require "../base/field"
local Event = require "gameevent2019"
local Parameters = require "../base/parameters"

local COLLISION_SPEED = Parameters.add("collision", "COLLISION_SPEED", 1.5)
local COLLISION_SPEED_DIFF = Parameters.add("collision", "COLLISION_SPEED_DIFF", 0.3)
local ASSUMED_BREAK_SPEED_DIFF = Parameters.add("collision", "ASSUMED_BREAK_SPEED_DIFF", 0.2)

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

-- TODO: dont ignore the signal for some time after a collision
function Collision.occuring()
    Collision.ignore = false
    local collisionSpeed = COLLISION_SPEED()
    local maxSpeedDiff = COLLISION_SPEED_DIFF()
    local breakDiff = ASSUMED_BREAK_SPEED_DIFF()
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
        for _, offRobot in ipairs(World[offense.."Robots"]) do
            for _, defRobot in ipairs(World[defense.."Robots"]) do
                local speedDiff = offRobot.speed - defRobot.speed
                local projectedSpeed = (offRobot.pos + speedDiff):orthogonalProjection(offRobot.pos,
                    defRobot.pos):distanceTo(offRobot.pos) - breakDiff
                local defSpeed = math.max(0, defRobot.speed:length() - breakDiff)
                local offSpeed = math.max(0, offRobot.speed:length() - breakDiff)
                local collisionPoint = (offRobot.pos + defRobot.pos) / 2
                if offRobot.pos:distanceTo(defRobot.pos) <= 2*offRobot.radius
                        and projectedSpeed > collisionSpeed and offSpeed > defSpeed then
                    if offSpeed - defSpeed > maxSpeedDiff then

                        local speed = math.round(offRobot.speed:length() - breakDiff, 2)
                        local message = "Collision foul by " .. World[offense.."ColorStr"] .. " " ..
                            offRobot.id .. "<br>while traveling at " .. speed .. " m/s"
                        Collision.message = message
                        Collision.event = Event.botCrash(offRobot.isYellow, offRobot.id, defRobot.id, collisionPoint, speed, speedDiff)
                        return true
                    else
                        local message = "Collision by both teams ("..
                            offense.." "..offRobot.id..", "..defense.." "..defRobot.id..")"
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
