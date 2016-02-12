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
local Referee = require "../base/referee"

MultipleDefender.possibleRefStates = {
    Game = true
}

local offender, occupation
local function checkOccupation(team, partially)
    for _, robot in ipairs(World[team.."Robots"]) do
        local distThreshold = partially == true and robot.radius or -robot.radius
        if robot ~= World[team.."Keeper"]
                and Field["isIn"..team.."DefenseArea"](robot.pos, distThreshold)
                and robot.pos:distanceTo(World.Ball.pos) < Referee.touchDist
        then
            offender = robot
            occupation = partially and "partially" or "entirely"
            MultipleDefender.consequence = "YELLOW_CARD_" .. team:upper()
            return true
        end
    end
    return false
end

function MultipleDefender.occuring()
    local defense = "Yellow"
    if World.Ball.pos.y > 0 then -- on blue side of field
        defense = "Blue"
    end
    return checkOccupation(defense, false) or checkOccupation(defense, true)
end


function MultipleDefender:print()
    local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
    log(color .. " " .. offender.id .. " touched the ball while being located <b>"
        .. occupation .. "</b> within its own defense area")
end

return MultipleDefender
