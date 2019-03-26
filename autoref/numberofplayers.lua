--[[***********************************************************************
*   Copyright 2019 Alexander Danzer, Andreas Wendler                      *
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

local NumberOfPlayers = {}

local World = require "../base/world"
local Event = require "gameevent2019"

-- TODO: no too many robots?
NumberOfPlayers.possibleRefStates = {
    Stop = true,
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

-- TODO: only do this if the number is exceeded for more than just one frame
function NumberOfPlayers.occuring()
    if #World.YellowRobots > World.YellowRobotsNumberAllowed then
        -- TODO: just discount one robot here
        for _, robot in ipairs(World.YellowRobots) do
            for _, otherRobot in ipairs(World.YellowRobots) do
                if robot~= otherRobot and robot.pos:distanceTo(otherRobot.pos) < 0.07 then
                    -- probably vision problems
                    return false
                end
            end
        end
        NumberOfPlayers.message = World.YellowColorStr .. " team has more than<br>"..World.YellowRobotsNumberAllowed.." players on the field!"
        NumberOfPlayers.event = Event.numberOfRobots(true)
        return true
    elseif #World.BlueRobots > World.BlueRobotsNumberAllowed then
        for _, robot in ipairs(World.BlueRobots) do
            for _, otherRobot in ipairs(World.BlueRobots) do
                if robot~= otherRobot and robot.pos:distanceTo(otherRobot.pos) < 0.07 then
                    -- probably vision problems
                    return false
                end
            end
        end
        NumberOfPlayers.message = World.BlueColorStr .. " team has more than<br>"..World.BlueRobotsNumberAllowed.." players on the field!"
        NumberOfPlayers.event = Event.numberOfRobots(false)
        return true
    end

    return false
end

return NumberOfPlayers
