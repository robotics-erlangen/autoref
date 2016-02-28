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
local Refbox = require "../base/refbox"
local BallOwner = require "../base/ballowner"
World = require "../base/world"
local ballPlacement = require "ballplacement"

local foulnames = {
    "collision",
    "fastshot",
    "outoffield",
    "multipledefender",
    "chooseteamsides",
    "dribbling",
    "attackerindefensearea",
    "stopspeed",
    "numberofplayers",
    "attackerdefareadist",
    "freekickdistance",
    "doubletouch"
}
local fouls = nil
local foulTimes = {}
local FOUL_TIMEOUT = 3 -- minimum time between subsequent fouls of the same kind

local cardToSend
local function sendCardIfPending()
    if World.RefereeState == "Stop" and cardToSend then
        Refbox.send(cardToSend)
        cardToSend = nil
    end
end

local ballWasValidBefore = false
local function main()
    if World.Ball:isPositionValid() then
        ballWasValidBefore = true
    elseif ballWasValidBefore then
        ballWasValidBefore = false
        log("Ball is not visible!")
    else
        return
    end

    if ballPlacement.active() then
        ballPlacement.run()
    end
    sendCardIfPending()
    if fouls == nil then
        fouls = {}
        for _, option in ipairs(World.SelectedOptions) do
            table.insert(fouls, require(option))
            -- log("enabled " .. option)
        end
    end
    for _, foul in ipairs(fouls) do
        -- take the referee state until the second upper case letter
        -- thereby stripping 'Offensive', 'Defensive', 'Prepare' and 'Force'
        local simpleRefState = World.RefereeState:match("%u%l+")
        if foul.possibleRefStates[simpleRefState] and foul.occuring() and
            (not foulTimes[foul] or World.Time - foulTimes[foul] > FOUL_TIMEOUT)
        then
            foulTimes[foul] = World.Time
            assert(foul.consequence, "an occuring foul must define a consequence")
            foul.print()
            log("")
            if foul.freekickPosition and foul.executingTeam then
                ballPlacement.start(foul)
            elseif foul.consequence:match("(%a+)_CARD_(%a+)") or foul.consequence == "STOP" then
                cardToSend = foul.consequence
                if World.RefereeState ~= "Stop" then
                    Refbox.send("STOP") -- Stop is required for sending cards
                end
            else
                error("A foul must either send a card, STOP, or define a freekick position and executing team")
            end
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

return {name = "AutoRef", entrypoints = Entrypoints.get(mainLoopWrapper),
        options = foulnames}
