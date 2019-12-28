--[[***********************************************************************
*   Copyright 2018 Alexander Danzer, Andreas Wendler                      *
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
local Parameters = require "../base/parameters"
local Event = require "gameevent2019"

local STOP_SPEED = 1.5 -- as specified by the rules
local GRACE_PERIOD = 2 -- as specified by rules
local SPEED_TOLERANCE = Parameters.add("stopspeed", "SPEED_TOLERANCE", 0.02)

StopSpeed.possibleRefStates = {
    Stop = true
}

-- dont stop calling the occuring function once the event triggered
StopSpeed.shouldAlwaysExecute = true
StopSpeed.runOnInvisibleBall = true

local enterStopTime = World.Time
local fastRobotsInThisStop = {}
function StopSpeed.occuring()
    if World.Time - enterStopTime < GRACE_PERIOD then
        return false
    end

    for _, robot in ipairs(World.Robots) do
        local teamStr = robot.isYellow and "yellow" or "blue"
        if robot.speed:length() > STOP_SPEED + SPEED_TOLERANCE() and not fastRobotsInThisStop[robot] then
            StopSpeed.message = teamStr.." bot "..robot.id.." was too fast during stop"
            StopSpeed.event = Event.stopSpeed(robot.isYellow, robot.id, robot.pos, robot.speed:length())
            fastRobotsInThisStop[robot] = true
            return true
        end
    end
    return false
end

function StopSpeed.reset()
    fastRobotsInThisStop = {}
    enterStopTime = World.Time
end

return StopSpeed
