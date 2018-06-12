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
local Event = require "event"
local Parameters = require "../base/parameters"

local COLLISION_SPEED = Parameters.add("collision", "COLLISION_SPEED", 1.5)
local COLLISION_SPEED_DIFF = Parameters.add("collision", "COLLISION_SPEED_DIFF", 0.3)

-- collision between two robots, at least one of them being fast.
-- See the "Decisions" paragraph of section 12.4

Collision.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
    Ball = true,
}

local collisionCounter = {Blue = 0, Yellow = 0}
function Collision.occuring()
    local collisionSpeed = COLLISION_SPEED()
    local maxSpeedDiff = COLLISION_SPEED_DIFF()
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
        for _, offRobot in ipairs(World[offense.."Robots"]) do
            for _, defRobot in ipairs(World[defense.."Robots"]) do
                local speedDiff = offRobot.speed - defRobot.speed
                local projectedSpeed = (offRobot.pos + speedDiff):orthogonalProjection(offRobot.pos,
                    defRobot.pos):distanceTo(offRobot.pos)
                local defSpeed = defRobot.speed:length()
                local offSpeed = offRobot.speed:length()
                if offRobot.pos:distanceTo(defRobot.pos) <= 2*offRobot.radius
                        and projectedSpeed > collisionSpeed and offSpeed > defSpeed then
                    if offSpeed - defSpeed > maxSpeedDiff then
                        collisionCounter[offense] = collisionCounter[offense] + 1
                        Collision.consequence = "DIRECT_FREE_"..defense:upper()
                        Collision.freekickPosition = offRobot.pos:copy()
                        Collision.executingTeam = World[defense.."ColorStr"]
                        local speed = math.round(offRobot.speed:length(), 2)
                        Collision.message = "Collision foul by " .. World[offense.."ColorStr"] .. " " ..
                            offRobot.id .. "<br>while traveling at " .. speed .. " m/s ("..collisionCounter[offense].." collisions)"
                        Collision.event = Event("Collision", offRobot.isYellow, offRobot.pos, {offRobot.id},
                            "traveling at " .. speed .. " m/s, hitting "..defense:lower().." "..defRobot.id)
                        log(Collision.message)
                        if collisionCounter[offense] == 3 or (collisionCounter[offense] > 3 and
                            (collisionCounter[offense]-3) % 2 == 0) then
                            --Collision.card = "YELLOW_CARD_" .. offense:upper()
                            -- TODO: issue custom message for the number of collisions leading up to a yellow card
                            log("Yellow card for team "..offense..", as they collided "..collisionCounter[offense].." times during the game")
                        end
                        return true
                    else
                        Collision.consequence = "FORCE_START"
                        Collision.freekickPosition = World.Ball.pos
                        Collision.executingTeam = math.random(2) == 1 and "YellowColorStr" or "BlueColorStr"
                        Collision.message = "Collision foul by both teams (ids "..offRobot.id.." and "..defRobot.id..")"
                        Collision.event = Event("CollisionBoth", nil, nil, nil, "Collision involving two fast robots ("..
                            offense.." "..offRobot.id..", "..defense.." "..defRobot.id..")")
                        log(Collision.message)
                        return true
                    end
                end
            end
        end
    end

    return false
end

return Collision
