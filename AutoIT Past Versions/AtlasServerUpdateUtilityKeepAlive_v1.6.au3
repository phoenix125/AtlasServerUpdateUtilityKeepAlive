#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\phoenix_lightfaded.ico
#AutoIt3Wrapper_Outfile=Builds\AtlasServerUpdateUtilityKeepAlive_v1.6.exe
#AutoIt3Wrapper_Outfile_x64=Builds\AtlasServerUpdateUtilityKeepAlive_v1.6(x64).exe
#AutoIt3Wrapper_Res_Comment=By Phoenix125
#AutoIt3Wrapper_Res_Description=AtlasServerUpdateUtilityKeepAlive_v1.6
#AutoIt3Wrapper_Res_Fileversion=1.6.0.0
#AutoIt3Wrapper_Res_ProductName=AtlasServerUpdateUtilityKeepAlive_v1.6
#AutoIt3Wrapper_Res_ProductVersion=v1.6.0
#AutoIt3Wrapper_Res_CompanyName=http://www.Phoenix125.com
#AutoIt3Wrapper_Res_LegalCopyright=http://www.Phoenix125.com
#AutoIt3Wrapper_Run_AU3Check=n
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Date.au3>
#include <String.au3>
#include <TrayConstants.au3>; Required For the $TRAY_ICONSTATE_SHOW constant.

Global $aUtilName = "AtlasServerUpdateUtilityKeepAlive"
Global $aGameName = "Atlas"
Global $aUtilityVer = "v1.6.0"
Global $aIniFile = @ScriptDir & "\" & $aUtilName & ".ini"
Global $aFolderTemp = @ScriptDir & "\" & $aGameName & "UtilFiles\"
Global $aFolderLog = @ScriptDir & "\_Log\"
Global $aLogFile = $aFolderLog & $aUtilName & ".log"
Global $aPID = 0

Global $iHeaderMain = " --------------- " & StringUpper($aUtilName) & " --------------- "
Global $iProgramToKeepAlive = "Program to Keep Alive ###"
Global $iProgramToRun = "Program to run ###"
Global $iRedisKeepAliveYN = "Keep your redis server alive? (Monitors for process redis-server.exe: NO to disable or let AtlasServerUpdateUtility manage redis)(yes/no) ###"
Global $iRedisKeepAliveEXE = "Redis filename/folder (ignored if answer is NO above) ###"
Global $iShowStatusWindowYN = "Show status window? (yes/no) ###"
Global $iStartMinimizedYN = "Start Program minimized? (yes/no) ###"
Global $iCloseUtilYN = "System use: Close " & $aUtilName & "? (Checked prior to restarting above Program... used when purposely shutting down above Program)(yes/no) ###"
Global $iCompiledYN = "System use: Is program compiled? (yes/no) ###"
Global $iKeepAliveTimeout = "System use: Max hang time before restarting program? (90-600) ###"
Global $iProgramPausedYN = "System use: Is program paused? (yes/no) ###"
Global $iKeepAlivePausedYN = "System use: Is KeepAlive paused? (yes/no) ###"

#Region ; Tray
If @Compiled Then
	Local $tHwd = WinWait("[REGEXPTITLE:AtlasServerUpdateUtilityKeepAlive_v[0-9]\.[0-9]]", "", 2)
	Local $tPID = WinGetProcess($tHwd)
	If $tPID > 0 Then
		SplashTextOn($aUtilName, "Another instance of " & @CRLF & $aUtilName & " is already running.", 500, 100, -1, -1, $DLG_MOVEABLE, "")
		Sleep(2000)
		Exit
	EndIf
