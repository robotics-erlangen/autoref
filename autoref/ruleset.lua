--[[***********************************************************************
*   Copyright 2018 Lukas Wegmann                                          *
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

local Ruleset = {}

Ruleset.name = ""				-- the name of the ruleset
Ruleset.dribblingDist = 0		-- a robot may not dribble the ball further than 'dribblingDist' (in metres)
Ruleset.shootSpeed = 0			-- the ball must not be shot faster than 'shootSpeed' (in metres per second)
Ruleset.stopBallDistance = 0	-- when in stop state, the robot must not be closer to the ball than 'stopBallDistance' (in metres)
Ruleset.numPlayers = 0			-- a team must not have more than 'numPlayers' robots on the field
Ruleset.stopSpeed = 0			-- when in stop state, no robot may move faster than 'stopSpeed' (in metres per second)


--[[ Stub to copy-paste:
	Ruleset.name =
	Ruleset.dribblingDist =
	Ruleset.shootSpeed =
	Ruleset.stopBallDistance =
	Ruleset.numPlayers =
	Ruleset.stopSpeed =
]]

-- should only be called from autoref/init.lua
function Ruleset.setRules(version)
	if version == "2017" then
		Ruleset.name = "2017"
		Ruleset.dribblingDist = 1
		Ruleset.shootSpeed = 8
		Ruleset.stopBallDistance = 0.5
		Ruleset.numPlayers = 6
		Ruleset.stopSpeed = 1.5
	elseif version == "2018: Division A" then
		Ruleset.name = "2018A"
		Ruleset.dribblingDist = 1
		Ruleset.shootSpeed = 6.5
		Ruleset.stopBallDistance = 0.5
		Ruleset.numPlayers = 8
		Ruleset.stopSpeed = 1.5
	elseif version == "2018: Division B" then
		Ruleset.name = "2018B"
		Ruleset.dribblingDist = 1
		Ruleset.shootSpeed = 6.5
		Ruleset.stopBallDistance = 0.5
		Ruleset.numPlayers = 6
		Ruleset.stopSpeed = 1.5
	else
		error("Attempt to set invalid ruleset: "..tostring(version))
	end
end

return Ruleset