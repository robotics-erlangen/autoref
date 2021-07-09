--[[***********************************************************************
*   Copyright 2021 Andreas Wendler                                        *
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

local Class = require "base/class"
local Rule = Class("Rules.Rule")

-- static properties
Rule.possibleRefStates = {} -- must contain a list of ref states in which the rule should run
Rule.shouldAlwaysExecute = false -- execute even directly after the rule was triggered (prevent timeout until next rule trigger)
Rule.runOnInvisibleBall = false -- if the rule should be executed when the ball is not currently visible
Rule.resetOnInvisibleBall = false

-- the init function can have one parameter, the world object used for dependency injection

-- returns a rule violation event if the rule is currently violated and a matching message
function Rule:occuring()
	error("stub")
end

function Rule:reset()
	-- override if necessary
	-- will be called in each frame the function occuring is not called (due to invisible ball,
	-- time after last rule trigger or not matching ref state)
end

return Rule
