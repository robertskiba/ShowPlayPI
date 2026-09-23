#pragma compile(Icon, ShowPlayPI-Configurator.ico)
#pragma compile(ProductName, ShowPlayPI Configurator)
#pragma compile(FileDescription, ShowPlayPI Configurator)
#pragma compile(ProductVersion, 1.0.0-beta.1)
#pragma compile(FileVersion, 1.0.0.0)
#pragma compile(OriginalFilename, ShowPlayPI-Configurator.exe)

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <MsgBoxConstants.au3>

Opt("MustDeclareVars", 1)

Global Const $g_sIniPath = @ScriptDir & "\showplaypi.ini"
; About page values: change these for future releases.
Global Const $g_sAppVersion = "1.0.0-beta.1"
Global Const $g_sDownloadUrl = "https://konftools.com"
Global Const $g_sSupportEmail = "support@konftools.com"

If Not FileExists($g_sIniPath) Then
    If Not _CreateDefaultIni() Then
        MsgBox($MB_ICONERROR, "ShowPlayPI Configurator", _
            "showplaypi.ini is missing and a new configuration file could not be created." & @CRLF & @CRLF & _
            "Make sure the application directory is writable:" & @CRLF & @ScriptDir)
        Exit 1
    EndIf

    MsgBox($MB_ICONINFORMATION, "ShowPlayPI Configurator", _
        "showplaypi.ini was missing." & @CRLF & @CRLF & _
        "A new configuration file with default values has been created.")
EndIf

Global $g_hGui = GUICreate("ShowPlayPI Configurator", 700, 610, -1, -1, _
    BitOR($WS_CAPTION, $WS_SYSMENU, $WS_MINIMIZEBOX))

If @Compiled Then
    GUISetIcon(@AutoItExe)
Else
    GUISetIcon(@ScriptDir & "\ShowPlayPI-Configurator.ico")
EndIf

Global $g_idTab = GUICtrlCreateTab(18, 18, 664, 510)

; -----------------------------------------------------------------------------
; System tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("System")

GUICtrlCreateLabel("Hostname", 45, 75, 180, 20)
Global $g_idHostname = GUICtrlCreateInput(IniRead($g_sIniPath, "SYSTEM", "HOSTNAME", "showplaypi"), 245, 70, 390, 26)

GUICtrlCreateLabel("Timezone", 45, 120, 180, 20)
Global $g_sCurrentTimezone = IniRead($g_sIniPath, "SYSTEM", "TIMEZONE", "Europe/Berlin")
Global $g_idTimezone = GUICtrlCreateCombo("", 245, 115, 390, 26, $CBS_DROPDOWN)
GUICtrlSetData($g_idTimezone, _TimezoneList(), $g_sCurrentTimezone)

GUICtrlCreateLabel("NTP server", 45, 165, 180, 20)
Global $g_idNtpServer = GUICtrlCreateInput(IniRead($g_sIniPath, "SYSTEM", "NTP_SERVER", "192.53.103.108"), 245, 160, 390, 26)

GUICtrlCreateLabel("The default NTP server is operated by PTB in Germany.", 245, 195, 390, 35)

; -----------------------------------------------------------------------------
; Network tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("Network")

GUICtrlCreateLabel("Address mode", 45, 75, 180, 20)
Global $g_idNetworkMode = GUICtrlCreateCombo("", 245, 70, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idNetworkMode, "dhcp|static", IniRead($g_sIniPath, "NETWORK", "MODE", "dhcp"))

GUICtrlCreateLabel("IP address", 45, 120, 180, 20)
Global $g_idIpAddress = GUICtrlCreateInput(IniRead($g_sIniPath, "NETWORK", "IP", ""), 245, 115, 200, 26)

GUICtrlCreateLabel("Subnet mask", 45, 165, 180, 20)
Global $g_idNetmask = GUICtrlCreateInput(IniRead($g_sIniPath, "NETWORK", "NETMASK", "255.255.255.0"), 245, 160, 200, 26)

GUICtrlCreateLabel("Gateway", 45, 210, 180, 20)
Global $g_idGateway = GUICtrlCreateInput(IniRead($g_sIniPath, "NETWORK", "GATEWAY", ""), 245, 205, 200, 26)