EndIf
Opt("TrayMenuMode", 3)     ; The default tray menu items will not be shown and items are not checked when selected. These are options 1 and 2 for TrayMenuMode.
Opt("TrayOnEventMode", 1)     ; Enable TrayOnEventMode.
Global $aPauseUtil = False
Global $iTrayLastUpdated = TrayCreateItem("Last Online Update Time: [Waiting 2 minutes]")
Global $iTraySecSinceLastUpdated = TrayCreateItem("Last Online Update Secs:")
Global $iTrayProgramStatus = TrayCreateItem("Program Status:")
TrayCreateItem("")     ; Create a separator line.
Local $iTrayUpdateUtilPause = TrayCreateItem("Pause AtlasUtilKeepAlive")
TrayItemSetOnEvent(-1, "Tray_PauseUtil")
Local $iTrayUpdateUtilResume = TrayCreateItem("Resume AtlasUtilKeepAlive")
TrayItemSetOnEvent(-1, "Tray_ResumeUtil")
TrayCreateItem("")     ; Create a separator line.
Local $iTrayExitCloseY = TrayCreateItem("Exit AtlasUtilKeepAlive")
TrayItemSetOnEvent(-1, "Tray_Exit")
TrayItemSetState($iTrayUpdateUtilPause, $TRAY_ENABLE)
TrayItemSetState($iTrayUpdateUtilResume, $TRAY_DISABLE)
Func Tray_PauseUtil()
	IniWrite($aIniFile, $iHeaderMain, $iKeepAlivePausedYN, "yes")
	$aPauseUtil = True
	TrayItemSetState($iTrayUpdateUtilPause, $TRAY_DISABLE)
	TrayItemSetState($iTrayUpdateUtilResume, $TRAY_ENABLE)
EndFunc   ;==>Tray_PauseUtil
Func Tray_ResumeUtil()
	IniWrite($aIniFile, $iHeaderMain, $iKeepAlivePausedYN, "no")
	TrayItemSetState($iTrayUpdateUtilPause, $TRAY_ENABLE)
	TrayItemSetState($iTrayUpdateUtilResume, $TRAY_DISABLE)
EndFunc   ;==>Tray_ResumeUtil
Func Tray_Exit()
	Exit
EndFunc   ;==>Tray_Exit
#EndRegion ; Tray

Local $tDate, $tTime

; INI Variables
LogWrite("---------------- " & $aUtilName & " Started ----------------")
LogWrite("Reading Ini file.")
ReadUini()
Global $aStartText = "Starting " & $aGameName & @CRLF & @CRLF
If $aShowStatusWindowYN = "yes" Then Global $aSplashStartUp = SplashTextOn($aUtilName, $aStartText, 475, 140, -1, -1, $DLG_MOVEABLE, "")
If $aRedisKeepAliveYN = "yes" Then
	If ProcessExists("redis-server.exe") Then LogWrite("Redis-server.exe found.")
EndIf
If $aShowStatusWindowYN = "yes" Then
	ControlSetText($aSplashStartUp, "", "Static1", $aStartText & $aProgramToKeepAlive & " started.")
	Sleep(3000)
	SplashOff()
EndIf
Local $aStopLoop = False
For $i = 0 To 120
	$aCloseUtilYN = IniRead($aIniFile, $iHeaderMain, $iCloseUtilYN, "")
	If $aCloseUtilYN = "yes" Then Exit
	TrayItemSetText($iTrayLastUpdated, "Last Online Update Time: [Waiting " & 120 - $i & " more seconds]")
	Sleep(1000)
Next
Func GetPID()
	Local $tHwd = WinWait("[REGEXPTITLE:AtlasServerUpdateUtility v[0-9]\.[0-9]\.[0-9]]", "", 2)
	Local $tPID = WinGetProcess($tHwd)
	Return $tPID
