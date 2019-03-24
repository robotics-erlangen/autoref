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
local Field = require "../base/field"
local debug = require "../base/debug"
local vis = require "../base/vis"
local World = require "../base/world"
local Parameters = require "../base/parameters"
local Event = require "gameevent2019"

local OUT_OF_FIELD_MIN_TIME = Parameters.add("outoffield", "OUT_OF_FIELD_MIN_TIME", 0.25)

OutOfField.possibleRefStates = {
    Game = true,
}

local wasBouncing = false
local wasInFieldBefore = false
local outOfFieldTime = math.huge
local outOfFieldPos = nil
local outOfFieldPosZ = 0
local waitingForDecision = false

function OutOfField.occuring()
    debug.set("bounce", World.Ball.isBouncing)
    local ballPos = World.Ball.pos
    local outOfFieldEvent -- for event message

    local lastTeam = Referee.teamWhichTouchedBallLast()
    local lastRobot, lastPos = Referee.robotAndPosOfLastBallTouch()
    if lastTeam and lastRobot then
        -- "match" string to remove the font-tags
        debug.set("last ball touch", lastTeam:match(">(%a+)<") .. " " .. lastRobot.id)
        vis.addCircle("last ball touch", lastPos, 0.02, vis.colors.red, true)
    else
        waitingForDecision = false
        return false
    end

    if not waitingForDecision then
        if Field.isInField(ballPos, World.Ball.radius) then
            wasInFieldBefore = true
        elseif wasInFieldBefore  then
            outOfFieldTime = World.Time
            wasInFieldBefore = false
            outOfFieldPos = World.Ball.pos:copy()
            outOfFieldPosZ = World.Ball.posZ
            wasBouncing = World.Ball.isBouncing
            waitingForDecision = true
        end
    end

    debug.set("wait decision", waitingForDecision)
    debug.set("in field before", wasInFieldBefore)
    debug.set("delay time", World.Time - outOfFieldTime)

    if waitingForDecision and World.Time - outOfFieldTime > OUT_OF_FIELD_MIN_TIME() then
        outOfFieldTime = math.huge -- reset
        waitingForDecision = false

        OutOfField.executingTeam = World.YellowColorStr
        if Referee.teamWhichTouchedBallLast() == World.YellowColorStr then
             OutOfField.executingTeam = World.BlueColorStr
        end

        local freekickType = "INDIRECT_FREE"
        outOfFieldEvent = "Throw-In"
        vis.addCircle("ball out of play", World.Ball.pos, 0.02, vis.colors.blue, true)
        if math.abs(outOfFieldPos.y) > World.Geometry.FieldHeightHalf then -- out of goal line
            freekickType = "DIRECT_FREE"
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
                debug.set("wasz bounce", wasBouncing)
                if wasBouncing or (outOfFieldPosZ > 0) then
                    wasBouncing = false
                    OutOfField.message =  "<b>No Goal</b> for " .. scoringTeam .. ", ball was not in contact with the ground"
                    -- TODO: max ball height
                    OutOfField.event = Event.chippedGoal(lastRobot.isYellow, lastRobot.id, outOfFieldPos, lastPos)
                elseif Referee.wasIndirect() and Referee.numTouchingRobotsSinceFreekick() <= 1 then
                    OutOfField.message = "<b>No goal</b> for "..scoringTeam..", was shot directly after an indirect"
                    OutOfField.event = Event.indirectGoal(lastRobot.isYellow, lastRobot.id, outOfFieldPos, lastPos)
                elseif closeToGoal or insideGoal
                        or math.abs(ballPos.y) > World.Geometry.FieldHeightHalf+0.2 then -- math.abs(World.Ball.pos.x) < World.Geometry.GoalWidth/2
                    OutOfField.message =  "<b>Goal</b> for " .. scoringTeam
                    -- TODO: this will be changed in a newer game controller protocol version
                    OutOfField.event = Event.goal(scoringTeam==World.YellowColorStr, lastRobot.id, outOfFieldPos, lastPos)
                    return true
                else
                    OutOfField.event = nil
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
