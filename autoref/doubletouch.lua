local DoubleTouch = {}

local Referee = require "../base/referee"

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
}

local lastTouchingRobotInFreekick
function DoubleTouch.occuring()
    local simpleRefState = World.RefereeState:match("%u%l+")
    if simpleRefState == "Indirect" or simpleRefState == "Direct" then
        lastTouchingRobotInFreekick = Referee.robotAndPosOfLastBallTouch()
    elseif World.RefereeState == "Game" and lastTouchingRobotInFreekick then
        local touchingRobot
        for _, robot in ipairs(World.Robots) do
            if robot.pos:distanceTo(World.Ball.pos) < Referee.touchDist then
                touchingRobot = robot
            end
        end
        if touchingRobot then
            if touchingRobot == lastTouchingRobotInFreekick then
                local defenseTeam = touchingRobot.isYellow and "Blue" or "Yellow"
                DoubleTouch.consequence = "INDIRECT_FREE_" .. defenseTeam:upper()
                DoubleTouch.freekickPosition = touchingRobot.pos:copy()
                DoubleTouch.executingTeam = World[defenseTeam.."ColorStr"]
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

function DoubleTouch.print()
    local color = lastTouchingRobotInFreekick.isYellow and World.YellowColorStr or World.BlueColorStr
    log("Double touch by " .. color .. " " .. lastTouchingRobotInFreekick.id)
end

return DoubleTouch
