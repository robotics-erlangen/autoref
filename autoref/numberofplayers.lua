local NumberOfPlayers = {}

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
        NumberOfPlayers.consequence = "STOP"
        NumberOfPlayers.message = World.YellowColorStr .. " team has more than 6 players on the field!"
        return true
    elseif #World.BlueRobots > 6 then
        NumberOfPlayers.consequence = "STOP"
        NumberOfPlayers.message = World.BlueColorStr .. " team has more than 6 players on the field!"
        return true
    end

    return false
end

return NumberOfPlayers
