;----------------------------------------
; Mouse Steering program made by Zoom377 | 27/9/2015
;----------------------------------------
maxKeys := 32
keys := ["LButton","RButton", "S", "W", "Tab", "Delete", "XButton1", "XButton2", "MButton", "Shift", "Backspace"]

#Persistent
#SingleInstance, Force
#NoEnv
SetFormat, float, 0.20
SetBatchLines, -1
#Include Gdip.ahk
#Include CvJoyInterface.ahk
#Include AHKHID.ahk


Gui InputGUI:New, +LastFound +ToolWindow
Gui InputGUI:Show, NA

InputGUIHandle := WinExist()

AHKHID_UseConstants()

OnMessage(0x00FF, "InputMsg")

gosub Register

global vJoyInterface := new CvJoyInterface()

if(!vJoyInterface.vJoyEnabled()){
	MsgBox, % "Error: " . vJoyInterface.LoadLibraryLog
}
else
{
	TrayTip, Mouse Steering, vJoy found.
}

If !pToken := Gdip_Startup()
{
	MsgBox, w, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}

;- Quadratic curves:
;- ax^2 + bx + c
;- c is unnecessary as the curve must intercept 0 so:
;- ax^2 + bx

;-User defined variables
global sensitivity := "" ;The amount mouse movements affect joyStickX
global pushBack := "" ;The speed at which joyStickX is pushed to 0
global a := "" ;Nonlinearity for the joyStickX pushback

;-Program constants
global SETTINGS_FOLDER_PATH := A_MyDocuments . "\Mouse Steering"
global SETTINGS_PATH := A_MyDocuments . "\Mouse Steering\Settings.ini"

global SLIDER_MIN_SENSITIVITY := 1
global SLIDER_MAX_SENSITIVITY := 1500
global SLIDER_INTERVAL_SENSITIVITY := 0.1

global SLIDER_MIN_PUSHBACK := 0
global SLIDER_MAX_PUSHBACK := 100
global SLIDER_INTERVAL_PUSHBACK := 0.01

global SLIDER_MIN_NONLINEARITY := 100
global SLIDER_MAX_NONLINEARITY := 300
global SLIDER_INTERVAL_NONLINEARITY := 0.01

global MARKER_WIDTH := 15
global MARKER_WIDTH_WITH_BORDER := 15
global MARKER_HEIGHT := 30
global MARKER_HEIGHT_WITH_BORDER := 30


global MARKER_COLORS := [0xffff0000, 0xff00ff00, 0xff0000ff]

global MOUSE_RESET_INTERVAL := 500

global SCREEN_CENTER_X := A_ScreenWidth/2
global SCREEN_CENTER_Y := A_ScreenHeight/2

;-Program variables
global scale := 1
global previousMouseX := 0
global b := "" ;
global joyStickX := 0
global lastMouseReset := 0
global mouseHideEnabled := false
global markerEnabled := false
global markerColorIndex := 1

;-Setup
Menu, Tray, NoStandard
Menu, Tray, Add, Settings
Menu, Tray, Add, Exit
gosub LoadSettings
gosub CalculateScale



;-Gdip stuff!!!
; Get the dimensions of the primary monitor
SysGet, MonitorPrimary, MonitorPrimary
SysGet, WA, Monitor, %MonitorPrimary%
SysGet, screenPixelWidth, 16
WAWidth := WARight-WALeft
WAHeight := WABottom-WATop

; Create a layered window (+E0x80000) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
Gui, 2: +LastFound -Caption +E0x80000 +ToolWindow +OwnDialogs +AlwaysOnTop

; Show the window
Gui, 2: Show, NA

; Get a handle to this window we have created in order to update it later
global hwnd1 := WinExist()

WinSet, ExStyle, +0x20, ahk_id %hwnd1%

; Create a gdi bitmap with width and height of the work area
global hbm := CreateDIBSection(WAWidth, WAHeight)

; Get a device context compatible with the screen
global hdc := CreateCompatibleDC()

