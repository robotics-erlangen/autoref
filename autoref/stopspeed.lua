local StopSpeed = {}

local ROBOT_SLOW_DOWN_TIME = 2

StopSpeed.possibleRefStates = {
    Stop = true,
    Ball = true,
}

local lastCallTime = 0
local enterStopTime = 0
function StopSpeed.occuring()
    if World.Time - lastCallTime > 0.5 then
        -- it is safe to assume that the strategy is executed with a higher
        -- frequence than 0.5s -> there was another ref state in the meantime
        enterStopTime = World.Time
    end
    lastCallTime = World.Time
    if World.Time - enterStopTime < ROBOT_SLOW_DOWN_TIME then
        return false
    end

    for _, robot in ipairs(World.Robots) do
        if robot.speed:length() > 1.5 then
            StopSpeed.consequence = "YELLOW_CARD_" .. (robot.isYellow and "YELLOW" or "BLUE")
            local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
            StopSpeed.message = color .. " " .. robot.id .. " is driving with over 1.5m/s during STOP"
            return true
        end
    end
    return false
end

return StopSpeed
