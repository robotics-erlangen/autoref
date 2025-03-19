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

require("base/globalschecker").enable()
require "base/base"

local Entrypoints = require "base/entrypoints"
local debug = require "base/debug"
local Referee = require "base/referee"
local vis = require "base/vis"
local BallOwner = require "base/ballowner"
local World = require "base/world"
local plot = require "base/plot"

local BallObserver = require "ballobserver"
local GameController = require "gamecontroller"
local EventValidator = require "eventvalidator"

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

local fouls = nil
local foulTimes = {}
local FOUL_TIMEOUT = 3 -- minimum time between subsequent fouls of the same kind

local ballWasValidBefore = false

local eventsToSend = {}

local function runEvent(foul)
	-- take the referee state until the second upper case letter, thereby
	-- stripping 'Blue', 'Yellow', 'ColorPrepare', 'Force' and 'PlacementColor'
	local simpleRefState = World.RefereeState:match("%u%l+")
	if foul.possibleRefStates[simpleRefState] and
			(foul.shouldAlwaysExecute or not foulTimes[foul] or World.Time - foulTimes[foul] > FOUL_TIMEOUT) then
		local event = foul:occuring()
		if event then
			foulTimes[foul] = World.Time
			-- TODO: sanity checks on occuring events

			if World.RefereeState ~= "Halt" then
				table.insert(eventsToSend, event)
				EventValidator.dispatchEvent(event)
			else
				log("Error: issued event during Halt")
			end
			foul:reset()
		end
	elseif not foul.possibleRefStates[simpleRefState] then
		foul:reset()
	end
end

local function debugEvents(events)
	debug.pushtop()
	-- Do not change this, as it is used for replay tests
	debug.set("GAME_CONTROLLER_EVENTS", events)
	debug.pop()
end

local function main()
	if World.HasTrueState then
		EventValidator.update()
	end

	if World.BallPlacementPos then
		vis.addPath("ball placement", {World.Ball.pos, World.BallPlacementPos}, vis.colors.redHalf, true, nil, 0.5)
		vis.addCircle("ball placement", World.BallPlacementPos, 0.6, vis.colors.green, false)
	end

	if fouls == nil then
		fouls = { }
		for _, filename in pairs(descriptionToFileNames) do
			local foul = require("rules/" .. filename)()
			foul:reset()
			table.insert(fouls, foul)
		end
	end

	for _, foul in ipairs(fouls) do
		if foul.resetOnInvisibleBall and not World.Ball:isPositionValid() then
			foul:reset()
		end
	end

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
		-- Connect to GameController even without vision data to avoid
		-- confusion
		GameController.update()

		if not World.update() then
			return -- skip processing if no vision data is available yet
		end

		BallObserver._update()

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

return {name = "AutoRef", entrypoints = Entrypoints.get(mainLoopWrapper)}
