--[[
--- Provides informations about game state
module "World"
]]--

--[[***********************************************************************
*   Copyright 2015 Alexander Danzer, Michael Eischer, Christian Lobmeier, *
*       Philipp Nordhus                                                   *
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

local amun = amun
local Ball = require "../base/ball"
local Constants = require "../base/constants"
local Robot = require "../base/robot"

--- Ball and team informations.
-- @class table
-- @name World
-- @field Ball Ball - current Ball
-- @field YellowRobots Robot[] - List of own robots in an arbitary order
-- @field YellowInvisibleRobots Robot[] - Own robots which currently aren't tracked
-- @field YellowRobotsById Robot[] - List of own robots with robot id as index
-- @field YellowKeeper Robot - Own keeper if on field or nil
-- @field YellowRobotsNumberAllowed number - number of yellow robots that are allowed on the field
-- @field BlueRobots Robot[] - List of opponent robots in an arbitary order
-- @field BlueRobotsById Robot[] - List of opponent robots with robot id as index
-- @field BlueKeeper Robot - Opponent keeper if on field or nil
-- @field BlueRobotsNumberAllowed number - number of blue robots that are allowed on the field
-- @field Robots Robot[] - Every visible robot in an arbitary order
-- @field TeamIsBlue bool - True if we are the blue team, otherwise we're yellow
-- @field IsSimulated bool - True if the world is simulated
-- @field IsLargeField bool - True if playing on the large field
-- @field Time number - Current unix timestamp in seconds (with nanoseconds precision)
-- @field TimeDiff number - Time since last update
-- @field BallPlacementPos - Position where the ball has to be placed
-- @field RefereeState string - current refereestate, can be one of these:
-- Halt, Stop, Game, GameForce,
-- KickoffYellowPrepare, KickoffBluePrepare, KickoffYellow, KickoffBlue,
-- PenaltyYellowPrepare, PenaltyBluePrepare, PenaltyYellow, PenaltyBlue,
-- DirectYellow, DirectBlue, IndirectYellow, IndirectBlue,
-- TimeoutBlue, TimeoutYellow, BallPlacementBlue, BallPlacementYellow
-- @field GameStage string - current game stage, can be one of these:
-- FirstHalfPre, FirstHalf, HalfTime, SecondHalfPre, SecondHalf,
-- ExtraTimeBreak, ExtraFirstHalfPre, ExtraFirstHalf, ExtraHalfTime, ExtraSecondHalfPre, ExtraSecondHalf,
-- PenaltyShootoutBreak, PenaltyShootout, PostGame

local World = require ((require "../base/basedir").."world")

World.Ball = Ball()
World.YellowRobots = {}
World.YellowInvisibleRobots = {}
World.YellowRobotsById = {}
World.YellowKeeper = nil
World.YellowColorStr = "<font color=\"#C9C60D\">yellow</font>"
World.BlueRobots = {}
World.BlueRobotsById = {}
World.BlueKeeper = nil
World.BlueColorStr = "<font color=\"blue\">blue</font>"
World.Robots = {}
World.TeamIsBlue = false
World.IsSimulated = false
World.IsLargeField = false
World.SelectedOptions = nil

World.RULEVERSION = nil

World.Geometry = {}
--- Field geometry.
-- Lengths in meter
-- @class table
-- @name World.Geometry
-- @field FieldWidth number - Width of the playing field (short side)
-- @field FieldHeight number - Height of the playing field (long side)
-- @field FieldWidthHalf number - Half width of the playing field (short side)
-- @field FieldHeightHalf number - Half height of the playing field (long side)
-- @field FieldWidthQuarter number - Quarter width of the playing field (short side)
-- @field FieldHeightQuarter number - Quarter height of the playing field (long side)
-- @field GoalWidth number - Inner width of the goals
-- @field GoalWallWidth number - Width of the goal walls
-- @field GoalDepth number - Depth of the goal
-- @field GoalHeight number - Height of the goals
-- @field LineWidth number - Width of the game field lines
-- @field CenterCircleRadius number - Radius of the center circle
-- @field FreeKickDefenseDist number - Distance to keep to opponent defense area during a freekick
-- @field DefenseRadius number - Radius of the defense area corners
-- @field DefenseStretch number - Distance between the defense areas quarter circles
-- @field DefenseWidth number - Width of the rectangular defense area (since 2018)
-- @field DefenseHeight number - Height of the rectangular defense area (since 2018)
-- @field YellowPenaltySpot Vector - Position of our own penalty spot
-- @field BluePenaltySpot Vector - Position of the opponent's penalty spot
-- @field BluePenaltyLine number - Maximal distance from centerline during an offensive penalty
-- @field YellowPenaltyLine number - Maximal distance from centerline during an defensive penalty
-- @field YellowGoal Vector - Center point of the goal on the line
-- @field YellowGoalLeft Vector
-- @field YellowGoalRight Vector
-- @field BlueGoal Vector - Center point of the goal on the line
-- @field BlueGoalLeft Vector
-- @field BlueGoalRight Vector
-- @field BoundaryWidth number - Free distance around the playing field
-- @field RefereeWidth number - Width of area reserved for referee

-- initializes Team and Geometry data
function World._init()
	assert(not amun.isBlue(), "Must be run as yellow strategy or autoref!")
	World.TeamIsBlue = false
	local geom = amun.getGeometry()
	World._updateGeometry(geom)
	World._updateRuleVersion(geom)
	World._updateTeam()
end

-- Creates generation specific robot object for own team
function World._updateTeam()
	local friendlyRobotsById = {}
	for id = 0, 15 do
		friendlyRobotsById[id] = Robot(id, true, World.Geometry)
	end
	World.YellowRobotsById = friendlyRobotsById
end

-- Setup field geometry
local updateBefore = World._updateGeometry
function World._updateGeometry(geom)
	updateBefore(geom)
	local wgeom = World.Geometry
	wgeom.FieldWidth = geom.field_width
	wgeom.FieldWidthHalf = geom.field_width / 2
	wgeom.FieldWidthQuarter = geom.field_width / 4
	wgeom.FieldHeight = geom.field_height
	wgeom.FieldHeightHalf = geom.field_height / 2
	wgeom.FieldHeightQuarter = geom.field_height / 4

	wgeom.GoalWidth = geom.goal_width
	wgeom.GoalWallWidth = geom.goal_wall_width
	wgeom.GoalDepth = geom.goal_depth
	wgeom.GoalHeight = geom.goal_height

	wgeom.LineWidth = geom.line_width
	wgeom.CenterCircleRadius = geom.center_circle_radius
	wgeom.FreeKickDefenseDist = geom.free_kick_from_defense_dist

	wgeom.DefenseRadius = geom.defense_radius
	wgeom.DefenseStretch = geom.defense_stretch
	wgeom.DefenseStretchHalf = geom.defense_stretch / 2
	wgeom.DefenseWidth = geom.defense_width or geom.defense_stretch
	wgeom.DefenseHeight = geom.defense_height or geom.defense_radius
	wgeom.DefenseWidthHalf = (geom.defense_width or geom.defense_stretch) / 2

	wgeom.YellowPenaltySpot = Vector(0, - wgeom.FieldHeightHalf + geom.penalty_spot_from_field_line_dist)
	wgeom.BluePenaltySpot = Vector(0, wgeom.FieldHeightHalf - geom.penalty_spot_from_field_line_dist)
	wgeom.BluePenaltyLine = wgeom.BluePenaltySpot.y - geom.penalty_line_from_spot_dist
	wgeom.YellowPenaltyLine = wgeom.YellowPenaltySpot.y + geom.penalty_line_from_spot_dist

	-- The goal posts are on the field lines
	wgeom.YellowGoal = Vector(0, - wgeom.FieldHeightHalf + wgeom.LineWidth)
	wgeom.YellowGoalLeft = Vector(- wgeom.GoalWidth / 2, wgeom.YellowGoal.y)
	wgeom.YellowGoalRight = Vector(wgeom.GoalWidth / 2, wgeom.YellowGoal.y)

	wgeom.BlueGoal = Vector(0, wgeom.FieldHeightHalf - wgeom.LineWidth)
	wgeom.BlueGoalLeft = Vector(- wgeom.GoalWidth / 2, wgeom.BlueGoal.y)
	wgeom.BlueGoalRight = Vector(wgeom.GoalWidth / 2, wgeom.BlueGoal.y)

	wgeom.BoundaryWidth = geom.boundary_width
	wgeom.RefereeWidth = geom.referee_width

	World.IsLargeField = wgeom.FieldWidth > 5 and wgeom.FieldHeight > 7
end

local oldUpdate = World._updateWorld
function World._updateWorld(state)
	oldUpdate(state)
	-- Get time
	if World.Time then
		World.TimeDiff = state.time * 1E-9 - World.Time
	else
		World.TimeDiff = 0
	end
	World.Time = state.time * 1E-9
	assert(World.Time > 0, "Invalid World.Time. Outdated ra version!")
	if World.IsSimulated ~= state.is_simulated then
		World.IsSimulated = state.is_simulated
		Constants.switchSimulatorConstants(World.IsSimulated)
	end

	local radioResponses = state.radio_response

	-- update ball if available
	if state.ball then
		World.Ball:_update(state.ball, World.Time)
	end

	local dataFriendly = World.TeamIsBlue and state.blue or state.yellow
	if dataFriendly then
		-- sort data by robot id
		local dataById = {}
		for _,rdata in ipairs(dataFriendly) do
			dataById[rdata.id] = rdata
		end

		-- Update data of every own robot
		World.YellowRobots = {}
		World.YellowInvisibleRobots = {}
		for _, robot in pairs(World.YellowRobotsById) do
			-- get responses for the current robot
			-- these are identified by the robot generation and id
			local robotResponses = {}
			for _, response in ipairs(radioResponses) do
				if response.generation == robot.generation
						and response.id == robot.id then
					table.insert(robotResponses, response)
				end
			end

			robot:_update(dataById[robot.id], World.Time, robotResponses)
			-- sort robot into visible / not visible
			if robot.isVisible then
				table.insert(World.YellowRobots, robot)
			else
				table.insert(World.YellowInvisibleRobots, robot)
			end
		end
	end

	local dataOpponent = World.TeamIsBlue and state.yellow or state.blue
	if dataOpponent then
		-- only keep robots that are still existent
		local opponentRobotsById = World.BlueRobotsById
		World.BlueRobots = {}
		World.BlueRobotsById = {}
		-- just update every opponent robot
		-- robots that are invisible for more than one second are dropped by amun
		for _,rdata in ipairs(dataOpponent) do
			local robot = opponentRobotsById[rdata.id]
			opponentRobotsById[rdata.id] = nil
			if not robot then
				robot = Robot(rdata.id, false)
			end
			robot:_update(rdata, World.Time)
			table.insert(World.BlueRobots, robot)
			World.BlueRobotsById[rdata.id] = robot
		end
		-- mark dropped robots as invisible
		for _,robot in pairs(opponentRobotsById) do
			robot:_update(nil, World.Time)
		end
	end

	World.Robots = table.copy(World.YellowRobots)
	table.append(World.Robots, World.BlueRobots)

	-- no vision data only if the parameter is false
	return state.has_vision_data ~= false
end

-- updates referee command and keeper information
function World._updateGameState(state)
	World.RefereeState = state.state

	if World.RefereeState == "TimeoutOffensive" or World.RefereeState == "TimeoutDefensive" then
		World.RefereeState = "Halt"
	end

	if state.designated_position and state.designated_position.x and
			(not World.BallPlacementPos or World.BallPlacementPos.y ~= state.designated_position.y
			or World.BallPlacementPos.x ~= state.designated_position.x) then
		World.BallPlacementPos = Vector.createReadOnly(state.designated_position.x, state.designated_position.y)
	end

	World.GameStage = World.gameStageMapping[state.stage]

	local friendlyTeamInfo = World.TeamIsBlue and state.blue or state.yellow
	local opponentTeamInfo = World.TeamIsBlue and state.yellow or state.blue

	local friendlyKeeperId = friendlyTeamInfo.goalie
	local opponentKeeperId = opponentTeamInfo.goalie

	local friendlyKeeper = World.YellowRobotsById[friendlyKeeperId]
	if friendlyKeeper and not friendlyKeeper.isVisible then
		friendlyKeeper = nil
	end

	local opponentKeeper = World.BlueRobotsById[opponentKeeperId]
	if opponentKeeper and not opponentKeeper.isVisible then
		opponentKeeper = nil
	end

	World.YellowKeeper = friendlyKeeper
	World.BlueKeeper = opponentKeeper

	World.YellowRobotsNumberAllowed = friendlyTeamInfo.max_allowed_bots or 8
	World.BlueRobotsNumberAllowed = opponentTeamInfo.max_allowed_bots or 8

	World.StageTimeLeft = state.stage_time_left/1000000 -- in seconds

	--[[
    optional sint32 stage_time_left = 2;
	message TeamInfo {
		// The team's name (empty string if operator has not typed anything).
		required string name = 1;
		// The number of goals scored by the team during normal play and overtime.
		required uint32 score = 2;
		// The number of red cards issued to the team since the beginning of the game.
		required uint32 red_cards = 3;
		// The amount of time (in microseconds) left on each yellow card issued to the team.
		// If no yellow cards are issued, this array has no elements.
		// Otherwise, times are ordered from smallest to largest.
		repeated uint32 yellow_card_times = 4 [packed=true];
		// The total number of yellow cards ever issued to the team.
		required uint32 yellow_cards = 5;
		// The number of timeouts this team can still call.
		// If in a timeout right now, that timeout is excluded.
		required uint32 timeouts = 6;
		// The number of microseconds of timeout this team can use.
		required uint32 timeout_time = 7;
	}]]
end

-- update and handle user inputs set for own robots
function World._updateUserInput(input)
	if input.radio_command then
		for _, robot in pairs(World.YellowRobotsById) do
			robot:_updateUserControl(nil) -- clear
		end
		for _, cmd in ipairs(input.radio_command) do
			local robot = World.YellowRobotsById[cmd.id]
			if robot then
				robot:_updateUserControl(cmd.command)
			end
		end
	end
end

World._init()

return World
