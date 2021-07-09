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

local Rule = require "rules/rule"
local Class = require "base/class"
local MultipleDefender = Class("Rules.MultipleDefender", Rule)

local Field = require "base/field"
local Referee = require "base/referee"
local World = require "base/world"
local Event = require "gameevents"

MultipleDefender.possibleRefStates = {
    Game = true
}

function MultipleDefender.occuring()
    local defense = "Yellow"
    if World.Ball.pos.y > 0 then -- on blue side of field
        defense = "Blue"
    end
	for _, robot in ipairs(World[defense.."Robots"]) do
        local distThreshold = -robot.radius
        if robot ~= World[defense.."Keeper"]
                and Field["isIn"..defense.."DefenseArea"](robot.pos, distThreshold)
                and robot.pos:distanceTo(World.Ball.pos) < Referee.touchDist
                and World.Ball.posZ == 0 then
            local message = defense .. " " .. robot.id ..
                " touched the ball<br>while being located entirely within its own defense area"
            local event = Event.multipleDefender(robot.isYellow, robot.id, robot.pos, nil)
            return event, message
        end
    end
end

return MultipleDefender
