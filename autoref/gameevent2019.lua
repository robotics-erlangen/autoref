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
	return {x = location.x, y = location.y }
end

local function createFromStandardInfo(teamIsYellow, botId, location)
	local event = { by_team = toTeam(teamIsYellow) }
	if botId then
		event.by_bot = botId
	end
	if location then
		event.location = location
	end
	return event
end

-- goal line or touch line
function Events.ballLeftField(teamIsYellow, botId, location, goalLine)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if goalLine then
		return { ball_left_field_goal_line = event }
	else
		return { ball_left_field_touch_line = event }
	end
end

function Events.aimlessKick(teamIsYellow, botId, location, kickLocation)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if kickLocation then
		event.kick_location = toLocation(kickLocation)
	end
	return { aimless_kick = event }
end

function Events.goal(teamIsYellow, botId, location, kickLocation, unsureGoal)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if kickLocation then
		event.kick_location = toLocation(kickLocation)
	end
	if unsureGoal then
		return { possible_goal = event }
	else
		return { goal = event }
	end
end

function Events.indirectGoal(teamIsYellow, botId, location, kickLocation)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if kickLocation then
		event.kick_location = toLocation(kickLocation)
	end
	return { indirect_goal = event }
end

function Events.chippedGoal(teamIsYellow, botId, location, kick_location, maxBallHeight)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if kickLocation then
		event.kick_location = toLocation(kickLocation)
	end
	if maxBallHeight then
		event.max_ball_height = maxBallHeight
	end
	return { chipped_goal = event }
end

function Events.stopSpeed(teamIsYellow, botId, location, speed)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if speed then
		event.speed = speed
	end
	return { bot_too_fast_in_stop = event }
end

function Events.freeKickDistance(teamIsYellow, botId, location, distance)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if speed then
		event.distance = distance
	end
	return { defender_too_close_to_kick_point = event }
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
	return { bot_crash_drawn = event }
end

function Events.botCrash(teamIsYellow, botIdViolator, botIdVictim, location, speed, speedDiff, angle, skipped)
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
	if skipped then
		return { bot_crash_unique_skipped = event }
	else
		return { bot_crash_unique = event }
	end
end

function Events.pushing(teamIsYellow, botIdViolator, botIdVictim, location, distance, skipped)
	local event = { by_team = toTeam(teamIsYellow), violator = botIdViolator, victim = botIdVictim }
	event.location = toLocation(location)
	if distance then
		event.pushed_distance = distance
	end
	if skipped then
		return { bot_pushed_bot_skipped = event }
	else
		return { bot_pushed_bot = event }
	end
end

-- TODO: bot tipped over?

function Events.multipleDefender(teamIsYellow, botId, location, distance, partial)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if distance then
		event.distance = distance
	end
	if partial then
		return { defender_in_defense_area_partially = event }
	else
		return { defender_in_defense_area = event }
	end
end

function Events.attackerInDefenseArea(teamIsYellow, botId, location, distance)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if distance then
		event.distance = distance
	end
	return { attacker_in_defense_area = event }
end

function Events.fastShot(teamIsYellow, botId, location, kickSpeed, maxBallHeight)
	local event = createFromStandardInfo(teamIsYellow, botId, location)
	if kickSpeed then
		event.initial_ball_speed = kickSpeed
	end
	if maxBallHeight then
		event.max_ball_height = maxBallHeight
	end
	return { bot_kicked_ball_too_fast = event }
end

function Events.dribbling(teamIsYellow, botId, startLocation, endLocation)
	local event = createFromStandardInfo(teamIsYellow, botId)
	if startLocation then
		event.start = toLocation(startLocation)
	end
	if endLocation then
		event["end"] = toLocation(endLocation)
	end
	return { bot_dribbled_ball_too_far = event }
end

function Events.attackerTouchKeeper(teamIsYellow, botId, location)
	return { attacker_touched_keeper = createFromStandardInfo(teamIsYellow, botId, location) }
end

function Events.doubleTouch(teamIsYellow, botId, location)
	return { attacker_double_touched_ball = createFromStandardInfo(teamIsYellow, botId, location) }
end

function Events.attackerDefAreaDist(teamIsYellow, botId, location, distance)
	local event = createFromStandardInfo(teamIsYellow, botId)
	if distance then
		event.distance = distance
	end
	return { attacker_too_close_to_defense_area = event }
end

function Events.ballHolding(teamIsYellow, botId, location, duration)
	local event = createFromStandardInfo(teamIsYellow, botId)
	if duration then
		event.duration = duration
	end
	return { bot_held_ball_deliberately = event }
end

function Events.ballPlacementInterference(teamIsYellow, botId, location)
	return { bot_interfered_placement = createFromStandardInfo(teamIsYellow, botId, location) }
end

function Events.penaltyFromYellowCards(teamIsYellow)
	return { multiple_cards = { by_team = toTeam(teamIsYellow) } }
end

function Events.yellowCardFromMultipleFouls(teamIsYellow)
	return { multiple_fouls = { by_team = toTeam(teamIsYellow) } }
end

function Events.multiplePlacementFailure(teamIsYellow)
	return { multiple_placement_failures = { by_team = toTeam(teamIsYellow) } }
end

function Events.kickTimeout(teamIsYellow, location, time)
	local event = createFromStandardInfo(teamIsYellow)
	if location then
		event.location = toLocation(location)
	end
	if time then
		event.time = time
	end
	return { kick_timeout = event }
end

function Events.noProgress(location, time)
	local event = {}
	if location then
		event.location = toLocation(location)
	end
	if time then
		event.time = time
	end
	return { no_progress_in_game = event }
end

function Events.placementFailedTeamInFavor(teamIsYellow, remainingDistance)
	local event = createFromStandardInfo(teamIsYellow)
	if remainingDistance then
		event.remaining_distance = remainingDistance
	end
	return { placement_failed_by_team_in_favor = event }
end

function Events.placementFailedOpponent(teamIsYellow, remainingDistance)
	local event = createFromStandardInfo(teamIsYellow)
	if remainingDistance then
		event.remaining_distance = remainingDistance
	end
	return { placement_failed_by_opponent = event }
end

function Events.keeperBallHolding(teamIsYellow, location, duration)
	local event = createFromStandardInfo(teamIsYellow, location)
	if duration then
		event.duration = duration
	end
	return { keeper_held_ball = event }
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
	return { placement_succeeded = event }
end

function Events.prepared(timeTaken)
	return { prepared = { time_taken = timeTaken } }
end

function Events.numberOfRobots(teamIsYellow)
	return { too_many_robots = { by_team = toTeam(teamIsYellow) } }
end

return Events