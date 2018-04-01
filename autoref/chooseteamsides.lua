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

-- this is not a rule, but misueses this mecanism.
-- therefore 'occuring' should always return false

local Field = require "../base/field"
local World = require "../base/world"

local ChooseTeamSides = {}

ChooseTeamSides.possibleRefStates = {
    Halt = true,
    Stop = true,
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

local flipAttemptValue = true -- status is either true or false
local frameNumber = 0
local frameNumberOfLastFlipAttempt = 0
function ChooseTeamSides.occuring()
    frameNumber = frameNumber + 1
    -- ssl vision does not provide information about team sides.
    -- Therefore, we switch team sides if both goalies are located in the
    -- opponents defense area.
    if World.BlueKeeper and Field.isInYellowDefenseArea(World.BlueKeeper.pos, World.BlueKeeper.radius) and
            World.YellowKeeper and Field.isInBlueDefenseArea(World.YellowKeeper.pos, World.YellowKeeper.radius)
            and frameNumber > frameNumberOfLastFlipAttempt+5 then
        -- currently, the switch status is not retrievable. Therefore,
        -- if the flip was not effective we try again with the other possibility
        flipAttemptValue = not flipAttemptValue

        amun.sendCommand({ flip = flipAttemptValue })
        frameNumberOfLastFlipAttempt = frameNumber
    end

    return false
end

return ChooseTeamSides
