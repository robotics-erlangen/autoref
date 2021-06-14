require "amun"

local AutorefTestHelper = {}

local function failTestWithMessage(message)
	amun.log("os.exit(1)")
	error(message)
end

local function splitString(inputstr, sep)
	local t = {}
	-- replace with some character that will never be in the input string
	subbed = string.gsub(inputstr, sep, "§")
	for str in string.gmatch(subbed, "([^§]+)") do
		table.insert(t, str)
	end
	return t
end

function AutorefTestHelper.debugTreeToObject(debugValues, prefix)
	local result = {}
	local hasParts = false
	for _, value in ipairs(debugValues) do
		local split = splitString(value.key, prefix)
		if #split == 2 then
			local objectParts = splitString(split[2], "/")
			local objectToWriteTo = result
			for i = 1,#objectParts-1 do
				if not objectToWriteTo[objectParts[i]] or type(objectToWriteTo[objectParts[i]]) ~= "table" then
					objectToWriteTo[objectParts[i]] = {}
				end
				objectToWriteTo = objectToWriteTo[objectParts[i]]
			end
			if value.float_value then
				objectToWriteTo[objectParts[#objectParts]] = value.float_value
			elseif value.bool_value then
				objectToWriteTo[objectParts[#objectParts]] = value.bool_value
			elseif value.string_value then
				objectToWriteTo[objectParts[#objectParts]] = value.string_value
			else
				objectToWriteTo[objectParts[#objectParts]] = nil
			end

			hasParts = true
		end
	end
	if not hasParts then
		return nil
	end
	return result
end

local hadEvent = false

function evaluateSingleEvent(event, desiredEvent)
    if desiredEvent.stop_after_event and hadEvent then
        return
    end
    
    if not desiredEvent.expected_event then
        failTestWithMessage("Did not expect event " .. event.type)
    end
    
    local expected = desiredEvent.expected_event
    if event.type ~= expected.type then
        failTestWithMessage("Wrong event type: expected " .. expected.type .. " but got " .. event.type)
    end
    
    -- extract event message
    local messageName = ""
    for name, _ in pairs(expected) do
        if name ~= "type" then
            messageName = name
        end
    end
    
    local expectedMessage = expected[messageName]
    local message = event[messageName]
    
    -- must match exactly
    local checkProperties = {"by_bot", "by_team", "kicking_team", "kicking_bot", "num_robots_by_team"}
    
    for _, property in ipairs(checkProperties) do
        if expectedMessage[property] and message[property] and expectedMessage[property] ~= message[property] then
            failTestWithMessage("Property " .. property .." did not match: expected " .. expectedMessage[property] .. " but got " .. message[property])
        end
    end

    -- location fields
    local checkLocations = {"location", "kick_location"}
    for _, property in ipairs(checkLocations) do
        if expectedMessage[property] and message[property] then
            local xDiff = expectedMessage[property].x - message[property].x
            local yDiff = expectedMessage[property].y - message[property].y
            local diff = math.sqrt(xDiff * xDiff + yDiff * yDiff)
            if diff > 0.5 then
                failTestWithMessage("Location " .. property .." too different: (" .. expectedMessage[property].x .. ", " .. expectedMessage[property].y ..") vs ("
                                    .. message[property].x .. ", " .. message[property].y .. ")")
            end
        end
    end
    
    -- check max ball height for possible goals
    if expectedMessage.max_ball_height and message.max_ball_height and (expectedMessage.max_ball_height) > 0.2 ~= (message.max_ball_height > 0.2) then
        failTestWithMessage("Max ball height did not match: expected " .. expectedMessage.max_ball_height .. " but got " .. message.max_ball_height)
    end
end

function AutorefTestHelper.testEvent(desiredEvent)
	local function testStatus(status)
		for _, d in ipairs(status.debug) do
            for _, l in ipairs(d.log) do
                amun.log(l.text)
            end
            
			local eventCounter = 1
			while true do
				-- omit GAME_ from string so there is some first part of the string if it is toplevel
				local object = AutorefTestHelper.debugTreeToObject(d.value, "CONTROLLER_EVENTS/"..eventCounter.."/")
				if object then
					evaluateSingleEvent(object, desiredEvent)
                    hadEvent = true
				else
					break
				end
				eventCounter = eventCounter + 1
			end
		end
	end

	local function runFrame()
		local status = amun.getTestStatus()
		if status.time then
			testStatus(status)
		else
			if desiredEvent.expected_event and not hadEvent then
                failTestWithMessage("Expected event " .. desiredEvent.expected_event.type .. " but got none")
            end
		end
	end
	return {name = "Autoref test", entrypoints = {main = runFrame}}
end

return AutorefTestHelper
