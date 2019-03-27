--[[***********************************************************************
*   Copyright 2019 Andreas Wendler                                        *
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

local KeeperBallHolding = {}

local World = require "../base/world"
local Field = require "../base/field"
local Event = require "gameevent2019"

-- Rule 8.1.2. Lack Of Progress:
-- There is also a lack of progress if the ball is inside a team’s defense area for 10 seconds,
-- since the keeper is the only robot that is allowed to manipulate the ball.
KeeperBallHolding.possibleRefStates = {
    Game = true,
}

local MAX_DEFENSE_AREA_TIME = 10 -- as specified by the rules

local defenseAreaStartTimes = {}
function KeeperBallHolding.occuring()
    for _, side in ipairs {"Yellow", "Blue"} do
        if not defenseAreaStartTimes[side] then
            defenseAreaStartTimes[side] = World.Time
        end
        
        if Field["isIn"..side.."DefenseArea"](World.Ball.pos, 0) then
            local inDefenseAreaTime = World.Time - defenseAreaStartTimes[side]
            if inDefenseAreaTime > MAX_DEFENSE_AREA_TIME then
                defenseAreaStartTimes = {}
                KeeperBallHolding.message = side.." keeper kept the ball longer than 10 seconds in its defense area"
                KeeperBallHolding.event = Event.keeperBallHolding(side == "Yellow", World.Ball.pos, inDefenseAreaTime)
                return true
            end
        else
            defenseAreaStartTimes[side] = World.Time
        end
    end
    
    return false
end

function KeeperBallHolding.reset()
    defenseAreaStartTimes = {}
end

return KeeperBallHolding
