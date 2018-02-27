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
local Event = require "event"

AttackerDefAreaDist.possibleRefStates = {
    Game = true,
    Indirect = true,
    Direct = true,
}

local offender
-- the distance has to be respected only "at the time enters play"
-- therefore we wait for the switch from a freekick to game state
local wasFreeKickBefore = {
    Blue = false,
    Yellow = false
}
function AttackerDefAreaDist.occuring()
    offender = nil

    for offense, defense in pairs({Blue = "Yellow", Yellow = "Blue"}) do
        if wasFreeKickBefore[offense] and World.RefereeState == "Game" then
            for _, robot in ipairs(World[offense.."Robots"]) do
                if Field["distanceTo"..defense.."DefenseArea"](robot.pos, robot.radius) <= 0.2 then
                    offender = robot
                    AttackerDefAreaDist.consequence = "INDIRECT_FREE_"..defense:upper()
                    AttackerDefAreaDist.freekickPosition = World.Ball.pos:copy()
                    AttackerDefAreaDist.executingTeam = World[defense.."ColorStr"]
                    break
                end
            end
        end
    end

    if World.RefereeState == "DirectBlue" or World.RefereeState == "IndirectBlue" then
        wasFreeKickBefore.Blue = true
    elseif World.RefereeState == "DirectYellow" or World.RefereeState == "IndirectYellow" then
        wasFreeKickBefore.Yellow = true
    else -- both cannot remain true because there has to be a STOP between free kicks
        wasFreeKickBefore.Blue = false
        wasFreeKickBefore.Yellow = false
    end

    if offender then
        local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
        AttackerDefAreaDist.message = "20cm defense area<br>distance violation by<br>"
            .. color .. " " .. offender.id
        AttackerDefAreaDist.event = Event("DefenseAreaDist", offender.isYellow, offender.pos, {offender.id})
        return true
    end
end

return AttackerDefAreaDist
