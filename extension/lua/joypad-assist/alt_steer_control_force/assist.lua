local modes = {
  require('modes/race'),
  require('modes/drift')
}

local currentMode = modes[tonumber(ac.storage.mode)] or modes[1]
local wasPressed = false
local switchButton = ac.INIConfig.cspModule(ac.CSPModuleID.JoypadAssist):get('TWEAKS', 'MODE_SWITCH_BUTTON', ac.GamepadButton.Y)

function script.update(dt)
  currentMode.update(dt)

  if ac.isGamepadButtonPressed(math.floor(__gamepadIndex), switchButton) ~= wasPressed then
    wasPressed = not wasPressed
    if wasPressed then
      local newModeIndex = table.indexOf(modes, currentMode) % #modes + 1
      ac.storage.mode = newModeIndex
      local newMode = modes[newModeIndex]
      newMode.sync(currentMode)
      currentMode = newMode
      ac.setSystemMessage('Gamepad mode', 'Switched to '..currentMode.name)
    end
  end
end

