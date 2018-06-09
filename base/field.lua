--[[***********************************************************************
*   Copyright 2015 Alexander Danzer, Michael Eischer, Christian Lobmeier, *
*       André Pscherer                                                    *
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
local Field = require ((require "../base/basedir").."field")

local math = require "../base/math"
local World = require "../base/world"

local G = World.Geometry

--- Returns true if the position is inside/touching the yellow defense area
-- @name isInYellowDefenseArea
-- @param pos Vector - the position to check
-- @param radius number - Radius of object to check
-- @return bool
function Field.isInYellowDefenseArea(pos, radius)
	return Field.isInDefenseArea(pos, radius, true)
end

--- Returns true if the position is inside/touching the blue defense area
-- @name isInBlueDefenseArea
-- @param pos Vector - the position to check
-- @param radius number - Radius of object to check
-- @return bool
function Field.isInBlueDefenseArea(pos, radius)
	return Field.isInDefenseArea(pos, radius, false)
end

--- Calculates the distance (between robot hull and field line) to the yellow defense area
-- @name distanceToYellowDefenseArea
-- @param pos Vector - the position to check
-- @param radius number - Radius of object to check
-- @return number - distance
function Field.distanceToYellowDefenseArea(pos, radius)
	return Field.distanceToDefenseArea(pos, radius, true)
end

--- Calculates the distance (between robot hull and field line) to the blue defense area
-- @name distanceToBlueDefenseArea
-- @param pos Vector - the position to check
-- @param radius number - Radius of object to check
-- @return number - distance
function Field.distanceToBlueDefenseArea(pos, radius)
	return Field.distanceToDefenseArea(pos, radius, false)
end

local function limitAwayFromDefenseArea(pos, extraLimit)
	if Field.isInFriendlyDefenseArea(pos, extraLimit) then
		local targety = -G.FieldHeightHalf + G.DefenseHeight + extraLimit
		local targetx = G.DefenseWidthHalf + extraLimit
		local dy = targety - pos.y
		local dx = targetx - math.abs(pos.x)
		if dx > dy then
			return Vector(pos.x, targety)
		else
			return Vector(math.sign(pos.x)*targetx, pos.y)
		end
	elseif Field.isInOpponentDefenseArea(pos, extraLimit) then
		local targety = G.FieldHeightHalf - G.DefenseHeight - extraLimit
		local targetx = G.DefenseWidthHalf + extraLimit
		local dy = pos.y - targety
		local dx = targetx - math.abs(pos.x)
		if dx > dy then
			return Vector(pos.x, targety)
		else
			return Vector(math.sign(pos.x)*targetx, pos.y)
		end
	end
	return pos
end

function Field.limitToFreekickPosition(pos, executingTeam)
	pos = Field.limitToField(pos, -0.1)
	local ballSide = pos.y > 0 and "Blue" or "Yellow"
	local attackColor = executingTeam == World.BlueColorStr and "Blue" or "Yellow"

	if ballSide == attackColor and
			Field["distanceTo"..ballSide.."DefenseArea"](pos, 0) < 0.23 then
		-- closest point 600mm from the goal line and 100mm from the touch line
		pos = Vector(
			math.sign(pos.x) * G.FieldWidthHalf - math.sign(pos.x)*0.1,
			math.sign(pos.y) * G.FieldHeightHalf - math.sign(pos.y)*0.6
		)
	elseif Field["distanceTo"..ballSide.."DefenseArea"](pos, 0) < 0.73 and ballSide ~= attackColor then
		-- closest point 700mm from the defense area (plus some extra distance)
		pos = limitAwayFromDefenseArea(pos, 0.73)
	end

	return pos
end

return Field
