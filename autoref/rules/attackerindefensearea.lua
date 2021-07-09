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
local AttackerInDefenseArea = Class("Rules.AttackerInDefenseArea", Rule)

local Field = require "base/field"
local Referee = require "base/referee"
local World = require "base/world"
local Event = require "gameevents"

AttackerInDefenseArea.possibleRefStates = {
    Game = true
}

function AttackerInDefenseArea:occuring()
	for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
		if Field["isIn"..defense.."DefenseArea"](World.Ball.pos, World.Ball.radius) then
			for _, robot in ipairs(World[offense.."Robots"]) do
				-- attacker touches ball while the ball is in the defense area
				if World.Ball.posZ == 0 and robot.pos:distanceTo(World.Ball.pos) <= Referee.touchDist then
					local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
					local message = color .. " " .. robot.id ..
						" touched the ball in defense area"
					-- TODO: distance in defense area
					local event = Event.attackerInDefenseArea(robot.isYellow, robot.id, robot.pos)
					return event, message
				end
			end
		end
    end
end

return AttackerInDefenseArea
