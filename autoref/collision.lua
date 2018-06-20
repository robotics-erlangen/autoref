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
local Refbox = require "../base/refbox"
local Event = require "event"
local Parameters = require "../base/parameters"

local COLLISION_SPEED = Parameters.add("collision", "COLLISION_SPEED", 1.5)
local COLLISION_SPEED_DIFF = Parameters.add("collision", "COLLISION_SPEED_DIFF", 0.3)
local ASSUMED_BREAK_SPEED_DIFF = Parameters.add("collision", "ASSUMED_BREAK_SPEED_DIFF", 0.25)

-- collision between two robots, at least one of them being fast.
-- See the "Decisions" paragraph of section 12.4

Collision.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
    Ball = true,
    Stop = true,
}

local collisionCounter = {Blue = 0, Yellow = 0}
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
                    if Field["isIn"..offense.."DefenseArea"](collisionPoint, 0) then
                        Collision.consequence = "STOP"
                        Collision.message = "Penalty for "..defense.." as they collided inside their own defense area"
                        Collision.event = Event("Collision", offRobot.isYellow, nil, {offRobot.id},
                            "penalty for "..defense..", collision in their defense area with "..defense.." "..defRobot.id)
                        return true
                    elseif offSpeed - defSpeed > maxSpeedDiff then
                        collisionCounter[offense] = collisionCounter[offense] + 1

                        local speed = math.round(offRobot.speed:length() - breakDiff, 2)
                        local message = "Collision foul by " .. World[offense.."ColorStr"] .. " " ..
                            offRobot.id .. "<br>while traveling at " .. speed .. " m/s ("..collisionCounter[offense].." collisions)"
                        Refbox.sendWarning(message)
                        Collision.message = message
                        Collision.ignore = true

                        if collisionCounter[offense] == 3 or (collisionCounter[offense] > 3 and
                            (collisionCounter[offense]-3) % 2 == 0) then
                            Collision.message = "Yellow card for team "..offense..", as they collided "..collisionCounter[offense].." times"
                            Collision.consequence = "YELLOW_CARD_" .. offense:upper()
                            Collision.event = Event("Collision", offRobot.isYellow, nil, {}, Collision.message)
                        end
                        return true
                    else
                        local message = "Collision by both teams ("..
                            offense.." "..offRobot.id..", "..defense.." "..defRobot.id..")"
                        Refbox.sendWarning(message)
                        Collision.message = message
                        Collision.ignore = true
                        return true
                    end
                end
            end
        end
    end

    return false
end

return Collision
