local Refbox = {}

local VALID_REF_COMMANDS = {
    HALT = true,
    STOP = true,
    NORMAL_START = true,
    FORCE_START = true,
    PREPARE_KICKOFF_YELLOW = true,
    PREPARE_KICKOFF_BLUE = true,
    PREPARE_PENALTY_YELLOW = true,
    PREPARE_PENALTY_BLUE = true,
    DIRECT_FREE_YELLOW = true,
    DIRECT_FREE_BLUE = true,
    INDIRECT_FREE_YELLOW = true,
    INDIRECT_FREE_BLUE = true,
    TIMEOUT_YELLOW = true,
    TIMEOUT_BLUE = true,
    GOAL_YELLOW = true,
    GOAL_BLUE = true,
    BALL_PLACEMENT_BLUE = true,
    BALL_PLACEMENT_YELLOW = true,
	YELLOW_CARD_BLUE = true,
	YELLOW_CARD_YELLOW = true,
	RED_CARD_BLUE = true,
	RED_CARD_YELLOW = true,
}
function Refbox.send(command, placementPos)
    if not VALID_REF_COMMANDS[command] then
        error("invalid refbox command " .. command)
    end
    local cmd = {
        message_id = 1,
        command = command,
    }
    if command:sub(0,14) == "BALL_PLACEMENT" then
        cmd.designated_position = {
            x = placementPos.x,
            y = placementPos.y
        }
    end
	if command:match("(%a+)_CARD_(%a+)") then
		cmd.card = {
			type = "CARD_" .. command:match("(%a+)_CARD_"),
			team = "TEAM_" .. command:match("_CARD_(%a+)")
		}
	end
    if not amun.sendNetworkRefereeCommand then
        error("you must enable debug mode in order to send referee commands")
    end
    log("send refbox command: " .. command)
    amun.sendNetworkRefereeCommand(cmd)
end

return Refbox