GUICtrlCreateLabel("Primary / additional DNS", 45, 255, 180, 20)
Global $g_idDns1 = GUICtrlCreateInput(IniRead($g_sIniPath, "NETWORK", "DNS1", ""), 245, 250, 200, 26)

GUICtrlCreateLabel("Secondary / fallback DNS", 45, 300, 180, 20)
Global $g_idDns2 = GUICtrlCreateInput(IniRead($g_sIniPath, "NETWORK", "DNS2", "8.8.8.8"), 245, 295, 200, 26)

GUICtrlCreateLabel("In DHCP mode, DNS1 and DNS2 are added to DNS servers received through DHCP.", 245, 335, 390, 55)

; -----------------------------------------------------------------------------
; Browser tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("Browser")

GUICtrlCreateLabel("Target URL", 45, 75, 180, 20)
Global $g_idUrl = GUICtrlCreateInput(IniRead($g_sIniPath, "BROWSER", "URL", "file:///home/admin/kiosk/setup.html"), 245, 70, 390, 26)

Global $g_idIgnoreCertificates = GUICtrlCreateCheckbox("Ignore invalid HTTPS certificates", 245, 115, 300, 24)
_SetCheckboxFromIni($g_idIgnoreCertificates, IniRead($g_sIniPath, "BROWSER", "IGNORE_CERTIFICATE_ERRORS", "yes"))

Global $g_idWatchdogEnabled = GUICtrlCreateCheckbox("Enable website watchdog", 245, 155, 300, 24)
_SetCheckboxFromIni($g_idWatchdogEnabled, IniRead($g_sIniPath, "BROWSER", "WATCHDOG_ENABLED", "yes"))

