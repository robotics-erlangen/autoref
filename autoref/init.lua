--[[***********************************************************************
*   Copyright 2015 Alexander Danzer, Michael Eischer                      *
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

require("../base/globalschecker").enable()
require "../base/base"

local Entrypoints = require "../base/entrypoints"
local debug = require "../base/debug"
local Referee = require "../base/referee"
local BallOwner = require "../base/ballowner"
World = require "../base/world"
local ballPlacement = require "ballplacement"

local fouls = {
    -- require "collision",
    require "fastshot",
    require "outoffield",
    -- require "multipledefender",
    require "chooseteamsides",
    require "dribbling",
}
local foulTimes = {}
local FOUL_TIMEOUT = 3 -- minimum time between subsequent fouls of the same kind

local function main()
    if ballPlacement.active() then
        ballPlacement.run()
    end
    for _, foul in ipairs(fouls) do
        -- take the referee state until the second upper case letter
        -- thereby stripping 'Offensive', 'Defensive', 'Prepare' and 'Force'
        local simpleRefState = World.RefereeState:match("%u%l+")
        if foul.possibleRefStates[simpleRefState] and foul.occuring() and
            (not foulTimes[foul] or World.Time - foulTimes[foul] > FOUL_TIMEOUT)
        then
            foulTimes[foul] = World.Time
            assert(foul.executingTeam, "an occuring foul must define an executing team")
            assert(foul.freekickPosition, "an occuring foul must define a freekick position")
            assert(foul.consequence, "an occuring foul must define a consequence")
            foul.print()
            log("")
            ballPlacement.start(foul)
        end
    end
    Referee.illustrateRefereeStates()
end

local function mainLoopWrapper(func)
    return function()
        if not World.update() then
            return -- skip processing if no vision data is available yet
        end
        func()
    end
end
Entrypoints.add("main", function()
    main()
    debug.resetStack()
    Referee.checkTouching()
    BallOwner.lastRobot()
end)

return {name = "AutoRef", entrypoints = Entrypoints.get(mainLoopWrapper)}
