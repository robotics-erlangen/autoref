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
local Referee = require ((require "../base/basedir").."referee")
local World = require "../base/world"
local robotRadius = (require "../base/constants").maxRobotRadius

local lastTeam, lastRobot, lastTouchPos
local touchDist = World.Ball.radius+robotRadius
local fieldHeightHalf = World.Geometry.FieldHeightHalf
local fieldWidthHalf = World.Geometry.FieldWidthHalf
local noBallTouchStates = {
	Halt = true,
	Stop = true,
	KickoffOffensivePrepare = true,
	KickoffDefensivePrepare = true,
	PenaltyOffensivePrepare = true,
	PenaltyDefensivePrepare = true,
	TimeoutOffensive = true,
	TimeoutDefensive = true,
	BallPlacementDefensive = true,
	BallPlacementOffensive = true
}

Referee.touchDist = touchDist
--- Update the status of which team touched the ball last
-- @name checkTouching
function Referee.checkTouching()
	local ballPos = World.Ball.pos
	-- only consider touches when playing
	if noBallTouchStates[World.RefereeState] or
			math.abs(ballPos.x) > fieldWidthHalf or math.abs(ballPos.y) > fieldHeightHalf then
		return
	end
	for _, robot in ipairs(World.Robots) do
		if robot.pos:distanceTo(ballPos) <= touchDist then
			lastTeam = robot.isYellow and World.YellowColorStr or World.BlueColorStr
			lastRobot = robot
			lastTouchPos = Vector.createReadOnly(ballPos.x, ballPos.y)
			return
		end
	end
end

--- Get team which touched the ball last
-- @name teamWhichTouchedBallLast
-- @return string - team which touched the ball last
function Referee.teamWhichTouchedBallLast()
	return lastTeam
end

function Referee.robotAndPosOfLastBallTouch()
	return lastRobot, lastTouchPos
end

return Referee