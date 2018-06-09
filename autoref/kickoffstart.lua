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

local KickoffStart = {}

local World = require "../base/world"

KickoffStart.possibleRefStates = {
    Kickoff = true
}

function KickoffStart.occuring()
	-- check if the ball is in roughly the right position
	if World.Ball.pos:length() > 0.1 then
		return false
	end
	if World.RefereeState ~= "KickoffBluePrepare" and World.RefereeState ~= "KickoffYellowPrepare" then
		return false
	end
    -- check if all robots are on their own side
    for _, robot in ipairs(World.BlueRobots) do
		if robot.pos.y < robot.radius then
			return false
		end
		if World.RefereeState == "KickoffYellowPrepare" and
			robot.pos:distanceTo(World.Ball.pos) < 0.5 + robot.radius - 0.01 then
			return false
		end
    end
    for _, robot in ipairs(World.YellowRobots) do
		if robot.pos.y > -robot.radius then
			return false
		end
		if World.RefereeState == "KickoffBluePrepare" and
			robot.pos:distanceTo(World.Ball.pos) < 0.5 + robot.radius - 0.01 then
			return false
		end
    end
    KickoffStart.consequence = "NORMAL_START"
    KickoffStart.message = "Starting kickoff as both teams were ready after kickoff prepare"
    return true
end

return KickoffStart
