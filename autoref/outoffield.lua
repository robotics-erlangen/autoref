--[[***********************************************************************
*   Copyright 2015 Alexander Danzer                                       *
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

local OUT_OF_FIELD_MIN_TIME = 0.1

OutOfField.possibleRefStates = {
    Game = true
}

local wasInFieldBefore = false
local outOfFieldTime = math.huge
function OutOfField.occuring()
    local ballPos = World.Ball.pos
    local outOfFieldEvent = "" -- for event message

    local lastTeam = Referee.teamWhichTouchedBallLast()
    local lastRobot, lastPos = Referee.robotAndPosOfLastBallTouch()
    if lastTeam then
        -- "match" string to remove the font-tags
        debug.set("last ball touch", lastTeam:match(">(%a+)<") .. " " .. lastRobot.id)
        vis.addCircle("last ball touch", lastPos, 0.02, vis.colors.red, true)
    end

    if Field.isInField(ballPos, World.Ball.radius) then
        wasInFieldBefore = true
    elseif wasInFieldBefore and lastRobot then -- we detected the ball going out of field
        -- delay decision to increase certainty, because the tracking is not always reliable
        outOfFieldTime = World.Time
        wasInFieldBefore = false -- reset
    elseif World.Time - outOfFieldTime > OUT_OF_FIELD_MIN_TIME and lastRobot then
        outOfFieldTime = math.huge -- reset

        OutOfField.executingTeam = World.YellowColorStr
        if Referee.teamWhichTouchedBallLast() == World.YellowColorStr then
             OutOfField.executingTeam = World.BlueColorStr
        end

        local freekickType = "INDIRECT_FREE"
        outOfFieldEvent = "Throw-In"
        if math.abs(ballPos.y) > World.Geometry.FieldHeightHalf then -- out of goal line

            OutOfField.freekickPosition = Vector( -- 10cm from the corner
                (World.Geometry.FieldWidthHalf - 0.1) * math.sign(ballPos.x),
                (World.Geometry.FieldHeightHalf - 0.1) * math.sign(ballPos.y)
            )
            freekickType = "DIRECT_FREE"
            if (lastRobot.isYellow and ballPos.y>0) or (not lastRobot.isYellow and ballPos.y<0) then
                outOfFieldEvent = "Goal Kick"
            else
                outOfFieldEvent = "Corner Kick"
            end

            -- positive y position means blue side of field, negative yellow
            local icing = ((ballPos.y > 0 and lastTeam == World.YellowColorStr)
                or (ballPos.y < 0 and lastTeam == World.BlueColorStr))
                and lastPos.y * ballPos.y < 0 -- last touch was on other side of field

            if math.abs(ballPos.x) < World.Geometry.GoalWidth/2 then
                local team = ballPos.y>0 and World.YellowColorStr or World.BlueColorStr
                log("(probably) <b>goal</b> for " .. team .. "!")
                return false
            elseif icing then
                OutOfField.executingTeam = lastRobot.isYellow and World.BlueColorStr or World.YellowColorStr
                OutOfField.freekickPosition = lastPos
                freekickType = "INDIRECT_FREE"
                outOfFieldEvent = "Indirect because of Icing"
            end
        else -- out off field line
            OutOfField.freekickPosition = Vector( -- 10cm from field line
                (World.Geometry.FieldWidthHalf - 0.1) * math.sign(ballPos.x),
                ballPos.y
            )
        end

        OutOfField.consequence = freekickType .. "_" .. OutOfField.executingTeam:match(">(%a+)<"):upper()
        OutOfField.message = "Ball out field. Last touch: " .. Referee.teamWhichTouchedBallLast()
            .. "<br>" .. outOfFieldEvent .. " for " .. OutOfField.executingTeam
        return true
    end

    return false
end

return OutOfField
