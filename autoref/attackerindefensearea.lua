--[[***********************************************************************
*   Copyright 2015 Alexander Danzer                                       *
*   Robotics Erlangen e.V.                                                *
*   http://www.robotics-erlangen.de/                                      *
*   info@robotics-erlangen.de                                             *
*                                                                         *
*   This program is free software: you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation, either version 3 of the License, or     *
*   any later version.                                                    *
*                                                                         *
*   This program is distributed in the hope that it will be useful,       *
*   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
*   GNU General Public License for more details.                          *
*                                                                         *
*   You should have received a copy of the GNU General Public License     *
*   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
*************************************************************************]]

local AttackerInDefenseArea = {}

local Field = require "../base/field"
local Referee = require "../base/referee"
local World = require "../base/world"
local Event = require "event"

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

            -- foul 2: attacker touches keeper, while point of contact is in defense area
            if keeper and keeper.pos:distanceTo(robot.pos) <= keeper.radius+robot.radius then
                local pointOfContact = keeper.pos + (robot.pos-keeper.pos):normalize()*keeper.radius
                if Field["isIn"..defense.."DefenseArea"](pointOfContact, 0) then
                    touchingGoalie = true
                    offender = robot
                end
            end

            if offender then
                AttackerInDefenseArea.consequence = "INDIRECT_FREE_" .. defense:upper()
                AttackerInDefenseArea.executingTeam = World[defense.."ColorStr"]
                AttackerInDefenseArea.freekickPosition = offender.pos:copy()
                local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
                if touchingGoalie then
                    AttackerInDefenseArea.message = color .. " " .. offender.id ..
                        " touched goalie inside defense area"
                else
                    AttackerInDefenseArea.message = color .. " " .. offender.id ..
                        " touched the ball in defense area"
                end
                AttackerInDefenseArea.event = Event("AttackerInDefenseArea",
                    offender.isYellow, offender.pos, {offender.id}, "contact with " .. (touchingGoalie and "goalie" or "ball"))
                return true
            end
        end
    end
end

return AttackerInDefenseArea
