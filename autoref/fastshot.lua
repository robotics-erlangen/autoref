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

local Referee = require "../base/referee"

local FastShot = {}

FastShot.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

local lastSpeeds = {}
local maxSpeed = 0
function FastShot.occuring()
    local speed = World.Ball.speed:length()
    if speed > 8 then
        table.insert(lastSpeeds, speed)
        local maxVal = 0
        -- we take the maximum from the 5 last frames above 8m/s
        if #lastSpeeds > 4 then
            for _, val in ipairs(lastSpeeds) do
                if val > maxVal then
                    maxVal = val
                end
            end
        end
        if maxVal ~= 0 then
            maxSpeed = maxVal
            lastSpeeds = {}
            return true
        end
    else -- don't keep single values from flickering
        lastSpeeds = {}
    end
    return false
end

function FastShot.print()
    local offending = Referee.teamWhichTouchedBallLast()
    log("Shot over 8m/s by " .. offending .. " team")
    log("Speed: " .. maxSpeed .. "m/s")
    maxSpeed = 0
end

return FastShot
