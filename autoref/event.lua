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

    local team = teamIsYellow and "YELLOW" or "BLUE"
    if name == "Goal" then
        event.goal = { scoring_team = team, position = { x = pos.x, y = pos.y }}
    elseif name == "ChipGoal" then
        event.foul = { foul_type = "CHIP_GOAL", offending_team = team, offending_robots = offendingRobots, reason = "ball not in contact with the ground."}
    elseif name == "OutOfField" then
        assert(pos, "Out of field event needs a position")
        local globalPos = Coordinates.toGlobal(pos)
        event.ball_out_of_field = { last_touch = team,  position = { x = globalPos.x, y = globalPos.y}}
    elseif name == "Carpeting" then
        event.foul = { foul_type = "CARPETING", offending_team = team, offending_robots = offendingRobots }
    elseif name == "DefenseAreaDist" then
        event.foul = { foul_type = "DEFENSE_AREA_DISTANCE", offending_team = team, offending_robots = offendingRobots }
    elseif name == "AttackerInDefenseArea" then
        event.foul = { foul_type = "ATTACKER_DEFENSE_AREA", offending_team = team, offending_robots = offendingRobots, reason = reason }
    elseif name == "Collision" then
        event.foul = { foul_type = "COLLISION", offending_team = team, offending_robots = offendingRobots, reason = reason }
    elseif name == "DoubleTouch" then
        event.foul = { foul_type = "DOUBLE_TOUCH", offending_team = team, offending_robots = offendingRobots }
    elseif name == "Dribbling" then
        event.foul = { foul_type = "DRIBBLING", offending_team = team, offending_robots = offendingRobots }
    elseif name == "FastShot" then
        event.foul = { foul_type = "BALL_SPEED", offending_team = team, offending_robots = offendingRobots, reason = reason }
    elseif name == "FreekickDistance" then
        event.foul = { foul_type = "FREEKICK_DISTANCE", offending_team = team, offending_robots = offendingRobots }
    elseif name == "MultipleDefenderPartial" then
        event.foul = { foul_type = "DEFENDER_DEFENSE_AREA_PARTIAL", offending_team = team, offending_robots = offendingRobots }
    elseif name == "MultipleDefenderFull" then
        event.foul = { foul_type = "DEFENDER_DEFENSE_AREA_FULL", offending_team = team, offending_robots = offendingRobots }
    elseif name == "NumberOfPlayers" then
        event.foul = { foul_type = "NUMBER_OF_PLAYERS", offending_team = team, reason = reason }
    elseif name == "StopSpeed" then
        event.foul = { foul_type = "STOP_SPEED", offending_team = team, offending_robots = offendingRobots }
    else
        error("unknown event \"" .. name .. "\"")
    end

    return event
end

return Event
