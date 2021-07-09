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

local Rule = require "rules/rule"
local Class = require "base/class"
local OutOfField = Class("Rules.OutOfField", Rule)

local Referee = require "base/referee"
local debug = require "base/debug"
local vis = require "base/vis"
local World = require "base/world"
local Event = require "gameevents"

local OUT_OF_FIELD_MIN_TIME = 0.25

OutOfField.possibleRefStates = {
    Game = true,
}

function OutOfField:init()
	self.maxHeightAfterYellowTouch = 0
	self.maxHeightAfterBlueTouch = 0
	self.wasInFieldBefore = false
	self.outOfFieldTime = math.huge
	self.outOfFieldPos = nil
	self.waitingForDecision = false
	self.lastTouchPosition = nil
	self.rawOutOfFieldCounter = 0
end

-- Field.isInField considers the inside of the goal as in the field, this is not what we want here
local function isBallInField(ballPos)
    ballPos = ballPos or World.Ball.pos
    return math.abs(ballPos.y) < World.Geometry.FieldHeightHalf + World.Ball.radius and
            math.abs(ballPos.x) < World.Geometry.FieldWidthHalf + World.Ball.radius
end

function OutOfField:occuring()
    local ballPos = World.Ball.pos
    local outOfFieldEvent -- for event message

    local previousPos = self.lastTouchPosition

    local lastTeam = Referee.teamWhichTouchedBallLast()
	local lastRobot, lastPos = Referee.robotAndPosOfLastBallTouch()
    self.lastTouchPosition = lastPos

    if lastTeam and lastRobot then
        -- "match" string to remove the font-tags
        debug.set("last ball touch", lastTeam:match(">(%a+)<") .. " " .. lastRobot.id)
		vis.addCircle("last ball touch", lastPos, 0.02, vis.colors.red, true)
    else
        self.waitingForDecision = false
        return
	end

	if not self.waitingForDecision then
		if lastPos and lastPos ~= previousPos then
			-- reset bouncing when the ball is touched
			if lastRobot.isYellow then
				self.maxHeightAfterYellowTouch = 0
			else
				self.maxHeightAfterBlueTouch = 0
			end
		elseif isBallInField() then
			self.maxHeightAfterYellowTouch = math.max(self.maxHeightAfterYellowTouch, World.Ball.posZ)
			self.maxHeightAfterBlueTouch = math.max(self.maxHeightAfterBlueTouch, World.Ball.posZ)
		end

        if isBallInField() then
            self.wasInFieldBefore = true
        elseif self.wasInFieldBefore then
            self.outOfFieldTime = World.Time
            self.wasInFieldBefore = false
            self.outOfFieldPos = World.Ball.pos:copy()
            self.waitingForDecision = true
        end
    end

    if self.waitingForDecision then
        for _, pos in ipairs(World.Ball.rawPositions) do
            if not isBallInField(pos) then
                self.rawOutOfFieldCounter = self.rawOutOfFieldCounter + 1
            end
        end
    end
    if isBallInField() and not self.waitingForDecision then
        self.rawOutOfFieldCounter = 0
    end

    debug.set("wait decision", self.waitingForDecision)
    debug.set("in field before", self.wasInFieldBefore)
    debug.set("delay time", World.Time - self.outOfFieldTime)

    if self.waitingForDecision and World.Time - self.outOfFieldTime > OUT_OF_FIELD_MIN_TIME then
        self.outOfFieldTime = math.huge -- reset
        self.waitingForDecision = false

        if self.rawOutOfFieldCounter < 5 then
            -- although the ball might currently not be inside the field, this variable needs to be reset
            -- if there were less than 5 raw frames, but the ball is not actually outside of the field,
            -- this grants another chance to recognize it
            self.wasInFieldBefore = true
            return
        end

        local executingTeam = World.YellowColorStr
        if Referee.teamWhichTouchedBallLast() == World.YellowColorStr then
             executingTeam = World.BlueColorStr
        end

        outOfFieldEvent = "Throw-In"
		vis.addCircle("ball out of play", World.Ball.pos, 0.02, vis.colors.blue, true)
		local event, message
		if math.abs(self.outOfFieldPos.y) > World.Geometry.FieldHeightHalf then -- out of goal line
            if (lastRobot.isYellow and self.outOfFieldPos.y>0) or (not lastRobot.isYellow and self.outOfFieldPos.y<0) then
                outOfFieldEvent = "Goal Kick"
            else
                outOfFieldEvent = "Corner Kick"
            end
            message = outOfFieldEvent .. " " .. executingTeam
            event = Event.ballLeftField(lastRobot.isYellow, lastRobot.id, self.outOfFieldPos, true)

            -- positive y position means blue side of field, negative yellow
            local icing = ((self.outOfFieldPos.y > 0 and lastTeam == World.YellowColorStr)
                or (self.outOfFieldPos.y < 0 and lastTeam == World.BlueColorStr))
                and lastPos.y * self.outOfFieldPos.y < 0
                and not Referee.wasKickoff() -- last touch was on other side of field

			if math.abs(self.outOfFieldPos.x) < World.Geometry.GoalWidth/2 then
                local scoringTeam = self.outOfFieldPos.y>0 and World.YellowColorStr or World.BlueColorStr
                -- TODO investigate ball position after min_time in order to
                -- determine goal post collisions: inside goal or defense area
                local side = self.outOfFieldPos.y<0 and "Yellow" or "Blue"
                local insideGoal = math.abs(ballPos.x) < World.Geometry.GoalWidth/2
                    and math.abs(ballPos.y) > World.Geometry.FieldHeightHalf
                    and math.abs(ballPos.y) <World.Geometry.FieldHeightHalf+0.2

                local closeToGoal = (World.Geometry[side.."Goal"]):distanceTo(World.Ball.pos) < 0.8

                if closeToGoal or insideGoal
                        or math.abs(ballPos.y) > World.Geometry.FieldHeightHalf+0.2 then -- math.abs(World.Ball.pos.x) < World.Geometry.GoalWidth/2
                    message =  "<b>Goal</b> for " .. scoringTeam
                    local forYellow = scoringTeam == World.YellowColorStr
                    event = Event.goal(forYellow, lastRobot.isYellow, lastRobot.id,
					self.outOfFieldPos, lastPos, forYellow and self.maxHeightAfterYellowTouch or self.maxHeightAfterBlueTouch)
                    return event, message
                else
                    event = nil
                    return
                end
            elseif icing then
                outOfFieldEvent = "<b>Icing</b>"
                message =  outOfFieldEvent .. " of " .. Referee.teamWhichTouchedBallLast()
                event = Event.aimlessKick(lastRobot.isYellow, lastRobot.id, self.outOfFieldPos, lastPos)
            end
        else -- out off field line
            event = Event.ballLeftField(lastRobot.isYellow, lastRobot.id, self.outOfFieldPos, false)
            message = outOfFieldEvent .. " " .. executingTeam
        end

        return event, message
    end
end

return OutOfField
