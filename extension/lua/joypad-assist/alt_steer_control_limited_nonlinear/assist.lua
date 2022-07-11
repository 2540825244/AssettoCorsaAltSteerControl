--Local Variable
local pi = math.pi
local lastSteer = 0

--Configuration
local steeringRange = 0.9*pi
local steeringSpeedLimit = 6 --Limiter of steering speed in dSteer / second
local firstStageSensitivity = 0.1 --Sensitivity of first stage (upper hemisphere). 0 to 1. Equals to steer/angleRotation

--Derived Local Variable
local secondStageOffset = ((0.5*pi) * firstStageSensitivity) / steeringRange
local secondStageSensitivity = (1-secondStageOffset) / (steeringRange - (0.5*pi))

--Main Script
function script.update(dt)
    local data = ac.getJoypadState()

    local atan = 0

    local angleRotation = 0
    if data.steerStickX == 0 then
        goto AfterAngle
    end
    if data.steerStickY == 0 then
        if data.steerStickX > 0 then
            angleRotation = 0.5*pi
        end
        if data.steerStickX < 0 then
            angleRotation = -(0.5*pi)
        end
        goto AfterAngle
    end
    atan = math.abs(math.atan(data.steerStickX/data.steerStickY))
    if (data.steerStickX > 0) and (data.steerStickY > 0) then
        angleRotation = atan
        goto AfterAngle
    end
    if (data.steerStickX < 0) and (data.steerStickY > 0) then
        angleRotation = -atan
        goto AfterAngle
    end
    if (data.steerStickX > 0) and (data.steerStickY < 0) then
        angleRotation = pi - atan
        goto AfterAngle
    end
    if (data.steerStickX < 0) and (data.steerStickY < 0) then
        angleRotation = atan - pi
        goto AfterAngle
    end
    --angleRotation should be the radian value of rotation of joystick position from origin. 0 being upright; >0 clockwise; <0 anticlockwise

    ::AfterAngle::

    local rotationMagnitude = 0
    if math.abs(angleRotation) <= (0.5*pi) then
        rotationMagnitude = (angleRotation * firstStageSensitivity) / steeringRange
    end
    if math.abs(angleRotation) > (0.5*pi) then
        rotationMagnitude = (((angleRotation - ((0.5*pi) * math.sign(angleRotation))) * secondStageSensitivity) / steeringRange) + (secondStageOffset * math.sign(angleRotation))
    end

    local maxLength = 1
    if math.abs(data.steerStickX) > math.abs(data.steerStickY) then
        maxLength = math.sqrt( 1 + ( (data.steerStickY / data.steerStickX ) ^2) )
        goto AfterMaxLength
    end
    if math.abs(data.steerStickY) > math.abs(data.steerStickX) then
        maxLength = math.sqrt( 1 + ( (data.steerStickX / data.steerStickY ) ^2) )
    end

    ::AfterMaxLength::

    local linearLength = math.sqrt( (data.steerStickX^2) + (data.steerStickY^2) )

    local linearMagnitude = math.clamp( linearLength/maxLength, -1, 1)

    local steerMagnitude = math.clamp(rotationMagnitude * linearMagnitude, -1, 1 )

    local internalSteeringLimit =  steeringSpeedLimit * dt
    local dSteer = steerMagnitude - lastSteer
    if math.abs(dSteer) > internalSteeringLimit then
        steerMagnitude = lastSteer + math.sign(dSteer) * internalSteeringLimit
    end

    data.steer = steerMagnitude
    lastSteer = data.steer
end