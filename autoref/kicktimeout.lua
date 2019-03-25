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

local KickTimeout = {}

local World = require "../base/world"
local Event = require "gameevent2019"

KickTimeout.possibleRefStates = {
    Direct = true,
    Indirect = true,
    Kickoff = true
}

local stateStartTime = World.Time
function KickTimeout.occuring()
    if World.Time - stateStartTime < 1 then
        return false
    end
    if World.ActionTimeRemaining < 0 then
        local isYellow = World.RefereeState == "KickoffYellow" or World.RefereeState == "DirectYellow" or World.RefereeState == "IndirectYellow"
        KickTimeout.event = Event.kickTimeout(isYellow, World.Ball.pos, World.Time - stateStartTime)
        return true
    end
    return false
end

function KickTimeout.reset()
    stateStartTime = World.Time
end

return KickTimeout
