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
            angleRotation = pi/2
        end
        if data.steerStickX < 0 then
            angleRotation = -(pi/2)
        end
        goto AfterAngle
    end
    angleRotation = math.atan(data.steerStickX/data.steerStickY)
    --Should return the radian value of rotation of joystick position from origin. 0 being upright; >0 clockwise; <0 anticlockwise

    ::AfterAngle::

    local rotationMagnitude = angleRotation / steeringRange
    if angleRotation > steeringRange then
        rotationMagnitude = 0
    end

    local linearMagnitude = math.sqrt( (data.steerStickX^2) * (data.steerStickY^2) )

    local steerMagnitude = math.clamp(rotationMagnitude * linearMagnitude, -1, 1 )

    data.steer = steerMagnitude
end