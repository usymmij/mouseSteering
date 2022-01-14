# Mouse Steering for Driving Games

## Credits
Adapted from this steam community post by Zoom377

https://steamcommunity.com/app/310560/discussions/0/517142892065610935/

Also added the cursor script from 

https://www.autohotkey.com/boards/viewtopic.php?f=6&t=37781

also relies on the following scripts
[vJoy by Shaul](https://sourceforge.net/projects/vjoystick/)
[evilC's CvJoyInterface](https://github.com/evilC/AHK-CvJoyInterface)
[Gdip by tic](https://www.autohotkey.com/board/topic/29449-gdi-standard-library-145-by-tic/)
[AHKHID by TheGood](https://www.autohotkey.com/board/topic/38015-ahkhid-an-ahk-implementation-of-the-hid-functions/)
[Borderless window code by Klaus2](https://www.autohotkey.com/board/topic/114598-borderless-windowed-mode-forced-fullscreen-script-toggle/)

Made for Forza 5, but should work on any VJoy compatible game

## Changes
The following changes were made from the original script for Dirt Rally by Zoom 377
- button adding from the list of keys in keys[] (line 6), making user included buttons easier
- System level cursor hiding rather than pushing it off the page
- changed the look of the display for wheel position
- Made the wheel start from center on startup, and not skip to the right when hiding the mouse

## PREREQUISITES

You need a recent release of VJoy to use this
https://sourceforge.net/projects/vjoystick/

## Editing and adding Buttons

There are 8 buttons by default in VJoy

Make sure you change it using the Configure Vjoy App by increasing the Number of Buttons

You can add keys by adding to the keys list in the MouseSteering.ahk script (Line 6)

To increase the maximum number of keys change maxKeys and the button number in VJoy

## HotKeys
same as original, but some functions have been changed

- *Ctrl+F7*: pointer colour 
	- wont stay after exit
	- for permanent change, change the first entry of MARKER_COLORS in line 5
- *Ctrl+F8*: toggle hide cursor
- *Ctrl+F9*: toggle borderless window
- *Ctrl+F10*: set joystick to neutral
- *Ctrl+F11*: toggle the wheel position marker
- *Ctrl+F12*: exit