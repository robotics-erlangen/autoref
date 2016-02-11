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

local offendingTeam
function NumberOfPlayers.occuring()
    offendingTeam = nil
    if #World.YellowRobots > 6 then
        NumberOfPlayers.consequence = "STOP"
        offendingTeam = World.YellowColorStr
        return true
    elseif #World.BlueRobots > 6 then
        NumberOfPlayers.consequence = "STOP"
        offendingTeam = World.BlueColorStr
        return true
    end

    return false
end

function NumberOfPlayers.print()
    log(offendingTeam .. " team has more than 6 players on the field!")
end

return NumberOfPlayers
