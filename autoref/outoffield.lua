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

OutOfField.possibleRefStates = {
    Game = true
}

local function isInField()
    return Field.isInField(World.Ball.pos, World.Ball.radius)
end

local wasInFieldBefore = false
function OutOfField.occuring()
    local ballPos = World.Ball.pos

    if Field.isInField(ballPos, World.Ball.radius) then
        wasInFieldBefore = true
    elseif wasInFieldBefore then -- we detected the ball going out of field
        wasInFieldBefore = false -- reset

        OutOfField.executingTeam = World.YellowColorStr
        if Referee.teamWhichTouchedBallLast() == World.YellowColorStr then
             OutOfField.executingTeam = World.BlueColorStr
        end

        local freekickType = "INDIRECT_FREE"
        if math.abs(ballPos.y) > World.Geometry.FieldHeightHalf then
            if math.abs(ballPos.x) < World.Geometry.GoalWidth/2 then
                log("(probably) goal!")
                return false
            end
            freekickType = "DIRECT_FREE"
        end

        OutOfField.consequence = freekickType .. "_" .. OutOfField.executingTeam:match(">(%a+)<"):upper()

        OutOfField.freekickPosition = Vector(
            (World.Geometry.FieldWidthHalf - 0.1) * math.sign(ballPos.x),
            ballPos.y
        )
        if freekickType == "DIRECT_FREE" then
            OutOfField.freekickPosition.y = (World.Geometry.FieldHeightHalf - 0.1) * math.sign(ballPos.y)
        end

        return true
    end

    return false
end

function OutOfField.print()
    log("Ball out field. Last touch: " .. Referee.teamWhichTouchedBallLast())
end

return OutOfField
