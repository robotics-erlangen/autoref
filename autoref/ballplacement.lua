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

local BallPlacement = {}

local debug = require "../base/debug"
local Field = require "../base/field"
local Ruleset = require "ruleset"
local Refbox = require "../base/refbox"
local vis = require "../base/vis"
local World = require "../base/world"

local BALL_PLACEMENT_RADIUS = 0.1
local TEAM_CAPABLE_OF_PLACEMENT = {}
function BallPlacement.setYellowTeamCapable()
    TEAM_CAPABLE_OF_PLACEMENT[World.YellowColorStr] = true
end
function BallPlacement.setBlueTeamCapable()
    TEAM_CAPABLE_OF_PLACEMENT[World.BlueColorStr] = true
end
local SLOW_BALL = 0.1

-- the 'foul' variable is a rule object,
-- which contains foul-associated information
local foul
local waitingForBallToSlowDown
local placingTeam
local undefinedStateTime
local startTime = 0
local placementTimer = 0
function BallPlacement.start(foul_)
    foul = table.copy(foul_) -- preserve attributes
    foul.freekickPosition = Field.limitToFreekickPosition(foul.freekickPosition, foul.executingTeam)
    waitingForBallToSlowDown = true
    startTime = World.Time
    undefinedStateTime = 0
    Refbox.send("STOP", nil, foul.event)
end
function BallPlacement.active()
    return foul ~= nil
end
local function endBallPlacement()
    foul = nil
    placementTimer = 0
    undefinedStateTime = 0
end
function BallPlacement.run()
    local refState = World.RefereeState

    if placementTimer ~= 0 then
        debug.set("placement time", World.Time - placementTimer)
        vis.addCircle("ball placement", foul.freekickPosition, BALL_PLACEMENT_RADIUS, vis.colors.orangeHalf, true)
    end

    if refState ~= "Stop" and World.Time - startTime < 1 then
        -- wait a second for the initial stop command
        return
    end

    if refState == "Stop" and waitingForBallToSlowDown then
        if World.Ball.speed:length() < SLOW_BALL then
            placementTimer = World.Time
            placingTeam = foul.executingTeam
            if not TEAM_CAPABLE_OF_PLACEMENT[placingTeam] then -- change team
                placingTeam = (placingTeam == World.YellowColorStr) and World.BlueColorStr or World.YellowColorStr
            end
            if not TEAM_CAPABLE_OF_PLACEMENT[placingTeam] then
                log("autonomous ball placement failed: no team is capable")
                Refbox.send("STOP", nil, foul.event)
                endBallPlacement()
            else
                Refbox.send("BALL_PLACEMENT_" .. placingTeam:match(">(%a+)<"):upper(), foul.freekickPosition, foul.event)
                log("ball placement to be conducted by team " .. placingTeam)
                waitingForBallToSlowDown = false
            end
        end
    elseif refState:sub(0,13) == "BallPlacement" then
        local noRobotNearBall = true
        for _, robot in ipairs(World.Robots) do
            if robot.pos:distanceTo(foul.freekickPosition) < 0.5 then
                noRobotNearBall = false
            end
        end
        if World.Ball.pos:distanceTo(foul.freekickPosition) < BALL_PLACEMENT_RADIUS
                and noRobotNearBall and World.Ball.speed:length() < SLOW_BALL then
            log("success placing the ball")
            Refbox.send(foul.consequence, nil, foul.event)
            endBallPlacement()
        elseif World.Time - placementTimer > Ruleset.placementTimeout and
                foul.executingTeam == World.BlueColorStr and placingTeam == World.BlueColorStr
                and TEAM_CAPABLE_OF_PLACEMENT[World.YellowColorStr] then
            -- let the other team try (yellow)
            log(World.BlueColorStr .. " failed placing the ball, " .. World.YellowColorStr .. " now conducting")
            placingTeam = World.YellowColorStr
            placementTimer = World.Time
            Refbox.send("BALL_PLACEMENT_YELLOW", foul.freekickPosition, foul.event)
        elseif World.Time - placementTimer > Ruleset.placementTimeout and
                foul.executingTeam == World.YellowColorStr and placingTeam == World.YellowColorStr
                and TEAM_CAPABLE_OF_PLACEMENT[World.BlueColorStr] then
            -- let the other team try (blue)
            log(World.YellowColorStr .. " failed placing the ball, " .. World.BlueColorStr .. " now conducting")
            placingTeam = World.BlueColorStr
            placementTimer = World.Time
            Refbox.send("BALL_PLACEMENT_BLUE", foul.freekickPosition, foul.event)
        elseif World.Time - placementTimer > Ruleset.placementTimeout then
            log(Ruleset.placementTimeout)
            log("autonomous ball placement failed: timeout")
            Refbox.send("STOP", nil, foul.event)
            endBallPlacement()
        end
    else
        -- due to delay of refbox commands, situations can happen which
        -- do not fall into a case defined above
        -- this is also the case if the human referee decided differently
        if undefinedStateTime == 0 then
            undefinedStateTime = World.Time
        end
        if World.Time-undefinedStateTime > 1 and refState:sub(0,13) ~= "BallPlacement" then
            -- abort autonomous ball placement
            endBallPlacement()
        end
    end
end

return BallPlacement