EndFunc   ;==>GetPID
Do
	$aCloseUtilYN = IniRead($aIniFile, $iHeaderMain, $iCloseUtilYN, "")
	$aKeepAlivePausedYN = IniRead($aIniFile, $iHeaderMain, $iKeepAlivePausedYN, "no")
	If $aKeepAlivePausedYN = "no" Then
		$aProgramPausedYN = IniRead($aIniFile, $iHeaderMain, $iProgramPausedYN, "no")
		If $aProgramPausedYN = "no" Then
			TrayItemSetText($iTrayProgramStatus, "Program Status: Running")
			$aPauseUtil = False
		Else
			TrayItemSetText($iTrayLastUpdated, "Last Online Update Time: Paused")
			TrayItemSetText($iTraySecSinceLastUpdated, "Last Online Update Secs: Paused")
			TrayItemSetText($iTrayProgramStatus, "Program Status: Paused")
			$aPauseUtil = True
		EndIf
		If Not $aPauseUtil Then
			$tLastAliveTime = IniRead(@ScriptDir & "\AtlasUtilFiles\AtlasServerUpdateUtility_cfg.ini", "CFG", "aCFGKeepUtilAliveTime", _NowCalc())
			_DateTimeSplit($tLastAliveTime, $tDate, $tTime)
			If $tTime[2] < 10 Then $tTime[2] = "0" & $tTime[2]
			If $tTime[3] < 10 Then $tTime[3] = "0" & $tTime[3]
			TrayItemSetText($iTrayLastUpdated, "Last Online Update Time: " & $tTime[1] & ":" & $tTime[2] & ":" & $tTime[3])
			Local $tTimeSinceLastAlive = _DateDiff('s', $tLastAliveTime, _NowCalc())
			TrayItemSetText($iTraySecSinceLastUpdated, "Last Online Update Secs: " & Int($tTimeSinceLastAlive))
			$aPID = GetPID()
			If $tTimeSinceLastAlive >= $aKeepAliveTimeout And ($aCloseUtilYN = "no") Then
				If ProcessExists($aPID) Then ProcessClose($aPID)
				TrayItemSetText($iTrayProgramStatus, "Program Status: Not Responsive")
				SplashTextOn($aUtilName, "WARNING! " & @CRLF & GetFileFromFullPath($aProgramToRun) & @CRLF & " unresponsive or closed unexpectedly. Restarting program.", 600, 140, -1, -1, $DLG_MOVEABLE, "")
				Sleep(5000)
				If $aStartMinimizedYN = "no" Then
					$aPID = Run($aProgramToRun, @ScriptDir)
				Else
					$aPID = Run($aProgramToRun, @ScriptDir, @SW_MINIMIZE)
				EndIf
				Sleep(120000)
				SplashOff()
			EndIf
			If $aPID < 1 And $aCloseUtilYN = "no" Then
				TrayItemSetText($iTrayProgramStatus, "Program Status: CRASHED")
				LogWrite("WARNING! " & $aProgramToRun & " closed unexpectedly. Restarting program.")
				If $aStartMinimizedYN = "no" Then
					$aPID = Run($aProgramToRun, @ScriptDir)
				Else
					$aPID = Run($aProgramToRun, @ScriptDir, @SW_MINIMIZE)
				EndIf
				LogWrite($aProgramToKeepAlive & " PID(" & $aPID & ") started.")
				Sleep(120000)
				SplashOff()
			EndIf
			If $aRedisKeepAliveYN = "yes" And $aCloseUtilYN = "no" Then
				If Not ProcessExists("redis-server.exe") Then
					$aRedisPID = Run($aRedisKeepAliveEXE)
					LogWrite("WARNING! Redis closed unexpectedly. Redis started. PID(" & $aRedisPID & ") " & $aRedisKeepAliveEXE)
					SplashTextOn($aUtilName, "WARNING! Redis closed unexpectedly. Redis started. PID(" & $aRedisPID & ") " & $aRedisKeepAliveEXE, 475, 140, -1, -1, $DLG_MOVEABLE, "")
					Sleep(30000)
					SplashOff()
				EndIf
			EndIf
		EndIf
		Sleep(1000)
		If $aCloseUtilYN = "yes" Then Exit
	Else
		TrayItemSetText($iTrayLastUpdated, "Last Online Update Time: KeepAlive Paused")
		TrayItemSetText($iTraySecSinceLastUpdated, "Last Online Update Secs: KeepAlivePaused")
		TrayItemSetText($iTrayProgramStatus, "Program Status: KeepAlive Paused")
		Sleep(1000)
	EndIf
