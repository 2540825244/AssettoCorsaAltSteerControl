--LocalVariable
local pi = math.pi

--Configuration
local steeringRange = 0.9*pi

--Main Script
function script.update(dt)
    local data = ac.getJoypadState()

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
    local atan = math.abs(math.atan(data.steerStickX/data.steerStickY))
    if data.steerStickX > 0 & data.steerStickY > 0 then
        angleRotation = atan
        goto AfterAngle
    end
    if data.steerStickX < 0 & data.steerStickY > 0 then
        angleRotation = -atan
        goto AfterAngle
    end
    if data.steerStickX > 0 & data.steerStickY < 0 then
        angleRotation = pi - atan
        goto AfterAngle
    end
    if data.steerStickX < 0 & data.steerStickY < 0 then
        angleRotation = atan - pi
        goto AfterAngle
    end
    --angleRotation should be the radian value of rotation of joystick position from origin. 0 being upright; >0 clockwise; <0 anticlockwise

    ::AfterAngle::

    local rotationMagnitude = angleRotation / steeringRange
    if rotationMagnitude > 1 then
        rotationMagnitude = 0
    end

    local linearMagnitude = math.sqrt( (data.steerStickX^2) * (data.steerStickY^2) )

    local steerMagnitude = math.clamp(rotationMagnitude * linearMagnitude, -1, 1 )

    data.steer = steerMagnitude
end