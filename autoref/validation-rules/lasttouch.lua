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

local LastTouch = {}

local World = require "validation-rules/trueworld"

local lastTouchRobot = nil
local lastTouchPos = nil
function LastTouch.update()
	-- TODO: handle two robots touching the ball at the same time
	for _, robot in ipairs(World.Robots) do
		if robot.isTouchingBall then
			lastTouchRobot = robot
			lastTouchPos = World.Ball.pos
		end
	end
end

function LastTouch.lastTouchRobotAndPos()
	return lastTouchRobot, lastTouchPos
end

return LastTouch