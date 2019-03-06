--[[***********************************************************************
*   Copyright 2019 Andreas Wendler                                        *
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

local AttackerTouchKeeper = {}

local Field = require "../base/field"
local World = require "../base/world"
local Event = require "gameevent2019"

AttackerTouchKeeper.possibleRefStates = {
    Game = true,
    Kickoff = true,
    Penalty = true,
    Direct = true,
    Indirect = true,
    Ball = true,
    Stop = true,
}

function AttackerTouchKeeper.occuring()
    for offense, defense in pairs({Yellow = "Blue", Blue = "Yellow"}) do
        local keeper = World[defense.."Keeper"]
        for _, robot in ipairs(World[offense.."Robots"]) do
            -- attacker touches keeper, while point of contact is in defense area
            if keeper and keeper.pos:distanceTo(robot.pos) <= keeper.radius+robot.radius then
                local pointOfContact = keeper.pos + (robot.pos-keeper.pos):normalize()*keeper.radius
                if Field["isIn"..defense.."DefenseArea"](pointOfContact, 0) then
                    local color = offender.isYellow and World.YellowColorStr or World.BlueColorStr
                    AttackerTouchKeeper.message = color .. " " .. offender.id ..
                        " touched goalie inside defense area"
                    AttackerTouchKeeper.event = Event.attackerTouchKeeper(robot.isYellow, robot.id, pointOfContact)
                    return true
                end
            end
        end
    end
end

return AttackerTouchKeeper
