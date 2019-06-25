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

local AttackerTouchRobotInDefenseArea = {}

local Field = require "../base/field"
local World = require "../base/world"
local Event = require "gameevent2019"

AttackerTouchRobotInDefenseArea.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

function AttackerTouchRobotInDefenseArea.occuring()
	for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
		for _, defender in ipairs(World[defense .. "Robots"]) do
			if Field["isIn" .. defense .. "DefenseArea"](defender.pos, defender.radius + 0.02) then
				for _, offender in ipairs(World[offense .. "Robots"]) do
					local dist = offender.pos:distanceTo(defender.pos)
					if dist < defender.radius + offender.radius then
						local pointOfContact = offender.pos + (defender.pos - offender.pos):setLength(dist / 2)
						local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
						AttackerTouchRobotInDefenseArea.message = color .. " " .. offender.id ..
							" touched goalie inside defense area"
							AttackerTouchRobotInDefenseArea.event = Event.attackerTouchOpponentInDefenseArea(offender.isYellow, offender.id, pointOfContact, defender.id)
						return true
					end
				end
			end
		end
    end
end

return AttackerTouchRobotInDefenseArea
