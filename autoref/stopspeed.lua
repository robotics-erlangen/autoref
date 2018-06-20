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
local Event = require "event"
local Ruleset = require "ruleset"

local STOP_SPEED = Ruleset.stopSpeed
local ROBOT_SLOW_DOWN_TIME = Parameters.add("stopspeed", "ROBOT_SLOW_DOWN_TIME", 1.5)
local SPEED_TOLERANCE = Parameters.add("stopspeed", "SPEED_TOLERANCE", 0.02)

StopSpeed.possibleRefStates = {
    Stop = true,
    Ball = true, -- this is ball placement
}

local enterStopTime = 0
local wasLongEnough = false
local tooFastCounter = { yellow = 0, blue = 0 }
local tooFastRobots = { yellow = {}, blue = {}}
local counterIncreased = { yellow = false, blue = false }
function StopSpeed.occuring()
    if World.Time - enterStopTime < ROBOT_SLOW_DOWN_TIME() then
        return false
    end

    wasLongEnough = true
    for _, robot in ipairs(World.Robots) do
        local teamStr = robot.isYellow and "yellow" or "blue"
        if robot.speed:length() > STOP_SPEED + SPEED_TOLERANCE() and
                not counterIncreased[teamStr] then
            counterIncreased[teamStr] = true
            tooFastCounter[teamStr] = tooFastCounter[teamStr] + 1
            table.insert(tooFastRobots[teamStr], robot.id)
            -- TODO: send warning game event
            
            if tooFastCounter[teamStr] == 3 then
                tooFastCounter[teamStr] = 0
                StopSpeed.message = teamStr.." bots were too fast 3 times in a row (robots "..tooFastRobots[teamStr][1]..
                    ", "..tooFastRobots[teamStr][2]..", "..tooFastRobots[teamStr][3]..") -> yellow card"
                StopSpeed.consequence = "YELLOW_CARD_" .. teamStr:upper()
                StopSpeed.event = Event("StopSpeed", robot.isYellow, nil, nil, tooFastRobots[teamStr][1]..
                    ", "..tooFastRobots[teamStr][2]..", "..tooFastRobots[teamStr][3])
                return true
            end
        end
    end
    return false
end

function StopSpeed.reset()
    enterStopTime = World.Time
    if wasLongEnough then
        if not counterIncreased.blue then
            tooFastCounter.blue = 0
            tooFastRobots.blue = {}
        end
        if not counterIncreased.yellow then
            tooFastCounter.yellow = 0
            tooFastRobots.yellow = {}
        end
    end
    counterIncreased.yellow = false
    counterIncreased.blue = false
    wasLongEnough = false
end

return StopSpeed
