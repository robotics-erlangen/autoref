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

function FastShot.occuring()
    return World.Ball.speed:length() > 8
end

function FastShot.print()
    local offending = (World.TeamIsBlue and Referee.friendlyTouchedLast()) and
        "<font color=\"blue\">blue</font>" or "<font color=\"#C9C60D\">yellow</font>"
    log("Shot over 8m/s by " .. offending .. " team")
    log("Speed: " .. World.Ball.speed:length() .. "m/s")
end

return FastShot
