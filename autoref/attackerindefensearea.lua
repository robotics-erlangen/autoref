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

local AttackerInDefenseArea = {}

local Field = require "../base/field"
local Referee = require "../base/referee"
local World = require "../base/world"
local Event = require "gameevent2019"

AttackerInDefenseArea.possibleRefStates = {
    Game = true
}

function AttackerInDefenseArea.occuring()
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
        for _, robot in ipairs(World[offense.."Robots"]) do
            -- attacker touches ball and is in defense area, even if partially
            if Field["isIn"..defense.."DefenseArea"](robot.pos, robot.radius) then
                if robot.pos:distanceTo(World.Ball.pos) <= Referee.touchDist then
                    local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
                    AttackerInDefenseArea.message = color .. " " .. robot.id ..
                        " touched the ball in defense area"
                    -- TODO: distance in defense area
                    AttackerInDefenseArea.event = Event.attackerInDefenseArea(robot.isYellow, robot.id, robot.pos)
                    return true
                end
            end
        end
    end
end

return AttackerInDefenseArea
