--[[***********************************************************************
*   Copyright 2018 Alexander Danzer, Andreas Wendler                      *
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

--[[ 12.3:
An indirect free kick is also awarded to the opposing team if a robot:
touches the ball such that the ball touches an opponent robot and travels along with the op-
ponent robot in direction of the opponent robot for more than 200 mm or until the opponent
enters its defense area, while both robots keep contact to the ball]]

local Pushing = {}

local World = require "../base/world"
local Field = require "../base/field"
local Referee = require "../base/referee"
local Parameters = require "../base/parameters"
local geom = require "../base/geom"
local Event = require "gameevent2019"
local debug = require "../base/debug"


Pushing.possibleRefStates = {
    Game = true,
}

local MAX_PUSH_DIST = Parameters.add("pushing", "MAX_PUSH_DIST", 0.2)
local MIN_PUSH_DIST_FOR_DEFENSE_AREA = Parameters.add("pushing", "MIN_PUSH_DIST_FOR_DEFENSE_AREA", 0.03)
local PUSHING_CONE_ANGLE = Parameters.add("pushing", "PUSHING_CONE_ANGLE", 10)
local RESET_FRAME_COUNT = Parameters.add("pushing", "RESET_FRAME_COUNT", 10)

local pushLengths = {Blue = 0, Yellow = 0}
local lastRobots = {}
local lastRobotPositions = {}
local wrongDirectionFrameCounter = {Blue = 0, Yelow = 0}
function Pushing.occuring()
	-- find holding robots
	local coneAngle = PUSHING_CONE_ANGLE() * math.pi / 180
	local holding = {Yellow = {}, Blue = {}}
	for _, robot in ipairs(World.Robots) do
		local dist = robot.pos:distanceTo(World.Ball.pos)
		if dist <= Referee.touchDist then
			local teamStr = robot.isYellow and "Yellow" or "Blue"
			if #holding[teamStr] == 0 then
				table.insert(holding[teamStr], robot)
			elseif dist < holding[teamStr][1].pos:distanceTo(World.Ball.pos) then
				holding[teamStr][1] = robot
			end
		end
	end
	if #holding.Yellow ~= 1 or #holding.Blue ~= 1 then
		Pushing.reset()
		return false
	end
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
		-- TODO: íf the distance is not yet reached, disable multipledefender and continue
		local offRobot = holding[offense][1]
		local defRobot = holding[defense][1]
		if Field["isIn"..defense.."DefenseArea"](defRobot.pos, holding[defense][1].radius) then
			if pushLengths[offense] < MIN_PUSH_DIST_FOR_DEFENSE_AREA() then
				-- disable multipledefender, don't issue anything
				debug.set("Pushing/not yet clear")
			else
				Pushing.message = offense.." "..offRobot.id.." pushed "..defense.." "..defRobot.id.." into the defense area"
				Pushing.event = Event.pushing(offRobot.isYellow, offRobot.id, defRobot.id, World.Ball.pos, pushLengths[offense])
				return true
			end
		end

		-- check robot
		if not lastRobots[offense] or lastRobots[offense] ~= offRobot then
			lastRobots[offense] = offRobot
			pushLengths[offense] = 0
			lastRobotPositions[offense] = offRobot.pos
			wrongDirectionFrameCounter[offense] = 0
			return false
		end

		-- check if direction is in pushing cone
		-- TODO: smooth direction, but use actual length
		local centerAngle = (offRobot.pos - lastRobotPositions[offense]):angle()
		local isInside = geom.isInTriangle(offRobot.pos, offRobot.pos + Vector.fromAngle(centerAngle + coneAngle),
			offRobot.pos + Vector.fromAngle(centerAngle - coneAngle), defRobot.pos)
		if isInside then
			wrongDirectionFrameCounter[offense] = wrongDirectionFrameCounter[offense] + 1
			if wrongDirectionFrameCounter[offense] >= RESET_FRAME_COUNT() then
				pushLengths[offense] = 0
			end
		else
			wrongDirectionFrameCounter[offense] = 0
			pushLengths[offense] = pushLengths[offense] + (lastRobotPositions[offense] - offRobot.pos):length()
		end

		-- check length
		if pushLengths[offense] > MAX_PUSH_DIST() then
			Pushing.message = offense.." "..offRobot.id.." pushed "..defense.." "..defRobot.id.." fo 20 cm"
			Pushing.event = Event.pushing(offRobot.isYellow, offRobot.id, defRobot.id, World.Ball.pos, pushLengths[offense])
			return true
		end

		lastRobotPositions[offense] = offRobot.pos
    end
    return false
end

function Pushing.reset()
	for offense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
		lastRobots[offense] = nil
		pushLengths[offense] = 0
		lastRobotPositions[offense] = nil
		wrongDirectionFrameCounter[offense] = 0
	end
end

return Pushing
