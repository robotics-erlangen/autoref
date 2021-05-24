--[[
--- Referee utility functions
module "Referee"
]]--

--[[***********************************************************************
*   Copyright 2015 Alexander Danzer, Michael Eischer, Christian Lobmeier  *
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

local Referee = {}

local robotRadius = (require "base/constants").maxRobotRadius -- avoid table lookups for speed reasons
local vis = require "base/vis"
local World = require "base/world"


-- states, in which we must keep a dist of 50cm
local stopStates = {
	Stop = true,
	KickoffDefensivePrepare = true,
	KickoffDefensive = true,
	DirectDefensive = true,
	IndirectDefensive = true,
	BallPlacementDefensive = true,
	BallPlacementOffensive = true
}

-- states in which the maximum speed is 1.5 m/s
local slowDriveStates = {
	Stop = true,
	BallPlacementDefensive = true,
	BallPlacementOffensive = true
}

local friendlyFreeKickStates = {
	DirectOffensive = true,
	IndirectOffensive = true
}

local kickoffStates = {
	KickoffDefensivePrepare = true,
	KickoffDefensive = true,
	KickoffOffensivePrepare = true,
	KickoffOffensive = true
}

local opponentPenaltyStates = {
	PenaltyDefensivePrepare = true,
	PenaltyDefensive = true
}

local friendlyPenaltyStates = {
	PenaltyOffensivePrepare = true,
	PenaltyOffensive = true
}

local gameStates = {
	Game = true,
	GameForce = true
}

local nonGameStages = {
	FirstHalfPre = true,
	HalfTime = true,
	SecondHalfPre = true,
	ExtraTimeBreak = true,
	ExtraFirstHalfPre = true,
	ExtraHalfTime = true,
	ExtraSecondHalfPre = true,
	PenaltyShootoutBreak = true,
	PostGame = true
}

--- Check whether the stop rules apply
-- @name isStopState
-- @return boolean - True if the current referee state is considered as stop
function Referee.isStopState()
	return stopStates[World.RefereeState]
end

--- Check whether the robot has to drive a maximum of 1.5 m/s (slow)
-- @name isSlowDriveState
-- @return boolean - True if all robots have to drive slowly (< 1.5 m/s)
function Referee.isSlowDriveState()
	return slowDriveStates[World.RefereeState]
end

--- Check whether we have a freekick
-- @name isFriendlyFreeKickState
-- @return boolean - True if the current referee state is a freekick for us
function Referee.isFriendlyFreeKickState()
	return friendlyFreeKickStates[World.RefereeState]
end

--- Check whether this is a kickoff
-- @name isKickoffState
-- @return boolean - True if the current referee state is a kickoff
function Referee.isKickoffState()
	return kickoffStates[World.RefereeState]
end

--- Check whether the opponent has a penalty
-- @name isOpponentPenaltyState
-- @return boolean - True if the opponent has a penalty
function Referee.isOpponentPenaltyState()
	return opponentPenaltyStates[World.RefereeState]
end

function Referee.isFriendlyPenaltyState()
	return friendlyPenaltyStates[World.RefereeState]
end

function Referee.isGameState()
	return gameStates[World.RefereeState]
end

function Referee.isNonGameStage()
	return nonGameStages[World.GameStage]
end

local rightLine = World.Geometry.FieldWidthHalf
local leftLine = -rightLine
local goalLine = World.Geometry.FieldHeightHalf
local cornerDist = 0.7 -- some tolerance, rules say 10cm
--- Check whether there is a freekick in the opponent corner
-- @name isOffensiveCornerKick
-- @return boolean - True if a corner kick in the opponents corner
function Referee.isOffensiveCornerKick()
	local ballPos = World.Ball.pos
	local refState = World.RefereeState
	return (refState == "DirectOffensive" or refState == "IndirectOffensive")
		and goalLine - ballPos.y < cornerDist
		and (leftLine - ballPos.x > -cornerDist or rightLine - ballPos.x < cornerDist)
end

--- Check whether there is a freekick in our corner
-- @name isDefensiveCornerKick
-- @return boolean - True if a corner kick in our corner
function Referee.isDefensiveCornerKick()
	local ballPos = World.Ball.pos
	local refState = World.RefereeState
	return (refState == "DirectDefensive" or refState == "IndirectDefensive" or refState == "Stop")
		and -goalLine - ballPos.y > -cornerDist
		and (leftLine - ballPos.x > -cornerDist or rightLine - ballPos.x < cornerDist)
end

--- Draw areas forbidden by the current referee command
-- @name illustrateRefereeStates
function Referee.illustrateRefereeStates()
	if World.RefereeState == "PenaltyDefensivePrepare" or World.RefereeState == "PenaltyDefensive" then
		vis.addPath("penaltyDistanceAllowed", {Vector(-2,World.Geometry.OwnPenaltyLine), Vector(2,World.Geometry.OwnPenaltyLine)}, vis.colors.red)
	elseif World.RefereeState == "PenaltyOffensivePrepare" or World.RefereeState == "PenaltyOffensive" then
		vis.addPath("penaltyDistanceAllowed", {Vector(-2,World.Geometry.PenaltyLine), Vector(2,World.Geometry.PenaltyLine)}, vis.colors.red)
	elseif Referee.isStopState() then
		vis.addCircle("stopstateBallDist", World.Ball.pos, 0.5, vis.colors.redHalf, true)
	end
end


local lastTeam, lastRobot, lastTouchPos
local touchDist = World.Ball.radius+robotRadius
local fieldHeightHalf = World.Geometry.FieldHeightHalf
local fieldWidthHalf = World.Geometry.FieldWidthHalf
local noBallTouchStates = {
	Halt = true,
	Stop = true,
	KickoffBluePrepare = true,
	KickoffYellowPrepare = true,
	PenaltyYellowPrepare = true,
	PenaltyBluePrepare = true,
	TimeoutBlue = true,
	TimeoutYellow = true,
	BallPlacementBlue = true,
	BallPlacementYellow = true
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
    if World.Ball.posZ ~= 0 then
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

local freekickStates = {
	DirectYellow = true,
	IndirectYellow = true,
	DirectBlue = true,
	IndirectBlue = true,
}
Referee.lastFreekick = nil
local touchingRobotsSinceFreekick = {}
function Referee.updateFreekickstate()
	if freekickStates[World.RefereeState] then
		Referee.lastFreekick = World.RefereeState
	end
	if World.RefereeState ~= "Game" and
		not freekickStates[World.RefereeState] then
		touchingRobotsSinceFreekick = {}
	else
		for _, robot in ipairs(World.Robots) do
			if robot.pos:distanceTo(World.Ball.pos) < Referee.touchDist then
				touchingRobotsSinceFreekick[robot] = World.Time
			end
		end
	end
end

function Referee.numTouchingRobotsSinceFreekick()
	return table.count(touchingRobotsSinceFreekick)
end

function Referee.numTouchingRobotsSinceFreekickSelective(yellowRobots)
	local lastTouchTime = 0
	for r, time in pairs(touchingRobotsSinceFreekick) do
		if (r.isYellow and yellowRobots) or (not r.isYellow and not yellowRobots) then
			if time > lastTouchTime then
				lastTouchTime = time
			end
		end
	end
	local counter = 1
	for _, time in pairs(touchingRobotsSinceFreekick) do
		if time < lastTouchTime then
			counter = counter + 1
		end
	end
	return counter
end

function Referee.wasIndirect()
	return Referee.lastFreekick == "IndirectBlue" or
		Referee.lastFreekick == "IndirectYellow"
end

function Referee.wasIndirectYellow()
	return Referee.lastFreekick == "IndirectYellow"
end

local lastNonGameState = nil
local function updateGameStates()
	if World.RefereeState ~= "Game" and World.RefereeState ~= "GameForce" then
		lastNonGameState = World.RefereeState
	end
end

function Referee.getLastNonGameState()
	return lastNonGameState
end

function Referee.wasKickoff()
	return lastNonGameState == "KickoffBlue" or lastNonGameState == "KickoffYellow"
end

function Referee.update()
	updateGameStates()
	Referee.updateFreekickstate()
	Referee.checkTouching()
end
return Referee