; Select the bitmap into the device context
global obm := SelectObject(hdc, hbm)

; Get a pointer to the graphics of the bitmap, for use with drawing functions
global G := Gdip_GraphicsFromHDC(hdc)

; Set the smoothing mode to antialias = 4 to make shapes appear smother (only used for vector drawing and filling)
Gdip_SetSmoothingMode(G, 4)



SetTimer, TimerTick, 15
return ;- Finish initialisation

TimerTick:
	
	difference := 16384 - joyStickX ;- Calculate difference between 16384 (desired) and joyStickX position
	;- ax^2 + bx
	;- a * difference^2 + b * difference	
	

	
	if (a >= 1 && a < 2)
	{
		if (difference >= 0) ;- If positive
		{
			quadraticOutput := (difference**a) ;- Quadratic stuff
			quadraticOutput *= pushBack * scale
		}
		else if (difference < 0) ;- If negative
		{
			difference *= -1
			quadraticOutput := -(difference**a) ;- Quadratic stuff
			quadraticOutput *= pushBack * scale
		}
	}
	else if (a >= 2 && a < 3)
	{
		if (difference >= 0) ;- If positive
		{
			quadraticOutput := (difference**a) ;- Quadratic stuff
			quadraticOutput *= pushBack * scale
		}
		else if (difference < 0) ;- If negative
		{
			difference *= -1
			quadraticOutput := -(difference**a) ;- Quadratic stuff
			quadraticOutput *= pushBack * scale
		}
	}
	else if (a >= 3)
	{
		if (difference >= 0) ;- If positive
		{
			quadraticOutput := (difference**a) ;- Quadratic stuff
			quadraticOutput *= pushBack * scale
		}
		else if (difference < 0) ;- If negative
		{
			quadraticOutput := (difference**a) ;- Quadratic stuff
			quadraticOutput *= pushBack * scale
		}
	}
	
	GetKeyState, state, RButton
	if (state = "U") ;- If right mouse button not held, push joystickX towards 0
	{
		joyStickX += quadraticOutput
	}
	;~ ToolTip, %joyStickX%, 10, 10
	
	if (joyStickX > 32767)
		joyStickX := 32767
	
	if (joyStickX < 0)
		joyStickX := 0	
	
	vJoyInterface.Devices[1].SetAxisByIndex(joyStickX, 1) ;- Set virtual joystick value	
	
	
	Button(key, id) {
		;MsgBox, %key%
		;MsgBox, %id%
		if (GetKeyState(key) = 1) {
			vJoyInterface.Devices[1].SetBtn(1, id)
		}
		else {
			vJoyInterface.Devices[1].SetBtn(0, id)
		}  
	}
	
	Loop, %maxKeys% {
		key := keys[A_Index]
		;MsgBox, %A_Index%
		;MsgBox, %key%
		Button(key,A_Index)		
	}

	
	xScale := screenPixelWidth / 32767
	markerXPos := (joystickX * xScale) - (MARKER_WIDTH/2)
	markerXPosWithBorder := (joystickX * xScale) - (MARKER_WIDTH_WITH_BORDER/2)
	
	Gdip_GraphicsClear(G)
	
	if (markerEnabled = true)
	{
		markerColorElement := MARKER_COLORS[markerColorIndex]
		pBrush := Gdip_BrushCreateSolid(markerColorElement)
		pBrushBlack := Gdip_BrushCreateSolid(0xff000000)

		Gdip_FillRectangle(G, pBrush, markerXPos, WAHeight-MARKER_HEIGHT - MARKER_WIDTH, MARKER_WIDTH, MARKER_HEIGHT)
		Gdip_FillRectangle(G, pBrushBlack, screenPixelWidth/2-MARKER_WIDTH/2, WAHeight - MARKER_HEIGHT_WITH_BORDER - MARKER_WIDTH, MARKER_WIDTH_WITH_BORDER, MARKER_HEIGHT_WITH_BORDER)
			
		Gdip_DeleteBrush(pBrush)
		Gdip_DeleteBrush(pBrushBlack)
	}
	; Update the specified window
	UpdateLayeredWindow(hwnd1, hdc, WALeft, WATop, WAWidth, WAHeight)	
