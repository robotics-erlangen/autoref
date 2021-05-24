--[[***********************************************************************
*   Copyright 2019 Alexander Danzer, Michael Eischer, Lukas Wegmann       *
*       Andreas Wendler                                                   *
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
local vis = require "../base/vis"
local BallOwner = require "../base/ballowner"
local World = require "../base/world"
local plot = require "../base/plot"
local Parameters = require "../base/parameters"

local GameController = require "gamecontroller"

local descriptionToFileNames = {
    ["Robot collisions"] = "collision",
    ["Shooting speed"] = "fastshot",
    ["Ball out of field"] = "outoffield",
    ["Multiple Defender"] = "multipledefender",
    ["Dribbling over 1m"] = "dribbling",
    ["Attacker in defense area"] = "attackerindefensearea",
    ["Robot speed during Stop"] = "stopspeed",
    ["Attacker distance to defense area"] = "attackerdefareadist",
    ["Distance during free kicks"] = "freekickdistance",
    ["Double touch after free kick"] = "doubletouch",
    ["Ball placement"] = "ballplacement",
    ["Ball placement interference"] = "placementinterference",
}

local optionnames = { }
for description, _ in pairs(descriptionToFileNames) do
    table.insert(optionnames, description)
end

local fouls = nil
local foulTimes = {}
local FOUL_TIMEOUT = Parameters.add("main", "FOUL_TIMEOUT", 3) -- minimum time between subsequent fouls of the same kind

local ballWasValidBefore = false
local debugMessage = ""

local eventsToSend = {}

local function runEvent(foul)
	-- take the referee state until the second upper case letter, thereby
	-- stripping 'Blue', 'Yellow', 'ColorPrepare', 'Force' and 'PlacementColor'
	local simpleRefState = World.RefereeState:match("%u%l+")
	if foul.possibleRefStates[simpleRefState] and
			(foul.shouldAlwaysExecute or not foulTimes[foul] or World.Time - foulTimes[foul] > FOUL_TIMEOUT()) and
			foul.occuring() then
		foulTimes[foul] = World.Time
		-- TODO: sanity checks on occuring events
		if foul.message then
			log(foul.message)
		end
		debugMessage = foul.message

		if foul.ignore then
			debug.set("ignore") -- just for the empty if branche
		else
			table.insert(eventsToSend, foul.event)
			GameController.sendEvent(foul.event)
		end
		if foul.reset then
			foul.reset()
		end
	elseif not foul.possibleRefStates[simpleRefState] then
		if foul.reset then
			foul.reset()
		end
	end

	if foulTimes[foul] and foul.freekickPosition and foulTimes[foul] > World.Time - 1 then
		vis.addCircle("event position", foul.freekickPosition, 0.1, vis.colors.blue, true)
	end
end

local function debugEvents(events)
    debug.pushtop()
    -- Do not change this, as it is used for replay tests
    debug.set("GAME_CONTROLLER_EVENTS", events)
    debug.pop()
    
    debug.pushtop()
    debug.set("AUTOREF_EVENT", debugMessage)
    debug.pop()
end

local function main()
    GameController.update()

    if World.BallPlacementPos then
        vis.addPath("ball placement", {World.Ball.pos, World.BallPlacementPos}, vis.colors.redHalf, true, nil, 0.5)
        vis.addCircle("ball placement", World.BallPlacementPos, 0.6, vis.colors.green, false)
    end

    if fouls == nil then
        fouls = { }
        for _, filename in pairs(descriptionToFileNames) do
            local foul = require(filename)
            if foul.reset then
                foul.reset()
            end
            table.insert(fouls, foul)
        end
    end

    for _, foul in ipairs(fouls) do
        if foul.resetOnInvisibleBall and not World.Ball:isPositionValid() then
            foul.reset()
        end
	end

	Parameters.update()
    eventsToSend = {}

	-- check events that should always be executed first
	for _, foul in ipairs(fouls) do
		if foul.runOnInvisibleBall then
			runEvent(foul)
		end
	end

	-- stop when the ball is not visible
    if World.Ball:isPositionValid() then
        ballWasValidBefore = true
    elseif ballWasValidBefore then
        ballWasValidBefore = false
        -- log("Ball is not visible!")
    else
        debugEvents(eventsToSend)
        return
    end

	-- check events that should only be executed when the ball is visible
	for _, foul in ipairs(fouls) do
		if not foul.runOnInvisibleBall then
			runEvent(foul)
		end
    end
    
    debugEvents(eventsToSend)

    Referee.illustrateRefereeStates()
end

local function mainLoopWrapper(func)
    return function()
        if not World.update() then
            return -- skip processing if no vision data is available yet
        end
        func()
        plot._plotAggregated()
    end
end

Entrypoints.add("2021", function()
    main()
    debug.resetStack()
    Referee.update()
    BallOwner.lastRobot()
end)

return {name = "AutoRef", entrypoints = Entrypoints.get(mainLoopWrapper),
        options = optionnames}
