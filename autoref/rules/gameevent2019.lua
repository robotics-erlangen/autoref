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

local World = require "base/world";
local Coordinates = require "base/coordinates"
local Vector = require "base/vector"

local Events = {}

local function toTeam(teamIsYellow)
	if teamIsYellow then
		return "YELLOW"
	elseif teamIsYellow == false then
		return "BLUE"
	else
		return "UNKNOWN"
	end
end

local function toLocation(location)
	location = Coordinates.toGlobal(location)
	if amun.isFlipped() then
		location = Vector(-location.x , -location.y)
	end
	return {x = location.y, y = -location.x }
end

local function createFromStandardInfo(teamIsYellow, botId, location)
	local event = { by_team = toTeam(teamIsYellow) }
	if botId then
		event.by_bot = botId
	end
	if location then
		event.location = toLocation(location)
	end
	return event
end

-- goal line or touch line
function Events.ballLeftField(teamIsYellow, botId, location, goalLine)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if goalLine then
		return { ball_left_field_goal_line = event, type = "BALL_LEFT_FIELD_GOAL_LINE" }
	else
		return { ball_left_field_touch_line = event, type = "BALL_LEFT_FIELD_TOUCH_LINE" }
	end
end

function Events.aimlessKick(teamIsYellow, botId, location, kickLocation)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if kickLocation then
		event.kick_location = toLocation(kickLocation)
	end
	return { aimless_kick = event, type = "AIMLESS_KICK" }
end

function Events.goal(scoringTeamIsYellow, shootingTeamIsYellow, shootingBotId, location,
		kickLocation, maxBallHeight)
	local event = {}
	event.by_team = toTeam(scoringTeamIsYellow)
	event.kicking_team = toTeam(shootingTeamIsYellow)
	event.kicking_bot = shootingBotId
	if location then
		event.location = toLocation(location)
	end
	if kickLocation then
		event.kick_location = toLocation(kickLocation)
	end
	if maxBallHeight then
		event.max_ball_height = maxBallHeight
	end
    if scoringTeamIsYellow then
        event.num_robots_by_team = #World.YellowRobots
    else
        event.num_robots_by_team = #World.BlueRobots
    end
	return { possible_goal = event, type = "POSSIBLE_GOAL" }
end

function Events.stopSpeed(teamIsYellow, botId, location, speed)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if speed then
		event.speed = speed
	end
	return { bot_too_fast_in_stop = event, type = "BOT_TOO_FAST_IN_STOP" }
end

function Events.freeKickDistance(teamIsYellow, botId, location, distance)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if distance then
		event.distance = distance
	end
	return { defender_too_close_to_kick_point = event, type = "DEFENDER_TOO_CLOSE_TO_KICK_POINT" }
end

-- speed: the calculated crash speed [m/s] of the two bots
-- speed diff: the difference [m/s] of the velocity of the two bots
-- angle: the angle [rad] in the range [0, pi/2] of the bot velocity vectors
-- an angle of 0rad means, the bots mearly touched each other
-- an angle of pi/2rad means, the bots crashed into each other frontal
function Events.botCrashBoth(botIdYellow, botIdBlue, location, speed, speedDiff, angle)
	local event = {}
	event.bot_yellow = botIdYellow
	event.bot_blue = botIdBlue
	event.location = toLocation(location)
	if speed then
		event.crash_speed = speed
	end
	if speedDiff then
		event.speed_diff = speedDiff
	end
	if angle then
		event.crash_angle = angle
	end
	return { bot_crash_drawn = event, type = "BOT_CRASH_DRAWN" }
end

function Events.botCrash(teamIsYellow, botIdViolator, botIdVictim, location, speed, speedDiff, angle)
	local event = { by_team = toTeam(teamIsYellow), violator = botIdViolator, victim = botIdVictim }
	event.location = toLocation(location)
	if speed then
		event.crash_speed = speed
	end
	if speedDiff then
		event.speed_diff = speedDiff
	end
	if angle then
		event.crash_angle = angle
	end
	return { bot_crash_unique = event, type = "BOT_CRASH_UNIQUE" }
end

function Events.multipleDefender(teamIsYellow, botId, location, distance)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if distance then
		event.distance = distance
	end
	return { defender_in_defense_area = event, type = "DEFENDER_IN_DEFENSE_AREA" }
end

function Events.attackerInDefenseArea(teamIsYellow, botId, location, distance)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if distance then
		event.distance = distance
	end
	event.ball_location = toLocation(World.Ball.pos)
	return { attacker_touched_ball_in_defense_area = event, type = "ATTACKER_TOUCHED_BALL_IN_DEFENSE_AREA" }
end

function Events.fastShot(teamIsYellow, botId, location, kickSpeed, maxBallHeight)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if kickSpeed then
		event.initial_ball_speed = kickSpeed
	end
	if maxBallHeight then
		event.chipped = maxBallHeight > 0
	end
	return { bot_kicked_ball_too_fast = event, type = "BOT_KICKED_BALL_TOO_FAST" }
end

function Events.dribbling(teamIsYellow, botId, startLocation, endLocation)
	local event = createFromStandardInfo(teamIsYellow, botId)
	if startLocation then
		event.start = toLocation(startLocation)
	end
	if endLocation then
		event["end"] = toLocation(endLocation)
	end
	return { bot_dribbled_ball_too_far = event, type = "BOT_DRIBBLED_BALL_TOO_FAR" }
end

function Events.doubleTouch(teamIsYellow, botId, location)
	return { attacker_double_touched_ball = createFromStandardInfo(teamIsYellow, botId, location), type = "ATTACKER_DOUBLE_TOUCHED_BALL" }
end

function Events.attackerDefAreaDist(teamIsYellow, botId, location, distance)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if distance then
		event.distance = distance
	end
	return { attacker_too_close_to_defense_area = event, type = "ATTACKER_TOO_CLOSE_TO_DEFENSE_AREA" }
end

function Events.ballPlacementInterference(teamIsYellow, botId, location)
	return { bot_interfered_placement = createFromStandardInfo(teamIsYellow, botId, location), type = "BOT_INTERFERED_PLACEMENT" }
end

function Events.placementSuccess(teamIsYellow, timeTaken, precision, distance)
	local event = createFromStandardInfo(teamIsYellow)
	if timeTaken then
		event.time_taken = timeTaken
	end
	if precision then
		event.precision = precision
	end
	if distance then
		event.distance = distance
	end
	return { placement_succeeded = event, type = "PLACEMENT_SUCCEEDED" }
end

-- the following events normally covered by the game controller, use only them for the internal autoref
function Events.keeperBallHolding(teamIsYellow, location, duration)
	local event = createFromStandardInfo(teamIsYellow, nil, location)
	if duration then
		event.duration = duration
	end
	return { keeper_held_ball = event, type = "KEEPER_HELD_BALL" }
end

function Events.noProgress(location, time)
	local event = {}
	if location then
		event.location = toLocation(location)
	end
	if time then
		event.time = time
	end
	return { no_progress_in_game = event, type = "NO_PROGRESS_IN_GAME" }
end

function Events.prepared(timeTaken)
	return { prepared = { time_taken = timeTaken }, type = "PREPARED" }
end

function Events.numberOfRobots(teamIsYellow)
	return { too_many_robots = { by_team = toTeam(teamIsYellow) }, type = "TOO_MANY_ROBOTS" }
end

function Events.placementFailed(teamIsYellow, remainingDistance)
	local event = createFromStandardInfo(teamIsYellow)
	if remainingDistance then
		event.remaining_distance = remainingDistance
	end
	return { placement_failed = event, type = "PLACEMENT_FAILED" }
end

return Events