return

PresentSettings:
	Gui, 1:Add, Text, x12 y10 w140 h20 +Center, Sensitivity
	Gui, 1:Add, Slider, vSliderSensitivity gSubSliderSensitivity x12 y30 w140 h30 ToolTip Range%SLIDER_MIN_SENSITIVITY%-%SLIDER_MAX_SENSITIVITY%, % sensitivity / SLIDER_INTERVAL_SENSITIVITY
	Gui, 1:Add, Text, vLabelSensitivity x152 y30 w50 h30 , % Format("{1:0.1f}", sensitivity)
	
	Gui, 1:Add, Text, x12 y70 w140 h20 +Center, Push back
	Gui, 1:Add, Slider, vSliderPushBack gSubSliderPushBack x12 y90 w140 h30 ToolTip Range%SLIDER_MIN_PUSHBACK%-%SLIDER_MAX_PUSHBACK%, % pushBack / SLIDER_INTERVAL_PUSHBACK
	Gui, 1:Add, Text, vLabelPushBack x152 y90 w70 h30 , % Format("{1:0.2f}", pushBack)
	
	Gui, 1:Add, Text, x12 y130 w140 h20 +Center, Non-linearity
	Gui, 1:Add, Slider, vSliderNonLinearity gSubSliderNonLinearity x12 y150 w140 h30 ToolTip Range%SLIDER_MIN_NONLINEARITY%-%SLIDER_MAX_NONLINEARITY%, % a / SLIDER_INTERVAL_NONLINEARITY
	Gui, 1:Add, Text, vLabelNonLinearity x152 y150 w50 h30 , % Format("{1:0.2f}", a)
	
	Gui, 1:Add, Button, gBtnSave x32 y190 w140 h30 , Save
	Gui, 1:Show, w205 h236, Settings
	WinWaitClose, Settings
return

SubSliderSensitivity:
	GuiControl, , LabelSensitivity, % Format("{1:0.1f}", SliderSensitivity * SLIDER_INTERVAL_SENSITIVITY)
return

SubSliderPushBack:
	GuiControl, , LabelPushBack, % Format("{1:0.2f}", SliderPushBack * SLIDER_INTERVAL_PUSHBACK)
return

SubSliderNonLinearity:
	GuiControl, , LabelNonLinearity, % Format("{1:0.2f}", SliderNonLinearity * SLIDER_INTERVAL_NONLINEARITY)
return

LoadSettings:
	IfExist, %SETTINGS_FOLDER_PATH%
	{
		IniRead, sensitivity, %SETTINGS_PATH%, UserVariables, key_sensitivity, 1
		IniRead, pushBack, %SETTINGS_PATH%, UserVariables, key_pushBack, 1
		IniRead, a, %SETTINGS_PATH%, UserVariables, key_a, 1
		b := 1 - a
		gosub CalculateScale
	}
	else
	{		
		FileCreateDir, %SETTINGS_FOLDER_PATH%
		FileAppend,, SETTINGS_PATH
		gosub PresentSettings
		gosub CalculateScale
	}
return

SaveSettings:
	IniWrite, %sensitivity%, %SETTINGS_PATH%, UserVariables, key_sensitivity
	IniWrite, %pushBack%, %SETTINGS_PATH%, UserVariables, key_pushBack
	IniWrite, %a%, %SETTINGS_PATH%, UserVariables, key_a
return

BtnSave:
	Gui, 1:Submit
	sensitivity := SliderSensitivity * SLIDER_INTERVAL_SENSITIVITY
	pushBack := SliderPushBack * SLIDER_INTERVAL_PUSHBACK
	a := SliderNonLinearity * SLIDER_INTERVAL_NONLINEARITY
	b := 1 - a
	Gui, 1:Destroy
	gosub SaveSettings
	gosub CalculateScale
