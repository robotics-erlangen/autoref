--[[***********************************************************************
*   Copyright 2021 Andreas Wendler                                        *
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
local OutOfField = Class("ValidationRules.OutOfField", Rule)

local Referee = require "base/referee"
local LastTouch = require "validation-rules/lasttouch"
local World = require "validation-rules/trueworld"
local Event = require "gameevents"

OutOfField.possibleRefStates = {
	Game = true,
}

function OutOfField:occuring()
	local lastRobot, lastTouchPos = LastTouch.lastTouchRobotAndPos()
	if not lastRobot then
		return false
	end
	if math.abs(World.Ball.pos.y) > World.Geometry.FieldHeightHalf + World.Ball.radius then

		-- aimless kick check
		if ((World.Ball.pos.y > 0 and lastRobot.isYellow)
				or (World.Ball.pos.y < 0 and not lastRobot.isYellow))
				and lastTouchPos.y * World.Ball.pos.y < 0
				and not Referee.wasKickoff() then

			local event = Event.aimlessKick(lastRobot.isYellow, lastRobot.id, World.Ball.pos, lastTouchPos)
			return event
		end

		local event = Event.ballLeftField(lastRobot.isYellow, lastRobot.id, World.Ball.pos, true)
		return event
	end
	if math.abs(World.Ball.pos.x) > World.Geometry.FieldWidthHalf + World.Ball.radius then
		local event = Event.ballLeftField(lastRobot.isYellow, lastRobot.id, World.Ball.pos, false)
		return event
	end
end

return OutOfField