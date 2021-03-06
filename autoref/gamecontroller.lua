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

local GameController = {}

local STATE_UNCONNECTED = 1
local STATE_CONNECTED = 2

local state = STATE_UNCONNECTED

function GameController.update()
	if amun.connectGameController() then
		if state == STATE_UNCONNECTED then
			state = STATE_CONNECTED
			amun.sendGameControllerMessage("AutoRefRegistration", {identifier="ER-Force"})
		end

	else
		state = STATE_UNCONNECTED
	end
end

function GameController.sendEvent(event)
	event.origin = {"ER-Force"}
	if state == STATE_CONNECTED then
		amun.sendGameControllerMessage("AutoRefToController", {game_event=event})
	else
		log("Not connected to game controller!")
	end
end

return GameController
