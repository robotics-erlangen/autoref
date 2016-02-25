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

-- collision fouls involve one fast moving and one stationary or
-- slow moving robot. See the "Decisions" paragraph of section 12.4
local FAST_SPEED = 2.5
local SLOW_SPEED = 0.5

local speedDiff = 0
local offender = 0

Collision.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

function Collision.occuring()
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
        for _, OffRobot in ipairs(World[offense.."Robots"]) do
            for _, DefRobot in ipairs(World[defense.."Robots"]) do
                if OffRobot.pos:distanceTo(DefRobot.pos) <= 2*DefRobot.radius
                    and OffRobot.speed:length() > FAST_SPEED
                    and DefRobot.speed:length() < SLOW_SPEED
                then
                    Collision.consequence = "DIRECT_FREE_"..defense:upper()
                    Collision.freekickPosition = OffRobot.pos:copy()
                    Collision.executingTeam = World[defense.."ColorStr"]
                    offender = OffRobot
                    return true
                end
            end
        end
    end

    return false
end

function Collision.print()
    local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
    log("Collision foul by " .. color .. " " .. offender.id)
    log("while driving at " .. offender.speed:length() .. " m/s")
end

return Collision
