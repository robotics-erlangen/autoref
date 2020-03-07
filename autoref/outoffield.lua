--[[***********************************************************************
*   Copyright 2019 Alexander Danzer, Andreas Wendler                      *
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

local OutOfField = {}

local Referee = require "../base/referee"
local debug = require "../base/debug"
local vis = require "../base/vis"
local World = require "../base/world"
local Parameters = require "../base/parameters"
local Event = require "gameevent2019"

local OUT_OF_FIELD_MIN_TIME = Parameters.add("outoffield", "OUT_OF_FIELD_MIN_TIME", 0.25)

OutOfField.possibleRefStates = {
    Game = true,
}

local wasBouncingAfterYellowTouch = false
local maxHeightAfterYellowTouch = 0
local wasBouncingAfterBlueTouch = false
local maxHeightAfterBlueTouch = 0
local wasInFieldBefore = false
local outOfFieldTime = math.huge
local outOfFieldPos = nil
local outOfFieldPosZ = 0
local waitingForDecision = false
local lastBlueRobot = nil
local lastYellowRobot = nil
local lastTouchPosition = nil
local rawOutOfFieldCounter = 0

-- Field.isInField considers the inside of the goal as in the field, this is not what we want here
local function isBallInField(ballPos)
    ballPos = ballPos or World.Ball.pos
    return math.abs(ballPos.y) < World.Geometry.FieldHeightHalf + World.Ball.radius and
            math.abs(ballPos.x) < World.Geometry.FieldWidthHalf + World.Ball.radius
end

function OutOfField.occuring()
    debug.set("bounce", World.Ball.isBouncing)
    local ballPos = World.Ball.pos
    local outOfFieldEvent -- for event message

    local previousPos = lastTouchPosition

    local lastTeam = Referee.teamWhichTouchedBallLast()
	local lastRobot, lastPos = Referee.robotAndPosOfLastBallTouch()
    lastTouchPosition = lastPos

    if lastTeam and lastRobot then
        -- "match" string to remove the font-tags
        debug.set("last ball touch", lastTeam:match(">(%a+)<") .. " " .. lastRobot.id)
		vis.addCircle("last ball touch", lastPos, 0.02, vis.colors.red, true)

		if lastRobot.isYellow then
			lastYellowRobot = lastRobot
		else
			lastBlueRobot = lastRobot
		end
    else
        waitingForDecision = false
        return false
	end

	if not waitingForDecision then
		if lastPos and lastPos ~= previousPos then
			-- reset bouncing when the ball is touched
			if lastRobot.isYellow then
				wasBouncingAfterYellowTouch = false
				maxHeightAfterYellowTouch = 0
			else
				wasBouncingAfterBlueTouch = false
				maxHeightAfterBlueTouch = 0
			end
		elseif isBallInField() then
			wasBouncingAfterYellowTouch = wasBouncingAfterYellowTouch or World.Ball.isBouncing
			wasBouncingAfterBlueTouch = wasBouncingAfterBlueTouch or World.Ball.isBouncing
			maxHeightAfterYellowTouch = math.max(maxHeightAfterYellowTouch, World.Ball.posZ)
			maxHeightAfterBlueTouch = math.max(maxHeightAfterBlueTouch, World.Ball.posZ)
		end

        if isBallInField() then
            wasInFieldBefore = true
        elseif wasInFieldBefore then
            outOfFieldTime = World.Time
            wasInFieldBefore = false
            outOfFieldPos = World.Ball.pos:copy()
            outOfFieldPosZ = World.Ball.posZ
            waitingForDecision = true
        end
    end

    if waitingForDecision then
        for _, pos in ipairs(World.Ball.rawPositions) do
            if not isBallInField(pos) then
                rawOutOfFieldCounter = rawOutOfFieldCounter + 1
            end
        end
    end
    if isBallInField() and not waitingForDecision then
        rawOutOfFieldCounter = 0
    end

    debug.set("wait decision", waitingForDecision)
    debug.set("in field before", wasInFieldBefore)
    debug.set("delay time", World.Time - outOfFieldTime)

    if waitingForDecision and World.Time - outOfFieldTime > OUT_OF_FIELD_MIN_TIME() then
        outOfFieldTime = math.huge -- reset
        waitingForDecision = false

        if rawOutOfFieldCounter < 5 then
            return false
        end

        OutOfField.executingTeam = World.YellowColorStr
        if Referee.teamWhichTouchedBallLast() == World.YellowColorStr then
             OutOfField.executingTeam = World.BlueColorStr
        end

        outOfFieldEvent = "Throw-In"
		vis.addCircle("ball out of play", World.Ball.pos, 0.02, vis.colors.blue, true)
		if math.abs(outOfFieldPos.y) > World.Geometry.FieldHeightHalf then -- out of goal line
            if (lastRobot.isYellow and outOfFieldPos.y>0) or (not lastRobot.isYellow and outOfFieldPos.y<0) then
                outOfFieldEvent = "Goal Kick"
            else
                outOfFieldEvent = "Corner Kick"
            end
            OutOfField.message = outOfFieldEvent .. " " .. OutOfField.executingTeam
            OutOfField.event = Event.ballLeftField(lastRobot.isYellow, lastRobot.id, outOfFieldPos, true)

            -- positive y position means blue side of field, negative yellow
            local icing = ((outOfFieldPos.y > 0 and lastTeam == World.YellowColorStr)
                or (outOfFieldPos.y < 0 and lastTeam == World.BlueColorStr))
                and lastPos.y * outOfFieldPos.y < 0
                and not Referee.wasKickoff() -- last touch was on other side of field

			if math.abs(outOfFieldPos.x) < World.Geometry.GoalWidth/2 then
                local scoringTeam = outOfFieldPos.y>0 and World.YellowColorStr or World.BlueColorStr
                -- TODO investigate ball position after min_time in order to
                -- determine goal post collisions: inside goal or defense area
                local side = outOfFieldPos.y<0 and "Yellow" or "Blue"
                local insideGoal = math.abs(ballPos.x) < World.Geometry.GoalWidth/2
                    and math.abs(ballPos.y) > World.Geometry.FieldHeightHalf
                    and math.abs(ballPos.y) <World.Geometry.FieldHeightHalf+0.2

                local closeToGoal = (World.Geometry[side.."Goal"]):distanceTo(World.Ball.pos) < 0.8
                debug.set("closeToGoal", closeToGoal)
                debug.set("insideGoal", insideGoal)

                debug.set("ball.pos.posZ", World.Ball.posZ)
				debug.set("wasz bounce (yellow bot)", wasBouncingAfterYellowTouch)
				debug.set("wasz bounce (blue bot)", wasBouncingAfterBlueTouch)
				local bounceCheck = (outOfFieldPos.y < 0 and wasBouncingAfterBlueTouch) or
					(outOfFieldPos.y > 0 and wasBouncingAfterYellowTouch)
				local wasIndirect = Referee.wasIndirect() and
					Referee.numTouchingRobotsSinceFreekickSelective(Referee.wasIndirectYellow()) <= 1 and
					Referee.wasIndirectYellow() == (side == "Blue")
                if bounceCheck or (outOfFieldPosZ > 0.15) then
                    wasBouncingAfterYellowTouch = false
					wasBouncingAfterBlueTouch = false
					local attackingRobot = side == "Yellow" and lastBlueRobot or lastYellowRobot
					local ballHeight = side == "Yellow" and maxHeightAfterBlueTouch or maxHeightAfterYellowTouch
                    OutOfField.message =  "<b>No Goal</b> for " .. scoringTeam .. ", ball was not in contact with the ground"
					-- TODO: max ball height
                    OutOfField.event = Event.chippedGoal(attackingRobot.isYellow, attackingRobot.id, outOfFieldPos, lastPos, ballHeight)
				elseif wasIndirect then
					local attackingRobot = Referee.wasIndirectYellow() and lastYellowRobot or lastBlueRobot
                    OutOfField.message = "<b>No goal</b> for "..scoringTeam..", was shot directly after an indirect"
                    OutOfField.event = Event.indirectGoal(Referee.wasIndirectYellow(), attackingRobot.id, outOfFieldPos, lastPos)
                elseif closeToGoal or insideGoal
                        or math.abs(ballPos.y) > World.Geometry.FieldHeightHalf+0.2 then -- math.abs(World.Ball.pos.x) < World.Geometry.GoalWidth/2
                    OutOfField.message =  "<b>Goal</b> for " .. scoringTeam
                    OutOfField.event = Event.goal(scoringTeam==World.YellowColorStr, lastRobot.isYellow, lastRobot.id, outOfFieldPos, lastPos)
                    return true
                else
                    OutOfField.event = nil
                    return false
                end
            elseif icing then
                outOfFieldEvent = "<b>Icing</b>"
                OutOfField.message =  outOfFieldEvent .. " of " .. Referee.teamWhichTouchedBallLast()
                OutOfField.event = Event.aimlessKick(lastRobot.isYellow, lastRobot.id, outOfFieldPos, lastPos)
            end
        else -- out off field line
            OutOfField.event = Event.ballLeftField(lastRobot.isYellow, lastRobot.id, outOfFieldPos, false)
            OutOfField.message = outOfFieldEvent .. " " .. OutOfField.executingTeam
        end

        return true
    end

    return false
end

return OutOfField