return

Settings:
	gosub PresentSettings
return

Exit:
	ExitApp
return

OnExit:
	; Select the object back into the hdc
	SelectObject(hdc, obm)
	; Now the bitmap may be deleted
	DeleteObject(hbm)
	; Also the device context related to the bitmap may be deleted
	DeleteDC(hdc)
	; The graphics may now be deleted
	Gdip_DeleteGraphics(G)
	; ...and gdi+ may now be shutdown
	Gdip_Shutdown(pToken)	
	
	gosub SaveSettings
return

StopTimer:
	SetTimer, TimerTick, Off
return

StartTimer:
	SetTimer, TimerTick, 15
return

GuiEscape:
GuiClose:
ButtonCancel:
	Gui, 1:Destroy
return


InputMsg(wParam, lParam) {
	Local xRawDelta, yRawDelta
    Critical
    
    xRawDelta += AHKHID_GetInputInfo(lParam, II_MSE_LASTX) + 0.0
    yRawDelta += AHKHID_GetInputInfo(lParam, II_MSE_LASTY) + 0.0
	
	joystickX += xRawDelta * sensitivity
}

Register:
    AHKHID_Register(1,2,InputGUIHandle, 0x00000100)
Return


CalculateScale:
	scale := 32767 / (32767**a)
return

ToggleFakeFullscreen()
{
	CoordMode Screen, Window
	static WINDOW_STYLE_UNDECORATED := -0xC40000
	static savedInfo := Object() ;; Associative array!
	WinGet, id, ID, A
	if (savedInfo[id])
	{
		inf := savedInfo[id]
		WinSet, Style, % inf["style"], ahk_id %id%
		WinMove, ahk_id %id%,, % inf["x"], % inf["y"], % inf["width"], % inf["height"]
		savedInfo[id] := ""
	}
	else
	{
		savedInfo[id] := inf := Object()
		WinGet, ltmp, Style, A
		inf["style"] := ltmp
		WinGetPos, ltmpX, ltmpY, ltmpWidth, ltmpHeight, ahk_id %id%
		inf["x"] := ltmpX
		inf["y"] := ltmpY
		inf["width"] := ltmpWidth
		inf["height"] := ltmpHeight
		WinSet, Style, %WINDOW_STYLE_UNDECORATED%, ahk_id %id%
		mon := GetMonitorActiveWindow()
		SysGet, mon, Monitor, %mon%
		WinMove, A,, %monLeft%, %monTop%, % monRight-monLeft, % monBottom-monTop
	}
}

GetMonitorAtPos(x,y)
{
	;; Monitor number at position x,y or -1 if x,y outside monitors.
	SysGet monitorCount, MonitorCount
	i := 0
	while(i < monitorCount)
	{
		SysGet area, Monitor, %i%
		if ( areaLeft <= x && x <= areaRight && areaTop <= y && y <= areaBottom )
		{
			return i
		}
		i := i+1
	}
	return -1
}

GetMonitorActiveWindow(){
	;; Get Monitor number at the center position of the Active window.
	WinGetPos x,y,width,height, A
	return GetMonitorAtPos(x+width/2, y+height/2)
}

^F7::
	markerColorIndex++
	if (markerColorIndex > MARKER_COLORS.Length())
	{
		markerColorIndex -= MARKER_COLORS.Length()
	}
return

^F8::
	mouseHideEnabled := !mouseHideEnabled
	if (mouseHideEnabled)
	{
		MouseMove, 9999, A_ScreenHeight/2, 0
		BlockInput, MouseMove
	}
	else
	{
		BlockInput, MouseMoveOff
	}	
return

^F9::ToggleFakeFullscreen()
^F10::joyStickX := 16384
^F11::
	markerEnabled := !markerEnabled
	if (markerEnabled = true)
	{
		WinSet, Top, , ahk_id %hwnd1%
		WinSet, AlwaysOnTop, On, ahk_id %hwnd1%
	}
return

^F12::ExitApp