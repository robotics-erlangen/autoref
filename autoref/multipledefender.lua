--[[***********************************************************************
*   Copyright 2019 Alexander Danzer, Andreas Wendler                      *
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
local World = require "../base/world"
local Event = require "gameevent2019"

MultipleDefender.possibleRefStates = {
    Game = true
}

local function checkOccupation(team, occupation)
    for _, robot in ipairs(World[team.."Robots"]) do
        local distThreshold = occupation == "partially" and robot.radius or -robot.radius
        if robot ~= World[team.."Keeper"]
                and Field["isIn"..team.."DefenseArea"](robot.pos, distThreshold)
                and robot.pos:distanceTo(World.Ball.pos) < Referee.touchDist then
            MultipleDefender.message = team .. " " .. robot.id ..
                " touched the ball<br>while being located <b>" ..
                occupation .. "</b><br>within its own defense area"
            MultipleDefender.event = Event.multipleDefender(robot.isYellow, robot.id, robot.pos, nil, occupation == "partially")
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
    return checkOccupation(defense, "entirely") -- or checkOccupation(defense, "partially")
end

return MultipleDefender
