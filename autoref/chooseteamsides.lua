-- this is not a rule, but misueses this mecanism.
-- therefore 'occuring' should always return false

local Field = require "../base/field"
local ChooseTeamSides = {}

ChooseTeamSides.possibleRefStates = {
    Halt = true,
    Stop = true,
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
}

local flipAttemptValue = true -- status is either true or false
local frameNumber = 0
local frameNumberOfLastFlipAttempt = 0
function ChooseTeamSides.occuring()
    frameNumber = frameNumber + 1
    -- ssl vision does not provide information about team sides.
    -- Therefore, we switch team sides if both goalies are located in the
    -- opponents defense are.
    if World.BlueKeeper and Field.isInYellowDefenseArea(World.BlueKeeper.pos) and
            World.YellowKeeper and Field.isInBlueDefenseArea(World.YellowKeeper.pos)
            and frameNumber > frameNumberOfLastFlipAttempt+5 then
        -- currently, the switch status is not retrievable. Therefore,
        -- if the flip was not effective we try again with the other possibility
        flipAttemptValue = not flipAttemptValue

        amun.sendCommand({ flip = flipAttemptValue })
        frameNumberOfLastFlipAttempt = frameNumber
    end

    return false
end

return ChooseTeamSides