GUICtrlCreateLabel("Watchdog interval (seconds)", 45, 205, 180, 20)
Global $g_idWatchdogInterval = GUICtrlCreateInput(IniRead($g_sIniPath, "BROWSER", "WATCHDOG_INTERVAL", "5"), 245, 200, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("Periodic reload (seconds)", 45, 250, 180, 20)
Global $g_idReloadInterval = GUICtrlCreateInput(IniRead($g_sIniPath, "BROWSER", "RELOAD_INTERVAL", "0"), 245, 245, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("Use 0 to disable periodic reloads. The watchdog reloads the page automatically after recovery.", 245, 285, 390, 55)

GUICtrlCreateLabel("Idle timeout (seconds)", 45, 350, 180, 20)
Global $g_idIdleTimeout = GUICtrlCreateInput(IniRead($g_sIniPath, "BROWSER", "IDLE_TIMEOUT", "0"), 245, 345, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("After idle timeout", 45, 395, 180, 20)
Global $g_idIdleAction = GUICtrlCreateCombo("", 245, 390, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idIdleAction, "home|reload", _IdleActionFromIni(IniRead($g_sIniPath, "BROWSER", "IDLE_ACTION", "home")))

Global $g_idIdleClearSession = GUICtrlCreateCheckbox("Clear cookies, form data and logins on reset", 245, 430, 380, 24)
_SetCheckboxFromIni($g_idIdleClearSession, IniRead($g_sIniPath, "BROWSER", "IDLE_CLEAR_SESSION", "no"))

GUICtrlCreateLabel("Returns to the start page after this time without touch, mouse or keyboard input (0 = off). " & _
    "home: only if the visitor left the start page. reload: always reset after use.", 245, 462, 390, 55)

; -----------------------------------------------------------------------------
; Display tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("Display")

GUICtrlCreateLabel("Display mode", 45, 75, 180, 20)
Global $g_idDisplayMode = GUICtrlCreateCombo("", 245, 70, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idDisplayMode, "auto|fixed", IniRead($g_sIniPath, "DISPLAY", "MODE", "auto"))

GUICtrlCreateLabel("Headless fallback", 45, 120, 180, 20)
Global $g_sCurrentFallback = _DisplayValueToLabel(IniRead($g_sIniPath, "DISPLAY", "FALLBACK", "1920x1080@60"))
Global $g_idFallback = GUICtrlCreateCombo("", 245, 115, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idFallback, _DisplayModeList(), $g_sCurrentFallback)

GUICtrlCreateLabel("Fixed resolution", 45, 165, 180, 20)
Global $g_idResolution = GUICtrlCreateInput(IniRead($g_sIniPath, "DISPLAY", "RESOLUTION", "1920x1080"), 245, 160, 200, 26)

GUICtrlCreateLabel("Fixed refresh rate", 45, 210, 180, 20)
Global $g_idRefresh = GUICtrlCreateInput(IniRead($g_sIniPath, "DISPLAY", "REFRESH", "60"), 245, 205, 120, 26)

GUICtrlCreateLabel("Auto uses the connected display's EDID. Fixed always uses the configured resolution and refresh rate.", 245, 250, 390, 55)

; -----------------------------------------------------------------------------
; VNC tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("VNC")

Global $g_idVncEnabled = GUICtrlCreateCheckbox("Enable VNC remote access", 245, 75, 300, 24)
_SetCheckboxFromIni($g_idVncEnabled, IniRead($g_sIniPath, "VNC", "ENABLED", "yes"))

GUICtrlCreateLabel("VNC port", 45, 125, 180, 20)
Global $g_idVncPort = GUICtrlCreateInput(IniRead($g_sIniPath, "VNC", "PORT", "5900"), 245, 120, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("VNC displays the actual Chromium kiosk session shown on HDMI.", 245, 165, 390, 40)

; -----------------------------------------------------------------------------
; OSC tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("OSC")

Global $g_idOscEnabled = GUICtrlCreateCheckbox("Enable OSC remote control", 245, 75, 300, 24)
_SetCheckboxFromIni($g_idOscEnabled, IniRead($g_sIniPath, "OSC", "ENABLED", "yes"))

GUICtrlCreateLabel("UDP port", 45, 125, 180, 20)
Global $g_idOscPort = GUICtrlCreateInput("9000", 245, 120, 120, 26, $ES_READONLY)
GUICtrlSetState($g_idOscPort, $GUI_DISABLE)

GUICtrlCreateLabel( _
    "OSC uses UDP port 9000. Changes made via OSC (for example a new URL or idle timeout) " & _
    "last until the next restart. Permanent changes are only made here in the configuration.", _
    245, 170, 390, 60)

; -----------------------------------------------------------------------------
; About tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("About")

GUICtrlCreateLabel("ShowPlayPI Configurator", 45, 75, 590, 32)
GUICtrlSetFont(-1, 16, 600)

GUICtrlCreateLabel("Version " & $g_sAppVersion, 45, 115, 590, 24)
GUICtrlSetFont(-1, 10, 400)

GUICtrlCreateLabel( _
    "ShowPlayPI Configurator provides an easy way to edit the showplaypi.ini " & _
    "configuration file for ShowPlayPI devices.", _
    45, 160, 590, 55)

GUICtrlCreateLabel( _
    "The latest version and additional information are available on the project website:", _
    45, 230, 590, 40)

GUICtrlCreateLabel($g_sDownloadUrl, 45, 275, 590, 24)
GUICtrlSetColor(-1, 0x0066CC)

GUICtrlCreateLabel("Support: " & $g_sSupportEmail, 45, 305, 590, 24)

Global $g_idDownloadPage = GUICtrlCreateButton("Open Download Page", 45, 345, 190, 34)

GUICtrlCreateTabItem("")

Global $g_idStatus = GUICtrlCreateLabel("Configuration file: " & $g_sIniPath, 25, 545, 500, 22)
Global $g_idSave = GUICtrlCreateButton("Save Configuration", 520, 540, 160, 34)

_UpdateNetworkControls()
_UpdateDisplayControls()
GUISetState(@SW_SHOW, $g_hGui)

While True
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            Local $iCloseChoice = MsgBox( _
                BitOR($MB_ICONQUESTION, $MB_YESNOCANCEL), _
                "ShowPlayPI Configurator", _
                "Do you want to save the configuration before closing?")

            Switch $iCloseChoice
                Case $IDYES
                    If _SaveConfiguration() Then
                        ExitLoop
                    EndIf

                Case $IDNO
                    ExitLoop

                Case $IDCANCEL
                    ; Keep the configurator open.
            EndSwitch

        Case $g_idNetworkMode
            _UpdateNetworkControls()

        Case $g_idDisplayMode
            _UpdateDisplayControls()

        Case $g_idSave
            If _SaveConfiguration() Then
                ExitLoop
            EndIf

        Case $g_idDownloadPage
            ShellExecute($g_sDownloadUrl)
    EndSwitch
WEnd

GUIDelete($g_hGui)


Func _CreateDefaultIni()
    Local $bSuccess = True

    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "HOSTNAME", "showplaypi") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "TIMEZONE", "Europe/Berlin") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "NTP_SERVER", "192.53.103.108") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "MODE", "dhcp") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "IP", "") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "NETMASK", "255.255.255.0") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "GATEWAY", "") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "DNS1", "") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "DNS2", "8.8.8.8") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "URL", "file:///home/admin/kiosk/setup.html") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IGNORE_CERTIFICATE_ERRORS", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "WATCHDOG_ENABLED", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "WATCHDOG_INTERVAL", "5") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "RELOAD_INTERVAL", "0") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_TIMEOUT", "0") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_ACTION", "home") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_CLEAR_SESSION", "no") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "MODE", "auto") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "FALLBACK", "1920x1080@60") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "RESOLUTION", "1920x1080") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "REFRESH", "60") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "VNC", "ENABLED", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VNC", "PORT", "5900") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "OSC", "ENABLED", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "OSC", "PORT", "9000") And $bSuccess

    Return $bSuccess
