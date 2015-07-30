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

local MINIMUM_COLLISION_SPEED_DIFF = 4.5

local speedDiff = 0
local offenderSpeed = 0

Collision.possibleRefStates = {
    Halt = true,
    Stop = true,
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

function Collision.occuring()
    for _, blue in ipairs(World.BlueRobots) do
        for _, yellow in ipairs(World.YellowRobots) do
            if blue.pos:distanceTo(yellow.pos) < 2*yellow.radius and
                (yellow.speed-blue.speed):length() > MINIMUM_COLLISION_SPEED_DIFF then
                if blue.speed:length() > yellow.speed:length() then
                    foulingTeam = World.BlueColorStr
                    speedDiff = (blue.speed - yellow.speed):length()
                    offenderSpeed = blue.speed
                else
                    foulingTeam = World.YellowColorStr
                    speedDiff = (yellow.speed - blue.speed):length()
                    offenderSpeed = yellow.speed
                end
                return true -- one foul at a time
            end
        end
    end
    return false
end

function Collision.print()
    log("Collision foul by " .. foulingTeam .. " team")
    log("with " .. speedDiff .. " m/s, while driving at " .. offenderSpeed .. " m/s")
end

return Collision
