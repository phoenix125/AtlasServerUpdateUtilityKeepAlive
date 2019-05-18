#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\phoenix_lightfaded.ico
#AutoIt3Wrapper_Outfile=Builds\AtlasServerUpdateUtilityKeepAlive_v1.1.exe
#AutoIt3Wrapper_Outfile_x64=Builds\AtlasServerUpdateUtilityKeepAlive_v1.1(x64).exe
#AutoIt3Wrapper_Res_Comment=By Phoenix125
#AutoIt3Wrapper_Res_Description=AtlasServerUpdateUtilityKeepAlive_v1.1
#AutoIt3Wrapper_Res_Fileversion=1.1.0.0
#AutoIt3Wrapper_Res_ProductName=AtlasServerUpdateUtilityKeepAlive_v1.1
#AutoIt3Wrapper_Res_ProductVersion=v1.1.0
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
;~ #include <Array.au3>
;~ #include <File.au3>

#Region ; Tray
Opt("TrayMenuMode", 3)     ; The default tray menu items will not be shown and items are not checked when selected. These are options 1 and 2 for TrayMenuMode.
Opt("TrayOnEventMode", 1)     ; Enable TrayOnEventMode.
Global $aPauseUtil = False
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
	$aPauseUtil = True
	TrayItemSetState($iTrayUpdateUtilPause, $TRAY_DISABLE)
	TrayItemSetState($iTrayUpdateUtilResume, $TRAY_ENABLE)
EndFunc   ;==>Tray_PauseUtil
Func Tray_ResumeUtil()
	$aPauseUtil = False
	TrayItemSetState($iTrayUpdateUtilPause, $TRAY_ENABLE)
	TrayItemSetState($iTrayUpdateUtilResume, $TRAY_DISABLE)
EndFunc   ;==>Tray_ResumeUtil
Func Tray_Exit()
	Exit
EndFunc   ;==>Tray_Exit
#EndRegion ; Tray

Global $aUtilName = "AtlasServerUpdateUtilityKeepAlive"
Global $aGameName = "Atlas"
Global $aUtilityVer = "v1.0.0"
Global $aIniFile = @ScriptDir & "\" & $aUtilName & ".ini"
Global $aFolderTemp = @ScriptDir & "\" & $aGameName & "UtilFiles\"
Global $aFolderLog = @ScriptDir & "\_Log\"
Global $aLogFile = $aFolderLog & $aUtilName & ".log"
Global $aPID = 0

; INI Variables
Global $iHeaderMain = " --------------- " & StringUpper($aUtilName) & " --------------- "
Global $iProgramToKeepAlive = "Program to Keep Alive ###"
Global $iProgramToRun = "Program to run ###"
Global $iRedisKeepAliveYN = "Keep your redis server alive? (Monitors for process redis-server.exe: NO to disable or let AtlasServerUpdateUtility manage redis)(yes/no) ###"
Global $iRedisKeepAliveEXE = "Redis filename/folder (ignored if answer is NO above) ###"
Global $iShowStatusWindowYN = "Show status window? (yes/no) ###"
Global $iStartMinimizedYN = "Start Program minimized? (yes/no) ###"
Global $iCloseUtilYN = "System use: Close " & $aUtilName & "? (Checked prior to restarting above Program... used when purposely shutting down above Program)(yes/no) ###"
Global $iCompiledYN = "System use: Is program compiled? (yes/no) ###"
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
Sleep(5000)
If $aCompiledYN = "no" Then
	$tPID = WinGetProcess("[CLASS:AutoIt v3 GUI]", "AtlasServerUpdateUtility v")
	MsgBox(0, $aUtilName, "Not compiled: PID[" & $tPID & "]", 5)
EndIf
Do
	If Not $aPauseUtil Then
		$aCloseUtilYN = IniRead($aIniFile, $iHeaderMain, $iCloseUtilYN, "")
		If Not ProcessExists($aPID) And $aCloseUtilYN = "no" Then
			If $aCompiledYN = "no" Then
				$aPID = WinGetProcess("[CLASS:AutoIt v3 GUI]", "AtlasServerUpdateUtility v")
				If $aPID < 1 Then
					RunWait("\AtlasServerUpdateUtilityKeepAlive.bat")
				EndIf
			Else
				$aPID = ProcessExists($aProgramToKeepAlive)
				If $aPID < 1 Then
					If $aStartMinimizedYN = "no" Then
						$aPID = Run($aProgramToRun, @ScriptDir)
					Else
						$aPID = Run($aProgramToRun, @ScriptDir, @SW_MINIMIZE)
					EndIf
				EndIf
				LogWrite($aProgramToKeepAlive & " PID(" & $aPID & ") started.")
				Sleep(5000)
			EndIf
		EndIf
		If $aRedisKeepAliveYN = "yes" And $aCloseUtilYN = "no" Then
			If Not ProcessExists("redis-server.exe") Then
				$aRedisPID = Run($aRedisKeepAliveEXE)
				LogWrite("Redis started. PID(" & $aRedisPID & ") " & $aRedisKeepAliveEXE)
			EndIf
		EndIf
	EndIf
	Sleep(1000)
Until $aCloseUtilYN = "yes"

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
EndFunc   ;==>UpdateIni

Func LogWrite($Msg)
	FileWriteLine($aLogFile, _NowCalc() & " " & $Msg)
EndFunc   ;==>LogWrite


