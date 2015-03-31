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
    if Field.isInField(World.Ball.pos, World.Ball.radius) then
        wasInFieldBefore = true
    elseif wasInFieldBefore then -- we detected the ball going out of field
        wasInFieldBefore = false -- reset
        return true
    end

    return false
end

function OutOfField.print()
    log("Ball out field. Last touch: " .. Referee.teamWhichTouchedBallLast())
end

return OutOfField