EndFunc


Func _SaveConfiguration()
    Local $sHostname = StringStripWS(GUICtrlRead($g_idHostname), 3)
    Local $sTimezone = StringStripWS(GUICtrlRead($g_idTimezone), 3)
    Local $sNtp = StringStripWS(GUICtrlRead($g_idNtpServer), 3)
    Local $sNetworkMode = StringLower(GUICtrlRead($g_idNetworkMode))
    Local $sIp = StringStripWS(GUICtrlRead($g_idIpAddress), 3)
    Local $sMask = StringStripWS(GUICtrlRead($g_idNetmask), 3)
    Local $sGateway = StringStripWS(GUICtrlRead($g_idGateway), 3)
    Local $sDns1 = StringStripWS(GUICtrlRead($g_idDns1), 3)
    Local $sDns2 = StringStripWS(GUICtrlRead($g_idDns2), 3)
    Local $sUrl = StringStripWS(GUICtrlRead($g_idUrl), 3)
    Local $iWatchdogInterval = Number(GUICtrlRead($g_idWatchdogInterval))
    Local $iReloadInterval = Number(GUICtrlRead($g_idReloadInterval))
    Local $iIdleTimeout = Number(GUICtrlRead($g_idIdleTimeout))
    Local $sIdleAction = StringLower(GUICtrlRead($g_idIdleAction))
    Local $sDisplayMode = StringLower(GUICtrlRead($g_idDisplayMode))
    Local $sFallback = _DisplayLabelToValue(StringStripWS(GUICtrlRead($g_idFallback), 3))
    Local $sResolution = StringStripWS(GUICtrlRead($g_idResolution), 3)
    Local $sRefresh = StringStripWS(GUICtrlRead($g_idRefresh), 3)
    Local $iVncPort = Number(GUICtrlRead($g_idVncPort))

    If Not StringRegExp($sHostname, "^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$") Then
        _ValidationError("Enter a valid hostname.", $g_idHostname)
        Return
    EndIf

    If $sTimezone = "" Or StringInStr($sTimezone, "..") Then
        _ValidationError("Enter a valid Linux timezone, for example Europe/Berlin.", $g_idTimezone)
        Return
    EndIf

    If Not _IsValidIPv4($sNtp) Then
        _ValidationError("Enter a valid IPv4 address for the NTP server.", $g_idNtpServer)
        Return
    EndIf

    If $sNetworkMode = "static" Then
        If Not _IsValidIPv4($sIp) Then
            _ValidationError("Enter a valid static IPv4 address.", $g_idIpAddress)
            Return
        EndIf

        If Not _IsValidNetmask($sMask) Then
            _ValidationError("Enter a valid contiguous subnet mask.", $g_idNetmask)
            Return
        EndIf

        If $sGateway <> "" And Not _IsValidIPv4($sGateway) Then
            _ValidationError("Enter a valid gateway address or leave the field empty.", $g_idGateway)
            Return
        EndIf
    EndIf

    If $sDns1 <> "" And Not _IsValidIPv4($sDns1) Then
        _ValidationError("Enter a valid primary DNS address or leave the field empty.", $g_idDns1)
        Return
    EndIf

    If $sDns2 <> "" And Not _IsValidIPv4($sDns2) Then
        _ValidationError("Enter a valid secondary DNS address or leave the field empty.", $g_idDns2)
        Return
    EndIf

    If Not StringRegExp($sUrl, "(?i)^(https?|file)://.+") Then
        _ValidationError("The target URL must begin with http://, https:// or file://.", $g_idUrl)
        Return
    EndIf

    If $iWatchdogInterval < 2 Or $iWatchdogInterval > 300 Then
        _ValidationError("The watchdog interval must be between 2 and 300 seconds.", $g_idWatchdogInterval)
        Return
    EndIf

    If $iReloadInterval < 0 Then
        _ValidationError("The reload interval cannot be negative.", $g_idReloadInterval)
        Return
    EndIf

    If $iIdleTimeout < 0 Or $iIdleTimeout > 86400 Then
        _ValidationError("The idle timeout must be between 0 (off) and 86400 seconds.", $g_idIdleTimeout)
        Return
    EndIf

    If Not StringRegExp($sFallback, "^[0-9]{3,5}x[0-9]{3,5}@[0-9]+(?:\.[0-9]+)?$") Then
        _ValidationError("Enter the fallback as WIDTHxHEIGHT@REFRESH, for example 1920x1080@60.", $g_idFallback)
        Return
    EndIf

    If Not StringRegExp($sResolution, "^[0-9]{3,5}x[0-9]{3,5}$") Then
        _ValidationError("Enter the fixed resolution as WIDTHxHEIGHT.", $g_idResolution)
        Return
    EndIf

    If Not StringRegExp($sRefresh, "^[0-9]+(?:\.[0-9]+)?$") Then
        _ValidationError("Enter a valid refresh rate.", $g_idRefresh)
        Return
    EndIf

    If $iVncPort < 1024 Or $iVncPort > 65535 Then
        _ValidationError("The VNC port must be between 1024 and 65535.", $g_idVncPort)
        Return
    EndIf

    Local $bSuccess = True
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "HOSTNAME", $sHostname) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "TIMEZONE", $sTimezone) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "NTP_SERVER", $sNtp) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "MODE", $sNetworkMode) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "IP", $sIp) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "NETMASK", $sMask) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "GATEWAY", $sGateway) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "DNS1", $sDns1) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "DNS2", $sDns2) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "URL", $sUrl) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IGNORE_CERTIFICATE_ERRORS", _CheckboxValue($g_idIgnoreCertificates)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "WATCHDOG_ENABLED", _CheckboxValue($g_idWatchdogEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "WATCHDOG_INTERVAL", String($iWatchdogInterval)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "RELOAD_INTERVAL", String($iReloadInterval)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_TIMEOUT", String($iIdleTimeout)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_ACTION", $sIdleAction) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_CLEAR_SESSION", _CheckboxValue($g_idIdleClearSession)) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "MODE", $sDisplayMode) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "FALLBACK", $sFallback) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "RESOLUTION", $sResolution) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "REFRESH", $sRefresh) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "VNC", "ENABLED", _CheckboxValue($g_idVncEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VNC", "PORT", String($iVncPort)) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "OSC", "ENABLED", _CheckboxValue($g_idOscEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "OSC", "PORT", "9000") And $bSuccess

    If Not $bSuccess Then
        MsgBox($MB_ICONERROR, "ShowPlayPI Configurator", _
            "The configuration could not be saved." & @CRLF & @CRLF & _
            "Make sure the drive is not write-protected and try again.")
        Return
    EndIf

    GUICtrlSetData($g_idStatus, "Configuration saved successfully: " & $g_sIniPath)
    MsgBox($MB_ICONINFORMATION, "ShowPlayPI Configurator", _
        "Configuration saved successfully." & @CRLF & @CRLF & _
        "Eject the drive, then restart ShowPlayPI to apply the changes.")

    Return True
EndFunc


Func _UpdateNetworkControls()
    Local $iState = $GUI_DISABLE

    If StringLower(GUICtrlRead($g_idNetworkMode)) = "static" Then
        $iState = $GUI_ENABLE
    EndIf

    GUICtrlSetState($g_idIpAddress, $iState)
    GUICtrlSetState($g_idNetmask, $iState)
    GUICtrlSetState($g_idGateway, $iState)
EndFunc


Func _UpdateDisplayControls()
    Local $bFixed = StringLower(GUICtrlRead($g_idDisplayMode)) = "fixed"

    GUICtrlSetState($g_idFallback, $bFixed ? $GUI_DISABLE : $GUI_ENABLE)
    GUICtrlSetState($g_idResolution, $bFixed ? $GUI_ENABLE : $GUI_DISABLE)
    GUICtrlSetState($g_idRefresh, $bFixed ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc


Func _DisplayModeList()
    Return "1080p60|1080p50|1080p30|1080p25|" & _
        "720p60|720p50|720p30|720p25|" & _
        "2160p60|2160p50|2160p30|2160p25"
EndFunc


Func _DisplayValueToLabel($sValue)
    Switch StringLower($sValue)
        Case "1920x1080@60"
            Return "1080p60"
        Case "1920x1080@50"
            Return "1080p50"
        Case "1920x1080@30"
            Return "1080p30"
        Case "1920x1080@25"
            Return "1080p25"
        Case "1280x720@60"
            Return "720p60"
        Case "1280x720@50"
            Return "720p50"
        Case "1280x720@30"
            Return "720p30"
        Case "1280x720@25"
            Return "720p25"
        Case "3840x2160@60"
            Return "2160p60"
        Case "3840x2160@50"
            Return "2160p50"
        Case "3840x2160@30"
            Return "2160p30"
        Case "3840x2160@25"
            Return "2160p25"
        Case Else
            Return "1080p60"
    EndSwitch
EndFunc


Func _DisplayLabelToValue($sLabel)
    Switch StringLower($sLabel)
        Case "1080p60"
            Return "1920x1080@60"
        Case "1080p50"
            Return "1920x1080@50"
        Case "1080p30"
            Return "1920x1080@30"
        Case "1080p25"
            Return "1920x1080@25"
        Case "720p60"
            Return "1280x720@60"
        Case "720p50"
            Return "1280x720@50"
        Case "720p30"
            Return "1280x720@30"
        Case "720p25"
            Return "1280x720@25"
        Case "2160p60"
            Return "3840x2160@60"
        Case "2160p50"
            Return "3840x2160@50"
        Case "2160p30"
            Return "3840x2160@30"
        Case "2160p25"
            Return "3840x2160@25"
        Case Else
            Return "1920x1080@60"
    EndSwitch
EndFunc


Func _TimezoneList()
    Return "UTC|" & _
        "Africa/Abidjan|Africa/Accra|Africa/Addis_Ababa|Africa/Algiers|Africa/Cairo|" & _
        "Africa/Casablanca|Africa/Dar_es_Salaam|Africa/Harare|Africa/Johannesburg|" & _
        "Africa/Kampala|Africa/Khartoum|Africa/Lagos|Africa/Maputo|Africa/Nairobi|" & _
        "Africa/Tripoli|Africa/Tunis|" & _
        "America/Anchorage|America/Argentina/Buenos_Aires|America/Asuncion|America/Bogota|" & _
        "America/Caracas|America/Chicago|America/Costa_Rica|America/Denver|America/Detroit|" & _
        "America/Edmonton|America/Guatemala|America/Halifax|America/Havana|America/Indiana/Indianapolis|" & _
        "America/La_Paz|America/Lima|America/Los_Angeles|America/Manaus|America/Mexico_City|" & _
        "America/Montevideo|America/New_York|America/Panama|America/Phoenix|America/Puerto_Rico|" & _
        "America/Santiago|America/Santo_Domingo|America/Sao_Paulo|America/St_Johns|" & _
        "America/Toronto|America/Vancouver|America/Winnipeg|" & _
        "Asia/Amman|Asia/Baghdad|Asia/Baku|Asia/Bangkok|Asia/Beirut|Asia/Colombo|Asia/Damascus|" & _
        "Asia/Dhaka|Asia/Dubai|Asia/Hong_Kong|Asia/Ho_Chi_Minh|Asia/Jakarta|Asia/Jerusalem|" & _
        "Asia/Kabul|Asia/Karachi|Asia/Kathmandu|Asia/Kolkata|Asia/Kuala_Lumpur|Asia/Kuwait|" & _
        "Asia/Manila|Asia/Muscat|Asia/Nicosia|Asia/Novosibirsk|Asia/Riyadh|Asia/Seoul|" & _
        "Asia/Shanghai|Asia/Singapore|Asia/Taipei|Asia/Tashkent|Asia/Tbilisi|Asia/Tehran|" & _
        "Asia/Tokyo|Asia/Ulaanbaatar|Asia/Yerevan|" & _
        "Atlantic/Azores|Atlantic/Bermuda|Atlantic/Canary|Atlantic/Cape_Verde|Atlantic/Reykjavik|" & _
        "Australia/Adelaide|Australia/Brisbane|Australia/Darwin|Australia/Hobart|" & _
        "Australia/Melbourne|Australia/Perth|Australia/Sydney|" & _
        "Europe/Amsterdam|Europe/Athens|Europe/Belgrade|Europe/Berlin|Europe/Brussels|" & _
        "Europe/Bucharest|Europe/Budapest|Europe/Copenhagen|Europe/Dublin|Europe/Helsinki|" & _
        "Europe/Istanbul|Europe/Kaliningrad|Europe/Kiev|Europe/Kyiv|Europe/Lisbon|Europe/London|Europe/Luxembourg|" & _
        "Europe/Madrid|Europe/Malta|Europe/Minsk|Europe/Moscow|Europe/Oslo|Europe/Paris|" & _
        "Europe/Prague|Europe/Riga|Europe/Rome|Europe/Sofia|Europe/Stockholm|Europe/Tallinn|" & _
        "Europe/Vienna|Europe/Vilnius|Europe/Warsaw|Europe/Zurich|" & _
        "Indian/Maldives|Indian/Mauritius|Indian/Reunion|" & _
        "Pacific/Auckland|Pacific/Chatham|Pacific/Fiji|Pacific/Guam|Pacific/Honolulu|" & _
        "Pacific/Noumea|Pacific/Port_Moresby|Pacific/Tahiti|Pacific/Tongatapu"
EndFunc


Func _SetCheckboxFromIni($iControl, $sValue)
    Switch StringLower(StringStripWS($sValue, 3))
        Case "yes", "true", "1", "on"
            GUICtrlSetState($iControl, $GUI_CHECKED)
        Case Else
            GUICtrlSetState($iControl, $GUI_UNCHECKED)
    EndSwitch
EndFunc


Func _CheckboxValue($iControl)
    If BitAND(GUICtrlRead($iControl), $GUI_CHECKED) = $GUI_CHECKED Then
        Return "yes"
    EndIf

    Return "no"
EndFunc


Func _ValidationError($sMessage, $iControl)
    MsgBox($MB_ICONWARNING, "Invalid Configuration", $sMessage)
    GUICtrlSetState($iControl, $GUI_FOCUS)
EndFunc


Func _IsValidIPv4($sAddress)
    Local $aParts = StringSplit($sAddress, ".", 2)
    Local $sPart

    If UBound($aParts) <> 4 Then Return False

    For $sPart In $aParts
        If $sPart = "" Or Not StringIsDigit($sPart) Then Return False
        If Number($sPart) < 0 Or Number($sPart) > 255 Then Return False
    Next

    Return True
EndFunc


Func _IsValidNetmask($sNetmask)
    Local $aParts = StringSplit($sNetmask, ".", 2)
    Local $bPartialFound = False
    Local $sPart

    If UBound($aParts) <> 4 Then Return False

    For $sPart In $aParts
        If Not StringIsDigit($sPart) Then Return False

        Local $iValue = Number($sPart)

        Switch $iValue
            Case 255
                If $bPartialFound Then Return False

            Case 254, 252, 248, 240, 224, 192, 128
                If $bPartialFound Then Return False
                $bPartialFound = True

            Case 0
                $bPartialFound = True

            Case Else
                Return False
        EndSwitch
    Next

    Return True
EndFunc


Func _IdleActionFromIni($sValue)
    If StringLower(StringStripWS($sValue, 3)) = "reload" Then Return "reload"
    Return "home"
EndFunc
