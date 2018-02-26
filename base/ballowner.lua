local World = require "../base/world"

local BallOwner = {}

--- Calculates the effective distance between ball and dribbler
-- find an ellipsis with the left and right dribbler edge points as focal points
-- dist is the length of the semi-minor axis
-- @param robot robot - the robot to calculate
-- @param ballPos vector - position of the ball
local function ellipticDistance(robot, ballPos)
	local dribblerPos = robot.pos + Vector.fromAngle(robot.dir):scaleLength(robot.shootRadius)
	local dribblerWidthHalf = Vector.fromAngle(robot.dir - math.pi/2):scaleLength(robot.dribblerWidth/2)
	local leftDribblerEdge = dribblerPos + dribblerWidthHalf
	local rightDribblerEdge = dribblerPos - dribblerWidthHalf
	return 0.5*math.sqrt((leftDribblerEdge:distanceTo(ballPos) + rightDribblerEdge:distanceTo(ballPos))^2 - robot.dribblerWidth*robot.dribblerWidth)
end

--- Returns the ball owner or nil if no robot is on the field
-- @return ballOwner robot - the robot that can be seen as ball owner, or nil
local BALL_OWN_HYSTERESIS = 0.03
local lastBallOwner = nil
local lastCall = 0
function BallOwner.lastRobot()
    if lastCall and lastCall == World.Time then -- cached result
        return lastBallOwner
    else
        lastCall = World.Time
    end

	-- search robot with min dist to ball
	local minDist = math.huge
	local ballOwner = nil
	for _, r in ipairs(World.Robots) do
		local dist = ellipticDistance(r, World.Ball.pos)
		if dist < minDist then
			minDist = dist
			ballOwner = r
		end
	end

	-- calculate dist from lastBallOwner to ball
	local lastDist = math.huge
	if lastBallOwner then
		lastDist = ellipticDistance(lastBallOwner, World.Ball.pos)
	end

	-- set new lastBallOwner or nil, if no robot is on the field
	if minDist + BALL_OWN_HYSTERESIS < lastDist then
		lastBallOwner = ballOwner
	end

	return lastBallOwner
end

return BallOwner
