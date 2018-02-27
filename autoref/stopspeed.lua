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

local StopSpeed = {}

local World = require "../base/world"
local Event = require "event"
local Ruleset = require "ruleset"

local STOP_SPEED = Ruleset.stopSpeed
local ROBOT_SLOW_DOWN_TIME = 2
local SPEED_TOLERANCE = 0.05

StopSpeed.possibleRefStates = {
    Stop = true,
}

local lastCallTime = 0
local enterStopTime = 0
function StopSpeed.occuring()
    if World.Time - lastCallTime > 0.5 then
        -- it is safe to assume that the strategy is executed with a higher
        -- frequence than 0.5s -> there was another ref state in the meantime
        enterStopTime = World.Time
    end
    lastCallTime = World.Time
    if World.Time - enterStopTime < ROBOT_SLOW_DOWN_TIME then
        return false
    end

    for _, robot in ipairs(World.Robots) do
        if robot.speed:length() > STOP_SPEED - SPEED_TOLERANCE then
            StopSpeed.consequence = "STOP"
            local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
            StopSpeed.message = color .. " " .. robot.id .. " is driving faster<br>than "..STOP_SPEED.." m/s during STOP"
            StopSpeed.event = Event("StopSpeed", robot.isYellow, robot.pos, {robot})
            return true
        end
    end
    return false
end

return StopSpeed
