local FreekickDistance = {}

FreekickDistance.possibleRefStates = {
    Direct = true,
    Indirect = true
}

local offender
function FreekickDistance.occuring()
    local defense = World.RefereeState:match("irect(%a+)") == "Yellow" and "Blue" or "Yellow"
    for _, robot in ipairs(World[defense.."Robots"]) do
        if robot.pos:distanceTo(World.Ball.pos)-robot.shootRadius < 0.5 then
            offender = robot
            FreekickDistance.consequence = "STOP"
            return true
        end
    end
end

function FreekickDistance.print()
    local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
    log(color .. " " .. offender.id .. " did not keep 50cm distance to ball during free kick")
end

return FreekickDistance
