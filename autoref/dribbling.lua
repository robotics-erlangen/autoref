local Dribbling = {}

local MAX_DRIBBLING_DIST = 1
local Referee = require "../base/referee"

Dribbling.possibleRefStates = {
    Game = true
}

local dribblingStart
function Dribbling.occuring()
    local currentTouchingRobot
    for _, robot in ipairs(World.Robots) do
        if robot.pos:distanceTo(World.Ball.pos) <= Referee.touchDist then
            currentTouchingRobot = robot
            break
        end
    end
    if currentTouchingRobot then
        if not dribblingStart or currentTouchingRobot ~= Referee.robotAndPosOfLastBallTouch() then
            dribblingStart = currentTouchingRobot.pos:copy()
        end
        if currentTouchingRobot.pos:distanceTo(dribblingStart) > MAX_DRIBBLING_DIST then
            Dribbling.executingTeam = World.YellowColorStr
            Dribbling.consequence = "INDIRECT_FREE_YELLOW"
            if currentTouchingRobot.isYellow then
                Dribbling.executingTeam = World.BlueColorStr
                Dribbling.consequence = "INDIRECT_FREE_BLUE"
            end
            Dribbling.freekickPosition = currentTouchingRobot.pos:copy()
            return true
        end
    else
        dribblingStart = nil
    end
end

function Dribbling.print()
    local lastTeam = Referee.teamWhichTouchedBallLast()
    local lastRobot = Referee.robotAndPosOfLastBallTouch()
    if lastRobot then -- should always be the case
        log("dribbling over " .. MAX_DRIBBLING_DIST .. "m by " .. lastTeam .. " " .. lastRobot.id)
    end
end

return Dribbling
