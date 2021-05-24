local Parameters = {}

local IO = require "base/io"
local debug = require "base/debug"

local defaultValues = {}
function Parameters.add(modulename, name, defaultValue)
	local fullname = modulename.."/"..name
	defaultValues[fullname] = defaultValue
	return function()
		return Parameters.get(fullname)
	end
end

local values = {}
function Parameters.get(name)
	return values[name]
end

local parameterFilename = "parameters"
function Parameters.update()
	values = IO.read(parameterFilename)
	local changed = false
	for name, value in pairs(defaultValues) do
		if not values[name] then
			values[name] = value
			changed = true
		end
	end
	if changed then
		IO.save(parameterFilename, values)
	end
	debug.set("parameters", values)
end

return Parameters