--[[***********************************************************************
*   Copyright 2015 Alexander Danzer, Lukas Wegmann                        *
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

local FreekickDistance = {}

local World = require "base/world"
local Event = require "rules/gameevent2019"

local STOP_BALL_DISTANCE = 0.5 -- as specified by the rules

FreekickDistance.possibleRefStates = {
    Direct = true,
    Indirect = true,
    Kickoff = true
}

local stopBallPos
function FreekickDistance.occuring()
    local defense = string.byte(World.RefereeState, -1) == string.byte("w", 1) and "Blue" or "Yellow"
    for _, robot in ipairs(World[defense.."Robots"]) do
        local d = robot.pos:distanceTo(stopBallPos)-robot.shootRadius
        if d < STOP_BALL_DISTANCE and World.Ball.speed:length() < 1 then
            local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
            FreekickDistance.message = color .. " " .. robot.id .. " did not keep "..tostring(STOP_BALL_DISTANCE*100).." cm distance<br>to ball during free kick"
            FreekickDistance.event = Event.freeKickDistance(robot.isYellow, robot.id, robot.pos, d)
            return true
        end
    end
end

function FreekickDistance.reset()
    stopBallPos = World.Ball.pos
end

return FreekickDistance
