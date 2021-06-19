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

local Referee = require "base/referee"
local World = require "base/world"
local Event = require "gameevents"
local plot = require "base/plot"

local FastShot = {}

local MAX_SHOOT_SPEED = 6.5

local MAX_FRAME_DISTANCE = 1.5
local MAX_INVISIBLE_TIME = 0.8
local lastRealisticBallPos
local lastRealisticBallTime = 0

local function updateLastRealisticBall()
    if not lastRealisticBallPos or lastRealisticBallPos:distanceTo(World.Ball.pos) < MAX_FRAME_DISTANCE
        or World.Time - lastRealisticBallTime > MAX_INVISIBLE_TIME then
        lastRealisticBallPos = World.Ball.pos:copy()
        lastRealisticBallTime = World.Time
    end
end

-- returns the smoothed and filtered ball speed
local lastSpeed = World.Ball.speed:length()
local FILTER_FACTOR = 0.7
local MAX_REALISTIC_SPEED = 10
local wasInvisible = false
local function smoothBallSpeed()
    updateLastRealisticBall()
    local positionValid = World.Ball:isPositionValid() and World.Ball.pos == lastRealisticBallPos
    if positionValid and wasInvisible then
        lastSpeed = World.Ball.speed:length()
    end
    wasInvisible = not positionValid
    if not positionValid then
        plot.addPlot("filteredBallSpeed", lastSpeed)
        return lastSpeed
    end
    local speed = World.Ball.speed:length()
    if speed < MAX_REALISTIC_SPEED then
        speed = speed * FILTER_FACTOR + lastSpeed * (1 - FILTER_FACTOR)
    else
        speed = lastSpeed
    end

    lastSpeed = speed
    plot.addPlot("filteredBallSpeed", speed)
    return speed
end

FastShot.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true
}

local lastSpeeds = {}
local maxSpeed = 0
function FastShot.occuring()
    local speed = smoothBallSpeed()
    if speed > MAX_SHOOT_SPEED then
        table.insert(lastSpeeds, speed)
        local maxVal = 0
        -- we take the maximum from the 5 last frames above 8m/s
        if #lastSpeeds > 4 then
            for _, val in ipairs(lastSpeeds) do
                if val > maxVal then
                    maxVal = val
                end
            end
        end
        if maxVal ~= 0 then
            maxSpeed = maxVal
            lastSpeeds = {}
            local lastTouchingRobot, shootPosition = Referee.robotAndPosOfLastBallTouch()
            if lastTouchingRobot then
                log("Last robot: "..tostring(lastTouchingRobot.id))
                local color = lastTouchingRobot.isYellow and World.YellowColorStr or World.BlueColorStr
                FastShot.message = "Shot over "..MAX_SHOOT_SPEED.." m/s by " .. color .. " " .. lastTouchingRobot.id ..
                    "<br>Speed: " .. math.round(maxSpeed, 2) .. "m/s"
                -- TODO: max ball height is not set
                FastShot.event = Event.fastShot(lastTouchingRobot.isYellow, lastTouchingRobot.id, shootPosition, maxSpeed)
                maxSpeed = 0
                return true
            end
        end
    else -- don't keep single values from flickering
        lastSpeeds = {}
    end
    return false
end

function FastShot.reset()
    lastSpeed = World.Ball.speed:length()
end

return FastShot
