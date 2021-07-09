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

local Rule = require "rules/rule"
local Class = require "base/class"
local Dribbling = Class("Rules.Dribbling", Rule)

local Referee = require "base/referee"
local World = require "base/world"
local Event = require "gameevents"

local MAX_DRIBBLING_DIST = 1 -- as specified by the rules

Dribbling.possibleRefStates = {
    Game = true
}

function Dribbling:init()
	self.dribblingStart = nil
end

function Dribbling:occuring()
    local currentTouchingRobot
    for _, robot in ipairs(World.Robots) do
        if robot.pos:distanceTo(World.Ball.pos) <= Referee.touchDist then
            currentTouchingRobot = robot
            break
        end
    end
    if currentTouchingRobot then
        if not self.dribblingStart or currentTouchingRobot ~= Referee.robotAndPosOfLastBallTouch() then
            self.dribblingStart = currentTouchingRobot.pos:copy()
        end
        if currentTouchingRobot.pos:distanceTo(self.dribblingStart) > MAX_DRIBBLING_DIST then
            local lastRobot = Referee.robotAndPosOfLastBallTouch()
            local message = "Dribbling over " .. MAX_DRIBBLING_DIST .. "m<br>by "
                .. Referee.teamWhichTouchedBallLast() .. " " .. lastRobot.id
            -- TODO: should it be the ball position or the robot position
            local event = Event.dribbling(lastRobot.isYellow, lastRobot.id, lastRobot.pos, self.dribblingStart, currentTouchingRobot.pos)
            return event, message
        end
    else
        self.dribblingStart = nil
    end
end

return Dribbling
