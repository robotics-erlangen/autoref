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
local FastShot = Class("ValidationRules.FastShot", Rule)

local LastTouch = require "validation-rules/lasttouch"
local World = require "validation-rules/trueworld"
local Event = require "gameevents"

FastShot.possibleRefStates = {
    Game = true,
	GameForce = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true
}

local MAX_SHOOT_SPEED = 6.5

function FastShot:occuring()
	local lastRobot, lastTouchPos = LastTouch.lastTouchRobotAndPos()
	if not lastRobot then
		return false
	end
	if World.Ball.speed:length() > MAX_SHOOT_SPEED then
		local color = lastRobot.isYellow and World.YellowColorStr or World.BlueColorStr
		local message = "(truth) Shot over "..MAX_SHOOT_SPEED.." m/s by " .. color .. " " .. lastRobot.id
		local event = Event.fastShot(lastRobot.isYellow, lastRobot.id, lastTouchPos, World.Ball.speed:length())
		return event, message
	end
end

return FastShot