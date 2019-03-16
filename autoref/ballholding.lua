--[[***********************************************************************
*   Copyright 2018 Andreas Wendler                                        *
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

local BallHolding = {}

local World = require "../base/world"
local Field = require "../base/field"
local Parameters = require "../base/parameters"
local Event = require "gameevent2019"

BallHolding.possibleRefStates = {
    Game = true,
}

local MAX_HOLDING_TIME = Parameters.add("ballholding", "MAX_HOLDING_TIME", 15)

local function checkKepperHolding(robot, lastHolding)
    if not Field["isIn"..(robot.isYellow and "Yellow" or "Blue").."DefenseArea"](World.Ball.pos, 0) then
        return false
    end
    local dist = robot.pos:distanceTo(World.Ball.pos)
    local hyst = robot.radius + World.Ball.radius + ((not lastHolding) and 0 or 0.03)
    if dist > hyst then
        return false
    end
    return true
end

local ballHoldingTimes = {}
function BallHolding._updateHolding(robot)
    if not robot then
        return false
    end
    local currentlyHolding = checkKepperHolding(robot, ballHoldingTimes[robot])
    if not ballHoldingTimes[robot] and currentlyHolding then
        ballHoldingTimes[robot] = World.Time
    end
    if not currentlyHolding then
        ballHoldingTimes[robot] = nil
    end
    if ballHoldingTimes[robot] and World.Time - ballHoldingTimes[robot] > MAX_HOLDING_TIME() then
        ballHoldingTimes[robot] = nil
        BallHolding.message = (robot.isYellow and "Yellow" or "Blue").." keeper held the ball longer than 15 seconds in its defense area"
        BallHolding.event = Event.ballHolding(robot.isYellow, robot.id, World.Ball.pos, World.Time - ballHoldingTimes[robot])
        return true
    end
    return false
end

function BallHolding.occuring()
    local retBlue = BallHolding._updateHolding(World.BlueKeeper)
    local retYellow = BallHolding._updateHolding(World.YellowKeeper)
    return retBlue or retYellow
end

return BallHolding
