--[[***********************************************************************
*   Copyright 2019 Andreas Wendler                                        *
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

local World = require "base/world"
local Event = require "gameevents"

local Rule = require "rules/rule"
local Class = require "base/class"
local BallPlacementInterference = Class("Rules.BallPlacementInterference", Rule)


-- TODO: If multiple robots commit the same foul within 2 seconds, only the first foul counts.
-- TODO: Each foul has a grace period of 2 seconds per team until it is raised again.
-- TODO: If a robot keeps committing a foul, it will be punished again after the grace period.
-- TODO: das gleiche auch noch fuer ein paar andere Regeln

BallPlacementInterference.possibleRefStates = {
    Ball = true
}
BallPlacementInterference.shouldAlwaysExecute = true
BallPlacementInterference.resetOnInvisibleBall = true

function BallPlacementInterference:init()
	self.inRangeStartTimes = {}
	self.robotsInThisStop = {}
end

function BallPlacementInterference:occuring()
    if World.BallPlacementPos then
        local opponent = World.RefereeState == "BallPlacementBlue" and "Yellow" or "Blue"
        for _, robot in ipairs(World[opponent.."Robots"]) do
            local dist = robot.pos:distanceToLineSegment(World.Ball.pos, World.BallPlacementPos)
            if dist < 0.5 + robot.radius then
                if not self.inRangeStartTimes[robot] then
                    self.inRangeStartTimes[robot] = World.Time
                else
                    local time = World.Time - self.inRangeStartTimes[robot]
                    if time > 2 and not self.robotsInThisStop[robot] then
                        self.robotsInThisStop[robot] = true
                        local event = Event.ballPlacementInterference(robot.isYellow, robot.id, robot.pos)
                        return event
                    end
                end
            else
                self.inRangeStartTimes[robot] = nil
            end
        end
    end
end

function BallPlacementInterference:reset()
    local simpleRefState = World.RefereeState:match("%u%l+")
    if simpleRefState ~= "Ball" then
        self.inRangeStartTimes = {}
        self.robotsInThisStop = {}
    end
end

return BallPlacementInterference
