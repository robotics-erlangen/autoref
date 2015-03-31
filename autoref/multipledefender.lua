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

local MultipleDefender = {}

local Field = require "../base/field"

MultipleDefender.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Direct = true,
    Indirect = true,
}

local offendingTeam =""
local occupation = ""

local function robotIsOffending(robot, team, testOccupation)
    local defAreaDistThreshold = (testOccupation == "partial") and robot.radius or -robot.radius
    if Field["isIn"..team.."DefenseArea"](robot.pos, defAreaDistThreshold) then
        local touchDistance = World.Ball.radius + robot.radius
        if robot.pos:distanceTo(World.Ball.pos) < touchDistance then
            if team == "Blue" then
                offendingTeam = World.BlueColorStr
            else
                offendingTeam = World.YellowColorStr
            end
            occupation = testOccupation
            return true
        end
    end
end

local function checkTeam(team)
    for _, robot in ipairs(World[team .. "Robots"]) do
        if robot ~= World[team .. "Keeper"] then
            if robotIsOffending(robot, team, "full") then return true end
            if robotIsOffending(robot, team, "partial") then return true end
        end
    end
end

function MultipleDefender:occuring()
    if checkTeam("Yellow") or checkTeam("Blue") then
        return true
    end

    return false
end

function MultipleDefender:print()
    log("Multiple defenders by " .. offendingTeam .. " team: " .. occupation .. " occupation")
end

return MultipleDefender
