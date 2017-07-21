local NumberOfPlayers = {}

local Event = require "event"

NumberOfPlayers.possibleRefStates = {
    Halt = true,
    Stop = true,
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

function NumberOfPlayers.occuring()
    if #World.YellowRobots > 6 then
        for _, robot in ipairs(World.YellowRobots) do
            for _, otherRobot in ipairs(World.YellowRobots) do
                if robot~= otherRobot and robot.pos:distanceTo(otherRobot.pos) < 0.07 then
                    -- probably vision problems
                    return false
                end
            end
        end
        NumberOfPlayers.consequence = "STOP"
        NumberOfPlayers.message = World.YellowColorStr .. " team has more than<br>6 players on the field!"
        NumberOfPlayers.event = Event("NumberOfPlayers", true, nil, nil, #World.YellowRobots .. " players on the field")
        return true
    elseif #World.BlueRobots > 6 then
        for _, robot in ipairs(World.BlueRobots) do
            for _, otherRobot in ipairs(World.BlueRobots) do
                if robot~= otherRobot and robot.pos:distanceTo(otherRobot.pos) < 0.07 then
                    -- probably vision problems
                    return false
                end
            end
        end
        NumberOfPlayers.consequence = "STOP"
        NumberOfPlayers.message = World.BlueColorStr .. " team has more than<br>6 players on the field!"
        NumberOfPlayers.event = Event("NumberOfPlayers", false, nil, nil, #World.BlueRobots .. " players on the field" )
        return true
    end

    return false
end

return NumberOfPlayers
