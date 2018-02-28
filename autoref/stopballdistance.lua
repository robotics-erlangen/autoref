--[[***********************************************************************
*   Copyright 2018 Lukas Wegmann                                          *
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

local StopBallDistance = {}

local World = require "../base/world"
local Event = require "event"
local Ruleset = require "ruleset"

local STOP_BALL_DISTANCE = Ruleset.stopBallDistance
local TIME_TO_EVADE_BALL = 2

StopBallDistance.possibleRefStates = {
    Stop = true
}

local lastCallTime = 0
local enterStopTime = 0
function StopBallDistance.occuring()

    if World.Time - lastCallTime > 0.5 then
        -- it is safe to assume that the strategy is executed with a higher
        -- frequence than 0.5s -> there was another ref state in the meantime
        enterStopTime = World.Time
    end

    lastCallTime = World.Time
    if World.Time - enterStopTime < TIME_TO_EVADE_BALL then
        return false
    end

    for _, robot in ipairs(World.Robots) do
        if robot.pos:distanceTo(World.Ball.pos)-robot.shootRadius < STOP_BALL_DISTANCE and World.Ball.speed:length() < 1 then
            local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
            StopBallDistance.consequence = "STOP"
            StopBallDistance.message = color .. " " .. robot.id .. " did not keep "..tostring(STOP_BALL_DISTANCE*100).." cm distance<br>to ball during stop state"
            StopBallDistance.event = Event("StopBallDistance", robot.isYellow, robot.pos, {robot})
            return true
        end
    end
end

return StopBallDistance