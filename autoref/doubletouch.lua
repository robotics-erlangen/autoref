local DoubleTouch = {}

local Referee = require "../base/referee"
local CONSIDER_FREE_KICK_EXECUTED_THRESHOLD = 0.03

-- define all refstates to be able to reset variables
-- foul occurs actually only in Game
DoubleTouch.possibleRefStates = {
    Halt = true,
    Stop = true,
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
    Ball = true
}

local lastTouchingRobotInFreekick
local lastBallPosInStop
function DoubleTouch.occuring()
    local simpleRefState = World.RefereeState:match("%u%l+")
    if simpleRefState == "Stop" or not lastBallPosInStop then
        lastBallPosInStop = World.Ball.pos:copy()
    end
    if simpleRefState == "Indirect" or simpleRefState == "Direct" then
        lastTouchingRobotInFreekick = Referee.robotAndPosOfLastBallTouch()
    elseif World.RefereeState == "Game" and lastTouchingRobotInFreekick then
        local touchingRobot
        for _, robot in ipairs(World.Robots) do
            if robot.pos:distanceTo(World.Ball.pos) < Referee.touchDist then
                touchingRobot = robot
            end
        end

        local distToFreekickPos = World.Ball.pos:distanceTo(lastBallPosInStop)
        if touchingRobot and distToFreekickPos > CONSIDER_FREE_KICK_EXECUTED_THRESHOLD then
            if touchingRobot == lastTouchingRobotInFreekick then
                local defenseTeam = touchingRobot.isYellow and "Blue" or "Yellow"
                DoubleTouch.consequence = "INDIRECT_FREE_" .. defenseTeam:upper()
                DoubleTouch.freekickPosition = touchingRobot.pos:copy()
                DoubleTouch.executingTeam = World[defenseTeam.."ColorStr"]
                local offenseTeam = touchingRobot.isYellow and "Yellow" or "Blue"
                DoubleTouch.message = "Double touch by " .. offenseTeam .. " " .. touchingRobot.id
                return true
            else
                lastTouchingRobotInFreekick = nil
            end
        end
    else
        lastTouchingRobotInFreekick = nil
    end
    return false
end

return DoubleTouch
