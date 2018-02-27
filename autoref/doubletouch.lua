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

local DoubleTouch = {}

local Referee = require "../base/referee"
local debug = require "../base/debug"
local World = require "../base/world"
local Event = require "event"

local CONSIDER_FREE_KICK_EXECUTED_THRESHOLD = 0.07

-- define all refstates to be able to reset variables
-- foul occurs actually only in Game
DoubleTouch.possibleRefStates = {
    Halt = true,
    Stop = true,
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
    Ball = true
}

local lastTouchingRobotInFreekick
local lastBallPosInStop
function DoubleTouch.occuring()
    local simpleRefState = World.RefereeState:match("%u%l+")
    if simpleRefState == "Stop" or not lastBallPosInStop then
        lastBallPosInStop = World.Ball.pos:copy()
    end

    if simpleRefState == "Indirect" or simpleRefState == "Direct" then
        -- lastTouchingRobotInFreekick = nil
        local r = Referee.robotAndPosOfLastBallTouch()
        if r and r.pos:distanceTo(World.Ball.pos) < Referee.touchDist then
            lastTouchingRobotInFreekick = r
            debug.set("last touch in freekick", lastTouchingRobotInFreekick)
        end
    elseif World.RefereeState == "Game" and lastTouchingRobotInFreekick then
        local touchingRobot
        for _, robot in ipairs(World.Robots) do
            if robot.pos:distanceTo(World.Ball.pos) < Referee.touchDist then
                touchingRobot = robot
            end
        end

        local distToFreekickPos = World.Ball.pos:distanceTo(lastBallPosInStop)
        debug.set("last touch in freekick", lastTouchingRobotInFreekick)
        debug.set("touching robot", touchingRobot)
        debug.set("distToFreekickPos", distToFreekickPos)
        if touchingRobot and distToFreekickPos > CONSIDER_FREE_KICK_EXECUTED_THRESHOLD then
            if touchingRobot == lastTouchingRobotInFreekick then
                local defenseTeam = touchingRobot.isYellow and "Blue" or "Yellow"
                DoubleTouch.consequence = "INDIRECT_FREE_" .. defenseTeam:upper()
                DoubleTouch.freekickPosition = touchingRobot.pos:copy()
                DoubleTouch.executingTeam = World[defenseTeam.."ColorStr"]
                local offenseTeam = touchingRobot.isYellow and "Yellow" or "Blue"
                DoubleTouch.message = "Double touch by " .. offenseTeam .. " " .. touchingRobot.id
                DoubleTouch.event = Event("DoubleTouch", touchingRobot.isYellow, touchingRobot.pos, {touchingRobot})
                return true
            else
                lastTouchingRobotInFreekick = nil
            end
        end
    else
        lastTouchingRobotInFreekick = nil
    end
    return false
end

return DoubleTouch
