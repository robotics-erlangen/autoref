local StopSpeed = {}

StopSpeed.possibleRefStates = {
    Stop = true
}

local offender
function StopSpeed.occuring()
    offender = nil
    for _, robot in ipairs(World.Robots) do
        if robot.speed:length() > 1.5 then
            StopSpeed.consequence = "YELLOW_CARD_" .. (robot.isYellow and "YELLOW" or "BLUE")
            offender = robot
            return true
        end
    end
end

function StopSpeed.print()
    local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
    log(color .. " " .. offender.id .. " is driving with over 1.5m/s during STOP")

end

return StopSpeed