Until $aCloseUtilYN = "yes"
Exit

Func ReadUini()
	Global $iIniError = ""
	Global $iIniFail = 0
	$iIniRead = True
	Local $iniCheck = ""
	Local $aChar[3]
	For $i = 1 To 13
		$aChar[0] = Chr(Random(97, 122, 1))     ;a-z
		$aChar[1] = Chr(Random(48, 57, 1))     ;0-9
		$iniCheck &= $aChar[Random(0, 1, 1)]
	Next
	Global $aProgramToKeepAlive = IniRead($aIniFile, $iHeaderMain, $iProgramToKeepAlive, $iniCheck)
	Global $aProgramToRun = IniRead($aIniFile, $iHeaderMain, $iProgramToRun, $iniCheck)
	Global $aRedisKeepAliveYN = IniRead($aIniFile, $iHeaderMain, $iRedisKeepAliveYN, $iniCheck)
	Global $aRedisKeepAliveEXE = IniRead($aIniFile, $iHeaderMain, $iRedisKeepAliveEXE, $iniCheck)
	Global $aShowStatusWindowYN = IniRead($aIniFile, $iHeaderMain, $iShowStatusWindowYN, $iniCheck)
	Global $aStartMinimizedYN = IniRead($aIniFile, $iHeaderMain, $iStartMinimizedYN, $iniCheck)
	Global $aCloseUtilYN = IniRead($aIniFile, $iHeaderMain, $iCloseUtilYN, $iniCheck)
	Global $aCompiledYN = IniRead($aIniFile, $iHeaderMain, $iCompiledYN, $iniCheck)
	Global $aKeepAliveTimeout = IniRead($aIniFile, $iHeaderMain, $iKeepAliveTimeout, $iniCheck)
	Global $aProgramPausedYN = IniRead($aIniFile, $iHeaderMain, $iProgramPausedYN, $iniCheck)
	Global $aKeepAlivePausedYN = IniRead($aIniFile, $iHeaderMain, $iKeepAlivePausedYN, $iniCheck)
	If $iniCheck = $aProgramToKeepAlive Then
		$aProgramToKeepAlive = "AtlasServerUpdateUtility.exe"
		$iIniFail += 1
		$iIniError = $iIniError & "ProgramToKeepAlive, "
	EndIf
	If $iniCheck = $aProgramToRun Then
		$aProgramToRun = @ScriptDir & "\_start_AtlasServerUpdateUtility.bat"
		$iIniFail += 1
		$iIniError = $iIniError & "ProgramToRun, "
	EndIf
	If $iniCheck = $aRedisKeepAliveEXE Then
		$aRedisKeepAliveEXE = @ScriptDir & "\redis-server.exe"
		$iIniFail += 1
		$iIniError = $iIniError & "RedisKeepAliveEXE, "
	EndIf
	If $iniCheck = $aRedisKeepAliveYN Then
		$aRedisKeepAliveYN = "no"
		$iIniFail += 1
		$iIniError = $iIniError & "ShowStatusWindowYN, "
	EndIf
	If $iniCheck = $aShowStatusWindowYN Then
		$aShowStatusWindowYN = "no"
		$iIniFail += 1
		$iIniError = $iIniError & "ShowStatusWindowYN, "
	EndIf
	If $iniCheck = $aStartMinimizedYN Then
		$aStartMinimizedYN = "no"
		$iIniFail += 1
		$iIniError = $iIniError & "StartMinimizedYN, "
	EndIf
	If $iniCheck = $aCloseUtilYN Then
		$aCloseUtilYN = "yes"
		$iIniFail += 1
		$iIniError = $iIniError & "CloseUtil, "
	EndIf
	If $iniCheck = $aCompiledYN Then
		$aCompiledYN = "yes"
		$iIniFail += 1
		$iIniError = $iIniError & "Compiled, "
	EndIf
	If $iniCheck = $aKeepAliveTimeout Then
		$aKeepAliveTimeout = 180
		$iIniFail += 1
		$iIniError = $iIniError & "KeepAliveTimout, "
	EndIf
	If $aKeepAliveTimeout < 90 Then $aKeepAliveTimeout = 90
	If $aKeepAliveTimeout > 600 Then $aKeepAliveTimeout = 600
	If $iniCheck = $aProgramPausedYN Then
		$aProgramPausedYN = "no"
		$iIniFail += 1
		$iIniError = $iIniError & "ProgramPaused, "
	EndIf
	If $iniCheck = $aKeepAlivePausedYN Then
		$aProgramPausedYN = "no"
		$iIniFail += 1
		$iIniError = $iIniError & "KeepAlivePaused, "
	EndIf
	If $iIniFail > 0 Then
		UpdateIni()
	EndIf
