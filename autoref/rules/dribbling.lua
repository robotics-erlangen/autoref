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

local Dribbling = {}

local Referee = require "../base/referee"
local World = require "../base/world"
local Event = require "rules/gameevent2019"

local MAX_DRIBBLING_DIST = 1 -- as specified by the rules

Dribbling.possibleRefStates = {
    Game = true
}

local dribblingStart
function Dribbling.occuring()
    local currentTouchingRobot
    for _, robot in ipairs(World.Robots) do
        if robot.pos:distanceTo(World.Ball.pos) <= Referee.touchDist then
            currentTouchingRobot = robot
            break
        end
    end
    if currentTouchingRobot then
        if not dribblingStart or currentTouchingRobot ~= Referee.robotAndPosOfLastBallTouch() then
            dribblingStart = currentTouchingRobot.pos:copy()
        end
        if currentTouchingRobot.pos:distanceTo(dribblingStart) > MAX_DRIBBLING_DIST then
            local lastRobot = Referee.robotAndPosOfLastBallTouch()
            Dribbling.message = "Dribbling over " .. MAX_DRIBBLING_DIST .. "m<br>by "
                .. Referee.teamWhichTouchedBallLast() .. " " .. lastRobot.id
            -- TODO: should it be the ball position or the robot position
            Dribbling.event = Event.dribbling(lastRobot.isYellow, lastRobot.id, lastRobot.pos, dribblingStart, currentTouchingRobot.pos)
            return true
        end
    else
        dribblingStart = nil
    end
end

return Dribbling
