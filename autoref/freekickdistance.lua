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

local World = require "../base/world"
local Event = require "event"
local Ruleset = require "ruleset"

local STOP_BALL_DISTANCE = Ruleset.stopBallDistance

FreekickDistance.possibleRefStates = {
    Direct = true,
    Indirect = true,
    Stop = true,
}

local stopBallPos
function FreekickDistance.occuring()
    if World.RefereeState == "Stop" or not stopBallPos then
        stopBallPos = World.Ball.pos
        return false
    end
    local defense = World.RefereeState:match("irect(%a+)") == "Yellow" and "Blue" or "Yellow"
    for _, robot in ipairs(World[defense.."Robots"]) do
        if robot.pos:distanceTo(stopBallPos)-robot.shootRadius < STOP_BALL_DISTANCE and World.Ball.speed:length() < 1 then
            local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
            FreekickDistance.consequence = "STOP"
            FreekickDistance.message = color .. " " .. robot.id .. " did not keep "..tostring(STOP_BALL_DISTANCE*100).." cm distance<br>to ball during free kick"
            FreekickDistance.event = Event("FreekickDistance", robot.isYellow, robot.pos, {robot})
            return true
        end
    end
end

return FreekickDistance
