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

local offender
local wasGameBefore = false
local startTime = 0
function AttackerDefAreaDist.occuring()
    offender = nil
    local offenderDistance

    if wasGameBefore then
        startTime = WorldTime
        wasGameBefore = false
    end

    if World.Time - startTime < BUFFER_TIME then
        return false
    end

    for offense, defense in pairs({Blue = "Yellow", Yellow = "Blue"}) do
        if wasFreeKickBefore[offense] and World.RefereeState == "Game" then
            for _, robot in ipairs(World[offense.."Robots"]) do
                local distance = Field["distanceTo"..defense.."DefenseArea"](robot.pos, robot.radius)
                if distance <= 0.2 then
                    offender = robot
                    offenderDistance = distance
                    break
                end
            end
        end
    end

    if offender then
        local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
        AttackerDefAreaDist.message = "20cm defense area<br>distance violation by<br>"
            .. color .. " " .. offender.id

        AttackerDefAreaDist.event = Event.attackerDefAreaDist(offender.isYellow, offender.id, offender.pos, offenderDistance)
        return true
    end
end

function AttackerDefAreaDist.reset()
    wasGameBefore = true
end

return AttackerDefAreaDist
