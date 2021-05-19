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

local World = require "../base/world"
local Event = require "gameevent2019"

local BallPlacementInterference = {}

BallPlacementInterference.possibleRefStates = {
    Ball = true
}

BallPlacementInterference.shouldAlwaysExecute = true
BallPlacementInterference.resetOnInvisibleBall = true

local inRangeStartTimes = {}
local robotsInThisStop = {}
function BallPlacementInterference.occuring()
    if World.BallPlacementPos then
        local opponent = World.RefereeState == "BallPlacementBlue" and "Yellow" or "Blue"
        for _, robot in ipairs(World[opponent.."Robots"]) do
            local dist = robot.pos:distanceToLineSegment(World.Ball.pos, World.BallPlacementPos)
            if dist < 0.5 + robot.radius then
                if not inRangeStartTimes[robot] then
                    inRangeStartTimes[robot] = World.Time
                else
                    local time = World.Time - inRangeStartTimes[robot]
                    if time > 2 and not robotsInThisStop[robot] then
                        robotsInThisStop[robot] = true
                        BallPlacementInterference.message = "Ball placement interference " .. (table.count(robotsInThisStop))
                        BallPlacementInterference.event = Event.ballPlacementInterference(robot.isYellow, robot.id, robot.pos)
                        return true
                    end
                end
            else
                inRangeStartTimes[robot] = nil
            end
        end
    end
    return false
end

function BallPlacementInterference.reset()
    local simpleRefState = World.RefereeState:match("%u%l+")
    if simpleRefState ~= "Ball" then
        inRangeStartTimes = {}
        robotsInThisStop = {}
    end
end

return BallPlacementInterference
