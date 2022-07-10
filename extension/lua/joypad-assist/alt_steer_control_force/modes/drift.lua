local virtualSteer = 0
local steerAngle = 0
local steerVelocity = 0
local driverSteerAngle = 0
local driverSteerVelocity = 0

--Local variables of alt steer control
local pi = math.pi
local steeringRange = 0.9*pi

ac.onCarJumped(0, function ()
  steerVelocity = 0
  steerAngle = 0
  driverSteerAngle = 0
  driverSteerVelocity = 0
end)

local steerStickSpeedBase = 14
local steerForceVelocityDecrease = 1
local ffbPositionMultSameDirection = 0.5
local ffbPositionMultOppositeDirection = 1
local ffbPositionMultGamma = 1
local steerAngleFadeBase = 0.9943
local steerVelocityBoundaryMult = 0.8
local speedForceBase = 0.42
local forceFactorBase = 12

local function update(dt)
  -- Assist-related data
  local data = ac.getJoypadState()

  -- Calculate virtual steer angle
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

  local rotationMagnitude = angleRotation / steeringRange
  if rotationMagnitude > 1 then
      rotationMagnitude = 1
  end
  if rotationMagnitude < -1 then
      rotationMagnitude = -1
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

  data.steer = steerMagnitude

  -- Input steer angle (TODO: switch to data.steerStick to use original settings)
  -- local steer = ac.getGamepadAxisValue(0, ac.GamepadAxis.LeftThumbX)

  -- A bit of gamma correction to improve deadzone situation (TODO: also add regular deadzone)
  -- steer = math.pow(steer, 2) * math.sign(steer)
  -- steer = math.lerpInvSat(math.abs(steer), 0.1, 1) * math.sign(steer)

  -- Actual steering input:
  local steer = virtualSteer
  local speedForce = speedForceBase
  local forceFactor = forceFactorBase
  local steerAngleFade = steerAngleFadeBase
  speedForce = speedForce - (math.abs(steerMagnitude)^2)*0.075
  local steerAD = (math.abs(data.localAngularVelocity.y) + 0.45) / (1 + math.abs(data.localVelocity.x)^0.3)
   if steerAD > 0.65 then
	steerAD = 0.65
  end 
   if steerAD < 0.28 then
	steerAD = 0.28
  end 
  if (data.ndSlipRR + data.ndSlipRL)/2 < 1 then
    steerAD = 0.28
	speedForce = 0.1
	steerAngleFade = 0.993
  end   
  local newSteerStick = steerMagnitude * steerAD
  local steerStickSpeed = steerStickSpeedBase
  local steerDelta = newSteerStick - steer
  steer = steer + math.min(steerStickSpeed * dt, math.abs(steerDelta)) * math.sign(steerDelta)
  virtualSteer = steer

  -- Base steering force:
  local steerForce = steer
   
  -- FFB force:
  local ffbForce = -data.ffb * speedForce
  local ffbPositionMult = math.sign(steerAngle) == math.sign(ffbForce) and ffbPositionMultSameDirection or ffbPositionMultOppositeDirection
  ffbForce = ffbForce * math.lerp(1, ffbPositionMult, math.pow(math.abs(steerAngle), ffbPositionMultGamma))

  -- Resulting force is the sum of both:
  local force = steerForce + ffbForce

  -- Applying tonemapping-like correction to make sure force would not exceed 1
  force = force / (1 + math.abs(force))

  -- Force and velocity application with a bit of drag
  local dSteer = (steerMagnitude * (data.localVelocity.x * 0.001)) * (-0.07) + (1 + math.abs(data.localVelocity.x)^0.3) * 0.0005
  steerAngleFade = steerAngleFade + dSteer + (steerAD - 0.28) / 1000
  if steerAngleFade > 0.997 then
	steerAngleFade = 0.997
  end 
  steerVelocity = steerVelocity * steerAngleFade + forceFactor * force * dt  
  steerAngle = steerAngle * steerAngleFade + steerVelocity * dt

  -- Driver steering
  --local driverSteerShare = math.max(math.min(1, math.abs(steer * 10)), math.lerpInvSat(data.speedKmh, 20, 10))
  --driverSteerVelocity = driverSteerVelocity * steerAngleFade + 50 * force * dt * driverSteerShare
  --driverSteerAngle = math.clamp(driverSteerAngle * math.lerp(driverSteerAngleFade, steerAngleFade, driverSteerShare) + driverSteerVelocity * dt, -1, 1)
  
  --ac.setCustomDriverModelSteerAngle(driverSteerAngle * ac.getCar(0).steerLock)

  -- Very important part
  if steerAngle < -1 or steerAngle > 1 then
    steerVelocity = steerVelocity * steerVelocityBoundaryMult
  end  

  -- Writing new steer angle with a bit of smoothing just in case (completely ignoring original value)
  data.steer = math.clamp(steerAngle, -1, 1)

  -- Vibrations
  local baseForce = math.saturate(data.speedKmh / 20 - 0.5) * math.abs(ffbForce * 4) * math.saturate(math.abs(ffbForce - steerForce) * 2 - 0.5)
  local offset = data.gForces.x / (1 + math.abs(data.gForces.x)) -- slightly offset vibrations based on X g-force (might have a wrong sign though)
  data.vibrationLeft = baseForce * (1 + offset) + math.saturate(data.speedKmh / 100) * data.surfaceVibrationGainLeft / 20
  data.vibrationRight = baseForce * (1 - offset) + math.saturate(data.speedKmh / 100) * data.surfaceVibrationGainRight / 20
  
  -- Debug:
  --ac.debug('data.localVelocity.x', data.localVelocity.x)
  --ac.debug('speedForce', speedForce) 
  --ac.debug('forceFactor', forceFactor)
  --ac.debug('steerAngleFade', steerAngleFade)  
  --ac.debug('steerAD', steerAD) 
end

return {
  name = 'Drift',
  update = update, 
  sync = function (m) steerAngle, steerVelocity = m.export() end,
  export = function () return steerAngle, steerVelocity end,
}

