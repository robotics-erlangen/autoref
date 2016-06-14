local AttackerDefAreaDist = {}

local Field = require "../base/field"

AttackerDefAreaDist.possibleRefStates = {
    Game = true,
    Indirect = true,
    Direct = true,
}

local offender
-- the distance has to be respected only "at the time enters play"
-- therefore we wait for the switch from a freekick to game state
local wasFreeKickBefore = {
    Blue = false,
    Yellow = false
}
function AttackerDefAreaDist.occuring()
    offender = nil

    for offense, defense in pairs({Blue = "Yellow", Yellow = "Blue"}) do
        if wasFreeKickBefore[offense] and World.RefereeState == "Game" then
            for _, robot in ipairs(World[offense.."Robots"]) do
                if Field["distanceTo"..defense.."DefenseArea"](robot.pos, robot.radius) <= 0.2 then
                    offender = robot
                    AttackerDefAreaDist.consequence = "INDIRECT_FREE_"..defense:upper()
                    AttackerDefAreaDist.freekickPosition = World.Ball.pos:copy()
                    AttackerDefAreaDist.executingTeam = World[defense.."ColorStr"]
                    break
                end
            end
        end
    end

    if World.RefereeState == "DirectBlue" or World.RefereeState == "IndirectBlue" then
        wasFreeKickBefore.Blue = true
    elseif World.RefereeState == "DirectYellow" or World.RefereeState == "IndirectYellow" then
        wasFreeKickBefore.Yellow = true
    else -- both cannot remain true because there has to be a STOP between free kicks
        wasFreeKickBefore.Blue = false
        wasFreeKickBefore.Yellow = false
    end

    if offender then
        local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
        AttackerDefAreaDist.message = color .. " " .. offender.id ..
            " did not keep 20cm distance<br>to opponent's defense area"
        return true
    end
end

return AttackerDefAreaDist
