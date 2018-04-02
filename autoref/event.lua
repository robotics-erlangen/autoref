--[[***********************************************************************
*   Copyright 2018 Alexander Danzer, Lukas Wegmann                        *
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

-- This module creates Event messages according to ssl_autoref.proto
-- which will later be sent as Protobuf messages

local Coordinates = require "../base/coordinates"
local World = require "../base/world"

local function Event(name, teamIsYellow, pos, offendingRobots, reason)
    assert(teamIsYellow ~= nil, "teamIsYellow must be set")
    local stage
    for k, v in pairs(World.gameStageMapping) do
        if v == World.GameStage then
            stage = k
            break
        end
    end
    local event = {
        game_timestamp = { game_stage = stage, stage_time_left = World.StageTimeLeft*1000000 }
    }

    local team = teamIsYellow and "TEAM_YELLOW" or "TEAM_BLUE"
    if name == "Goal" then
        event.goal = { scoring_team = team, position = { x = pos.x, y = pos.y }}
    elseif name == "ChipGoal" then
        event.foul = { gameEventType = "CHIP_ON_GOAL", originator = {team = team, botId = offendingRobots}, message = "ball not in contact with the ground."}
    elseif name == "OutOfField" then --TODO
        assert(pos, "Out of field event needs a position")
        local globalPos = Coordinates.toGlobal(pos)
        event.ball_out_of_field = { last_touch = team,  position = { x = globalPos.x, y = globalPos.y}}
    elseif name == "Carpeting" then
        event.foul = { gameEventType = "ICING", originator = {team = team, botId = offendingRobots } }
    elseif name == "DefenseAreaDist" then
        event.foul = { gameEventType = "ATTACKER_TO_DEFENCE_AREA", originator = {team = team, botId = offendingRobots} }
    elseif name == "AttackerInDefenseArea" then
        event.foul = { gameEventType = "ATTACKER_IN_DEFENSE_AREA", originator = {team = team, botId = offendingRobots}, message = reason }
    elseif name == "Collision" then
        event.foul = { gameEventType = "BOT_COLLISION", originator = {team = team, botId = offendingRobots}, message = reason }
    elseif name == "DoubleTouch" then
        event.foul = { gameEventType = "DOUBLE_TOUCH", originator = {team = team, botId = offendingRobots } }
    elseif name == "Dribbling" then
        event.foul = { gameEventType = "BALL_DRIBBLING", originator = {team = team, botId = offendingRobots } }
    elseif name == "FastShot" then
        event.foul = { gameEventType = "BALL_SPEED", originator = {team = team, botId = offendingRobots}, message = reason }
    elseif name == "FreekickDistance" then
        event.foul = { gameEventType = "DEFENDER_TO_KICK_POINT_DISTANCE", originator = {team = team, botId = offendingRobots } }
    elseif name == "MultipleDefenderPartial" then
        event.foul = { gameEventType = "MULTIPLE_DEFENDER_PARTIALLY", originator = {team = team, botId = offendingRobots } }
    elseif name == "MultipleDefenderFull" then
        event.foul = { gameEventType = "MULTIPLE_DEFENDER", originator = {team = team, botId = offendingRobots } }
    elseif name == "NumberOfPlayers" then
        event.foul = { gameEventType = "NUMBER_OF_PLAYERS", originator = {team = team}, message = reason }
    elseif name == "StopSpeed" then
        event.foul = { gameEventType = "ROBOT_STOP_SPEED", originator = {team = team, botId = offendingRobots } }
    elseif name == "StopBallDistance" then --STOP_BALL_DISTANCE
        event.foul = { gameEventType = "CUSTOM", originator = {team = team, botId = offendingRobots} }
    else
        error("unknown event \"" .. name .. "\"")
    end

    return event
end

return Event
