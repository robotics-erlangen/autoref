local debug = require "../base/debug"
local vis = require "../base/vis"

local BallPlacement = {}

local BALL_PLACEMENT_TIMEOUT = 30
local BALL_PLACEMENT_PRECISION = 0.05
local TEAM_CAPABLE_OF_PLACEMENT = {
    [World.YellowColorStr] = true,
    [World.BlueColorStr] = true
}
local SLOW_BALL = 0.1

local VALID_REF_COMMANDS = {
    HALT = true,
    STOP = true,
    NORMAL_START = true,
    FORCE_START = true,
    PREPARE_KICKOFF_YELLOW = true,
    PREPARE_KICKOFF_BLUE = true,
    PREPARE_PENALTY_YELLOW = true,
    PREPARE_PENALTY_BLUE = true,
    DIRECT_FREE_YELLOW = true,
    DIRECT_FREE_BLUE = true,
    INDIRECT_FREE_YELLOW = true,
    INDIRECT_FREE_BLUE = true,
    TIMEOUT_YELLOW = true,
    TIMEOUT_BLUE = true,
    GOAL_YELLOW = true,
    GOAL_BLUE = true,
    BALL_PLACEMENT_BLUE = true,
    BALL_PLACEMENT_YELLOW = true
}
local function sendToRefbox(command, placementPos)
    if not VALID_REF_COMMANDS[command] then
        error("invalid refbox command " .. command)
    end
    local cmd = {
        message_id = 1,
        command = command,
    }
    if command:sub(0,14) == "BALL_PLACEMENT" then
        cmd.designated_position = {
            x = placementPos.x,
            y = placementPos.y
        }
    end
    if not amun.sendNetworkRefereeCommand then
        error("you must enable debug mode in order to send referee commands")
    end
    log("send refbox command: " .. command)
    amun.sendNetworkRefereeCommand(cmd)
end

-- the 'foul' variable is a rule object,
-- which contains foul-associated information
local foul
local waitingForBallToSlowDown
local placingTeam
local undefinedStateTime
local startTime = 0
local placementTimer = 0
function BallPlacement.start(foul_)
    foul = foul_
    waitingForBallToSlowDown = true
    startTime = World.Time
    undefinedStateTime = 0
    sendToRefbox("STOP")
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
        vis.addCircle("ball placement", foul.freekickPosition, 0.05, vis.colors.orangeHalf, true)
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
                sendToRefbox("STOP")
                endBallPlacement()
            else
                sendToRefbox("BALL_PLACEMENT_" .. placingTeam:match(">(%a+)<"):upper(), foul.freekickPosition)
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
        if World.Ball.pos:distanceTo(foul.freekickPosition) < BALL_PLACEMENT_PRECISION
                and noRobotNearBall and World.Ball.speed:length() < SLOW_BALL then
            log("success placing the ball")
            sendToRefbox(foul.consequence)
            endBallPlacement()
        elseif World.Time - placementTimer > BALL_PLACEMENT_TIMEOUT and
                foul.executingTeam == World.BlueColorStr and placingTeam == World.BlueColorStr
                and TEAM_CAPABLE_OF_PLACEMENT[World.YellowColorStr] then
            -- let try other team (yellow)
            placingTeam = World.YellowColorStr
            placementTimer = World.Time
            sendToRefbox("BALL_PLACEMENT_YELLOW", foul.freekickPosition)
        elseif World.Time - placementTimer > BALL_PLACEMENT_TIMEOUT and
                foul.executingTeam == World.YellowColorStr and placingTeam == World.YellowColorStr
                and TEAM_CAPABLE_OF_PLACEMENT[World.BlueColorStr] then
            -- let try other team (blue)
            placingTeam = World.BlueColorStr
            placementTimer = World.Time
            sendToRefbox("BALL_PLACEMENT_BLUE", foul.freekickPosition)
        elseif World.Time - placementTimer > BALL_PLACEMENT_TIMEOUT then
            log("autonomous ball placement failed: timeout")
            sendToRefbox("STOP")
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
