# Assetto Corsa (Gamepad) Alt(ernative) Steer Control

## What is this?
As the name of this repo/script says, this is an alternate control scheme that implements "rotation" for steering in the racing game Assetto Corsa with a gamepad/controller making use of its joystick.
Keep in mind that the script, currently as it is, is still very immature and lacking many QoL features like customization, interaction with the force feedback system in game, vibration, etc. The script is also not very resource efficient.

## Reason for this?
Normally the wheel is turned directly proportional to the displacement of the X-axis of the joystick on the gamepad (or likewise). This had caused inconvenience to me as a steering position cannot be kept long accurately without paying a lot of effort.

## What does this do?
This script, once installed properly, remaps the x and y axes of the driving stick to steering with the logic as follow:

 - The closer the position of the stick is to the edge, the greater the steering.
 - The angle of rotation required from the origin to reach the position of the stick from the position of upright clockwise is proportional to steering.

The second point may be hard to understand due to my inability to describe it, but I would call it rotating the stick. Think of it like the virtual steering wheel on some of the driving games on mobile platforms where you drag the icon in a circular motion to turn the vehicle. A good way to approach this scheme is to just keep the stick on the edge upright, then if you want to turn left just move the stick left and down along the edge. The more you move along the edge the more the steering.

There is also a zone that is on the bottom I set that will have the maximum steering from the "rotation". The angle of the zone is 0.2pi. This can be changed by changing the steeringRange local variable in the script. The higher this value the smaller the zone mentioned before.

## Installation
### Requirement
This script requires Assetto Corsa with Custom Shader Patch version >=1.77 ( I tested the script with CSP 1.78) and use the Content Manager to set some settings. (I am not sure if there is a way to do without Content Manager)
### Installation Process
Simply download the extension folder in the repository and place it at the root of your game (where AssettoCorsa.exe is located, there should be a folder called extension as well). Select to merge the folder if asked.

However if it asks for any file to be replaced when you have **never installed this script before**, do not. Recheck if your operation is correct and redo, if the same thing persists, inform me on GitHub with a Issue ticket. Keep in mind this only applies when you never installed this script before, else just replace and go on.

Lastly, open the Content Manager and head to Settings>CUSTOM SHADERS PATCH and on the left find GAMEPAD FX. Click on it and then tick the checkbox that says Active under Basics. On the right of the checkbox there should be a dropdown menu. Use it to select Alt Steer Control. Then you can just play the game and the script should come into action.

(The script needs you to already have a control scheme in place that make use of the joystick only for steering)

## Misc
You many notice there is another script that has the word Limited at the end. It is just that I tried to add a limit on how fast you can turn the steering wheel as with the normal script it is possible to overcome the laws of physic and pretty much kill the tires by flicking the joystick. However the value of the limit is never tested and may not even be sensible. You can always use that script and change the value yourself though.

This project is very rushed, you may even see it as a proof of concept. I actually had this concept a long time ago, but it is until hours ago that I realize I could make it into a thing with AC CSP scripts (I was watching Initial D so I picked up this game again btw). I may never update the project ever again but I would try to help whoever encounters a problem related.

In the early thinking process I actually imagined a multi turn system where just like steering wheels you can rotate the stick in one direction multiple revolution to have a higher steering angle. But then I thought this would cause confusion and a hassle to implement I did not made it.