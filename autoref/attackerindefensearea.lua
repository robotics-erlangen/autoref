local AttackerInDefenseArea = {}

local Field = require "../base/field"
local Referee = require "../base/referee"

AttackerInDefenseArea.possibleRefStates = {
    Game = true,
}

local offender, touchingGoalie
function AttackerInDefenseArea.occuring()
    offender = nil
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
        local keeper = World[defense.."Keeper"]
        for _, robot in ipairs(World[offense.."Robots"]) do
            -- foul 1: attacker touches ball and is in defense area, even if partially
            if Field["isIn"..defense.."DefenseArea"](robot.pos, robot.radius) then
                if robot.pos:distanceTo(World.Ball.pos) <= Referee.touchDist then
                    touchingGoalie = false
                    offender = robot
                end
            end

            -- foul 2: attacker touches keeper, while point of contact is in defense are
            if keeper and keeper.pos:distanceTo(robot.pos) <= keeper.radius+robot.radius then
                local pointOfContact = keeper.pos + (robot.pos-keeper.pos):normalize()*keeper.radius
                if Field["isIn"..defense.."DefenseArea"](pointOfContact) then
                    touchingGoalie = true
                    offender = robot
                end
            end

            if offender then
                AttackerInDefenseArea.consequence = "INDIRECT_FREE_" .. defense:upper()
                AttackerInDefenseArea.executingTeam = World[defense.."ColorStr"]
                AttackerInDefenseArea.freekickPosition = robot.pos:copy()
                return true
            end
        end
    end
end

function AttackerInDefenseArea.print()
    local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
    if touchingGoalie then
        log(color .. " " .. offender.id .. " touched goalie, while point of contact was in defense area")
    else
        log(color .. " " .. offender.id .. " touched the ball in opponent's defense area")
    end
end

return AttackerInDefenseArea
