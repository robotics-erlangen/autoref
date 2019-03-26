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

local AttackerDefAreaDist = {}

local Field = require "../base/field"
local World = require "../base/world"
local Event = require "gameevent2019"

AttackerDefAreaDist.possibleRefStates = {
    Stop = true,
    Indirect = true,
    Direct = true,
}

local BUFFER_TIME = 2 -- as given by the rules

-- dont stop calling the occuring function once the event triggered
AttackerDefAreaDist.shouldAlwaysExecute = true

local offender
local startTime = 0
local closeRobotsInThisState = {}
function AttackerDefAreaDist.occuring()

    if World.Time - startTime < BUFFER_TIME then
        return false
    end

    for offense, defense in pairs({Blue = "Yellow", Yellow = "Blue"}) do
        for _, robot in ipairs(World[offense.."Robots"]) do
                local distance = Field["distanceTo"..defense.."DefenseArea"](robot.pos, robot.radius)
                if distance <= 0.2 and not closeRobotsInThisState[robot] then

                    local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
                    AttackerDefAreaDist.message = "20cm defense area<br>distance violation by<br>"
                        .. color .. " " .. robot.id

                    AttackerDefAreaDist.event = Event.attackerDefAreaDist(robot.isYellow, robot.id, robot.pos, distance)

                    closeRobotsInThisState[robot] = true
                    return true
                end
            end
    end
end

function AttackerDefAreaDist.reset()
    startTime = World.Time
    closeRobotsInThisState = {}
end

return AttackerDefAreaDist
