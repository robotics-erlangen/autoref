local BallPlacement = {}

local debug = require "../base/debug"
local vis = require "../base/vis"
local Refbox = require "../base/refbox"
local Field = require "../base/field"

local BALL_PLACEMENT_TIMEOUT = 15
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
    Refbox.send("STOP")
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
                Refbox.send("STOP")
                endBallPlacement()
            else
                Refbox.send("BALL_PLACEMENT_" .. placingTeam:match(">(%a+)<"):upper(), foul.freekickPosition)
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
            Refbox.send(foul.consequence)
            endBallPlacement()
        elseif World.Time - placementTimer > BALL_PLACEMENT_TIMEOUT and
                foul.executingTeam == World.BlueColorStr and placingTeam == World.BlueColorStr
                and TEAM_CAPABLE_OF_PLACEMENT[World.YellowColorStr] then
            -- let try other team (yellow)
            placingTeam = World.YellowColorStr
            placementTimer = World.Time
            Refbox.send("BALL_PLACEMENT_YELLOW", foul.freekickPosition)
        elseif World.Time - placementTimer > BALL_PLACEMENT_TIMEOUT and
                foul.executingTeam == World.YellowColorStr and placingTeam == World.YellowColorStr
                and TEAM_CAPABLE_OF_PLACEMENT[World.BlueColorStr] then
            -- let try other team (blue)
            placingTeam = World.BlueColorStr
            placementTimer = World.Time
            Refbox.send("BALL_PLACEMENT_BLUE", foul.freekickPosition)
        elseif World.Time - placementTimer > BALL_PLACEMENT_TIMEOUT then
            log("autonomous ball placement failed: timeout")
            Refbox.send("STOP")
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
