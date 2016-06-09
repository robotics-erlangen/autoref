local FreekickDistance = {}

FreekickDistance.possibleRefStates = {
    Direct = true,
    Indirect = true,
    Stop = true,
}

local stopBallPos
function FreekickDistance.occuring()
    if World.RefereeState == "Stop" or not stopBallPos then
        stopBallPos = World.Ball.pos
        return false
    end
    local defense = World.RefereeState:match("irect(%a+)") == "Yellow" and "Blue" or "Yellow"
    for _, robot in ipairs(World[defense.."Robots"]) do
        if robot.pos:distanceTo(stopBallPos)-robot.shootRadius < 0.5 then
            local color = robot.isYellow and World.YellowColorStr or World.BlueColorStr
            FreekickDistance.consequence = "STOP"
            FreekickDistance.message = color .. " " .. robot.id .. " did not keep 50cm distance to ball during free kick"
            return true
        end
    end
end

return FreekickDistance
