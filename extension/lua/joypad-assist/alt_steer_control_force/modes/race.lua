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

local steerForceVelocityDecrease = 0
local ffbPositionMultSameDirection = 0.5
local ffbPositionMultOppositeDirection = 1
local ffbPositionMultGamma = 1
local steerAngleFadeBase = 0.988
local steerVelocityBoundaryMult = 0.8
local speedForceBase = 0.04
local forceFactorBase = 14

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

  -- Actual steering input:
  local steerSens = data.steeringSpeed * 150 + 4
  local steerStickSpeed = 70 / (data.steeringFilter * 8 + 1)
  local steer = virtualSteer
  local newSteerStick = steerMagnitude * (steerSens * 0.1)
  local steerDelta = newSteerStick - steer
  steer = steer + math.min(steerStickSpeed * dt, math.abs(steerDelta)) * math.sign(steerDelta)
  virtualSteer = steer

  -- Base steering force:
  local steerForce = steer
  
  local speedForce = speedForceBase * (((((math.abs(data.localVelocity.x)/3)) ^ 2)/10) + 1)
    
  -- FFB force:
  local ffbForce = -data.ffb * speedForce
  local ffbPositionMult = math.sign(steerAngle) == math.sign(ffbForce) and ffbPositionMultSameDirection or ffbPositionMultOppositeDirection
  ffbForce = ffbForce * math.lerp(1, ffbPositionMult, math.pow(math.abs(steerAngle), ffbPositionMultGamma))

  -- Resulting force is the sum of both:
  local force = steerForce + ffbForce
  
  -- Increasing forceFactor with Angular Velocity
  local forceFactor = forceFactorBase-- * (1 + (math.abs(data.localAngularVelocity.y)^0.5)/2)

  -- Reducing forceFactor with speed
  forceFactor = forceFactor / (1 + ((data.speedKmh / (60 + 100 * data.speedSensitivity)) ^ 1.5))

  -- Applying tonemapping-like correction to make sure force would not exceed 1
  force = force / (1 + math.abs(force))

  -- Force and velocity application with a bit of drag
  local steerAngleFade = steerAngleFadeBase + ((math.abs(newSteerStick))*0.0025) * (1 + ((math.abs(data.gForces.x)^1.5)/3)) * (1 + ((math.abs(data.localVelocity.x)/4)^2)/10)
  steerAngleFade = steerAngleFade + (0.004/(1 + (data.speedKmh / (30 + 40 * data.speedSensitivity)) ^ 2))
  steerAngleFade = (steerAngleFade / (1 + ((data.speedKmh / (60 + 80 * data.speedSensitivity)) ^ 0.3) / 700))
  if steerAngleFade > 0.998 then
	steerAngleFade = 0.998
  end
  steerVelocity = steerVelocity * steerAngleFade + forceFactor * force * dt
  steerAngle = steerAngle * steerAngleFade + steerVelocity * dt

  -- Very important part
  if steerAngle < -1 or steerAngle > 1 then
    steerVelocity = steerVelocity * steerVelocityBoundaryMult
  end  

  -- Writing new steer angle with a bit of smoothing just in case (completely ignoring original value)
  data.steer = math.clamp(steerAngle, -1, 1)

  -- Vibrations
  local baseForceLeft = ((math.ceil(data.ndSlipL * 10) ^ 0.3) - 1) * ((1 + data.ndSlipL) ^ 0.3) * data.rumbleEffects * 0.01
  local baseForceRight = ((math.ceil(data.ndSlipL * 10) ^ 0.3) - 1) * ((1 + data.ndSlipL) ^ 0.3) * data.rumbleEffects * 0.01
  data.vibrationLeft = baseForceLeft
  data.vibrationRight = baseForceRight  
  
  -- Debug:
  --ac.debug('localAngularVelocity.y', data.localAngularVelocity.y)
  --ac.debug('data.localSpeedX', data.localSpeedX) -- sideways speed of front axle relative to car
  --ac.debug('data.localVelocity.x', data.localVelocity.x) -- sideways speed of a car relative to car
  --ac.debug('data.localVelocity.z', data.localVelocity.z) -- forwards/backwards speed of a car relative to car
  --ac.debug('data.ndSlipL', data.ndSlipL) -- slipping for left front tyre
  --ac.debug('data.ndSlipR', data.ndSlipR)  -- slipping for right front tyre
  --ac.debug('speedForce', speedForce) 
  --ac.debug('forceFactor', forceFactor)
  --ac.debug('steerAngleFade', steerAngleFade)  
  --ac.debug('ffbForce', ffbForce)  
  --ac.debug('data.gForces.x', data.gForces.x)
end

return {
  name = 'Race',
  update = update, 
  sync = function (m) steerAngle, steerVelocity = m.export() end,
  export = function () return steerAngle, steerVelocity end,
}