EndFunc   ;==>ReadUini

Func UpdateIni()
	If FileExists($aIniFile) Then FileDelete($aIniFile)
	FileWriteLine($aIniFile, "[ --------------- " & StringUpper($aUtilName) & " INFORMATION --------------- ]")
	FileWriteLine($aIniFile, "Author   :  Phoenix125")
	FileWriteLine($aIniFile, "Version  :  " & $aUtilityVer)
	FileWriteLine($aIniFile, "Website  :  http://www.Phoenix125.com")
	FileWriteLine($aIniFile, "Discord  :  http://discord.gg/EU7pzPs")
	FileWriteLine($aIniFile, "Forum    :  https://phoenix125.createaforum.com/index.php")
	FileWriteLine($aIniFile, @CRLF)
	FileWriteLine($aIniFile, "[" & $iHeaderMain & "]")
	IniWrite($aIniFile, $iHeaderMain, $iProgramToKeepAlive, $aProgramToKeepAlive)
	IniWrite($aIniFile, $iHeaderMain, $iProgramToRun, $aProgramToRun)
	IniWrite($aIniFile, $iHeaderMain, $iRedisKeepAliveYN, $aRedisKeepAliveYN)
	IniWrite($aIniFile, $iHeaderMain, $iRedisKeepAliveEXE, $aRedisKeepAliveEXE)
	IniWrite($aIniFile, $iHeaderMain, $iShowStatusWindowYN, $aShowStatusWindowYN)
	IniWrite($aIniFile, $iHeaderMain, $iStartMinimizedYN, $aStartMinimizedYN)
	IniWrite($aIniFile, $iHeaderMain, $iCloseUtilYN, $aCloseUtilYN)
	IniWrite($aIniFile, $iHeaderMain, $iCompiledYN, $aCompiledYN)
	IniWrite($aIniFile, $iHeaderMain, $iKeepAliveTimeout, $aKeepAliveTimeout)
	IniWrite($aIniFile, $iHeaderMain, $iProgramPausedYN, $aProgramPausedYN)
	IniWrite($aIniFile, $iHeaderMain, $iKeepAlivePausedYN, $aKeepAlivePausedYN)
EndFunc   ;==>UpdateIni

Func LogWrite($Msg)
	FileWriteLine($aLogFile, _NowCalc() & " " & $Msg)
EndFunc   ;==>LogWrite
Func GetFileFromFullPath($tFile)
	For $tC = 1 To StringLen($tFile)
		Local $tTxt = StringRight($tFile, $tC)
		If StringInStr($tTxt, "\") = 0 Then
		Else
;~ 			$tFolderOnly = StringTrimRight($tFile, $tC)
			$tTxt = StringTrimLeft($tTxt, 1)
			ExitLoop
		EndIf
	Next
	If StringRight($tTxt, 1) = '"' Then $tTxt = StringTrimRight($tTxt, 1)
	If StringLen($tFile) = $tC Then Return "ERROR-No \ found"
	Return $tTxt
EndFunc   ;==>GetFileFromFullPath


