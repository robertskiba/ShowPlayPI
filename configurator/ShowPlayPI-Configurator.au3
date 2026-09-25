#pragma compile(Icon, ShowPlayPI-Configurator.ico)
#pragma compile(ProductName, ShowPlayPI Configurator)
#pragma compile(FileDescription, ShowPlayPI Configurator)
#pragma compile(ProductVersion, 1.0.0-beta.3)
#pragma compile(FileVersion, 1.0.0.0)
#pragma compile(OriginalFilename, ShowPlayPI-Configurator.exe)

; A normal program in the taskbar – no AutoIt tray icon (with "Pause script" and "Exit")
#NoTrayIcon

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <Misc.au3>
#include <UpDownConstants.au3>

Opt("MustDeclareVars", 1)

; Only one configurator at a time: a second start brings the open window to the front
If _Singleton("ShowPlayPI-Configurator", 1) = 0 Then
    WinActivate("ShowPlayPI Configurator")
    Exit
EndIf

Global Const $g_sIniPath = @ScriptDir & "\showplaypi.ini"
; About page values: change these for future releases.
Global Const $g_sAppVersion = "1.0.0-beta.3"
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

; ontime and companion show the browser for now (in preparation)
GUICtrlCreateLabel("Operating mode", 45, 75, 180, 20)
Global $g_idMode = GUICtrlCreateCombo("", 245, 70, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idMode, "browser|video|ontime|companion", _ModeFromIni(IniRead($g_sIniPath, "SYSTEM", "MODE", "browser")))
GUICtrlSetTip($g_idMode, "browser = web page (Browser tab), video = videos and images from the VIDEO folder (Video tab), " & _
    "companion / ontime = Companion or Ontime runs on the device, the screen shows its view (Companion / Ontime tab). " & _
    "Takes effect after a restart.")

GUICtrlCreateLabel("Hostname", 45, 120, 180, 20)
Global $g_idHostname = GUICtrlCreateInput(IniRead($g_sIniPath, "SYSTEM", "HOSTNAME", "showplaypi"), 245, 115, 390, 26)
GUICtrlSetTip($g_idHostname, "showplaypi = automatic: showplaypi- plus the last six digits of the MAC address, e.g. showplaypi-e84042")

GUICtrlCreateLabel("Timezone", 45, 165, 180, 20)
Global $g_sCurrentTimezone = IniRead($g_sIniPath, "SYSTEM", "TIMEZONE", "auto")
Global $g_idTimezone = GUICtrlCreateCombo("", 245, 160, 390, 26, $CBS_DROPDOWN)
GUICtrlSetData($g_idTimezone, _TimezoneList(), $g_sCurrentTimezone)
GUICtrlSetTip($g_idTimezone, "auto = detected from the internet connection at every start (the public IP address is sent to " & _
    "a free service); without internet the last detected time zone is kept")

GUICtrlCreateLabel("NTP server", 45, 210, 180, 20)
Global $g_idNtpServer = GUICtrlCreateInput(IniRead($g_sIniPath, "SYSTEM", "NTP_SERVER", "192.53.103.108"), 245, 205, 390, 26)

GUICtrlCreateLabel("The default NTP server is operated by PTB in Germany.", 245, 240, 390, 35)

Global $g_idUsbConfigMode = GUICtrlCreateCheckbox("USB configuration mode while a computer is connected", 245, 285, 390, 24)
_SetCheckboxFromIni($g_idUsbConfigMode, IniRead($g_sIniPath, "SYSTEM", "USB_CONFIG_MODE", "yes"))
GUICtrlCreateLabel("Playback pauses while a computer uses the drive over USB-C; after unplugging, " & _
    "ShowPlayPI restarts with the new settings.", 245, 312, 390, 35)

Global $g_idBootMessages = GUICtrlCreateCheckbox("Show boot messages (for troubleshooting)", 245, 360, 390, 24)
_SetCheckboxFromIni($g_idBootMessages, IniRead($g_sIniPath, "SYSTEM", "BOOT_MESSAGES", "no"))
GUICtrlCreateLabel("Shows the system messages instead of the startup image while ShowPlayPI starts. " & _
    "A change restarts ShowPlayPI once more automatically.", 245, 387, 390, 35)

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
Global $g_idUrl = GUICtrlCreateInput(IniRead($g_sIniPath, "BROWSER", "URL", ""), 245, 70, 390, 26)
GUICtrlSetTip($g_idUrl, "Empty = default page: the setup page, in Companion mode the emulator chooser, in Ontime mode the Ontime view.")

Global $g_idIgnoreCertificates = GUICtrlCreateCheckbox("Ignore invalid HTTPS certificates", 245, 115, 300, 24)
_SetCheckboxFromIni($g_idIgnoreCertificates, IniRead($g_sIniPath, "BROWSER", "IGNORE_CERTIFICATE_ERRORS", "yes"))

Global $g_idWatchdogEnabled = GUICtrlCreateCheckbox("Enable website watchdog", 245, 155, 300, 24)
_SetCheckboxFromIni($g_idWatchdogEnabled, IniRead($g_sIniPath, "BROWSER", "WATCHDOG_ENABLED", "yes"))

GUICtrlCreateLabel("Watchdog interval (seconds)", 45, 205, 180, 20)
Global $g_idWatchdogInterval = GUICtrlCreateInput(IniRead($g_sIniPath, "BROWSER", "WATCHDOG_INTERVAL", "5"), 245, 200, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("Periodic reload (seconds)", 45, 250, 180, 20)
Global $g_idReloadInterval = GUICtrlCreateInput(IniRead($g_sIniPath, "BROWSER", "RELOAD_INTERVAL", "0"), 245, 245, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("Use 0 to disable periodic reloads. The watchdog reloads the page automatically after recovery.", 245, 285, 390, 55)

; Shown as minutes and seconds; the INI keeps seconds (like the OSC command /showplaypi/idle)
GUICtrlCreateLabel("Idle timeout", 45, 350, 180, 20)
Global $g_iIdleTimeoutIni = Int(Number(IniRead($g_sIniPath, "BROWSER", "IDLE_TIMEOUT", "0")))
Global $g_idIdleMinutes = GUICtrlCreateInput(Int($g_iIdleTimeoutIni / 60), 245, 345, 70, 26, $ES_NUMBER)
; No thousands separator: "1.440" would be read as 1.44
GUICtrlCreateUpdown($g_idIdleMinutes, BitOR($UDS_ALIGNRIGHT, $UDS_SETBUDDYINT, $UDS_ARROWKEYS, $UDS_NOTHOUSANDS))
GUICtrlSetLimit(-1, 1440, 0)
GUICtrlCreateLabel("min", 322, 350, 30, 20)
Global $g_idIdleSeconds = GUICtrlCreateInput(Mod($g_iIdleTimeoutIni, 60), 360, 345, 70, 26, $ES_NUMBER)
GUICtrlCreateUpdown($g_idIdleSeconds)
GUICtrlSetLimit(-1, 59, 0)
GUICtrlCreateLabel("s", 437, 350, 20, 20)

GUICtrlCreateLabel("After idle timeout", 45, 395, 180, 20)
Global $g_idIdleAction = GUICtrlCreateCombo("", 245, 390, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idIdleAction, "home|reload", _IdleActionFromIni(IniRead($g_sIniPath, "BROWSER", "IDLE_ACTION", "home")))

Global $g_idIdleClearSession = GUICtrlCreateCheckbox("Clear cookies, form data and logins on reset", 245, 430, 380, 24)
_SetCheckboxFromIni($g_idIdleClearSession, IniRead($g_sIniPath, "BROWSER", "IDLE_CLEAR_SESSION", "no"))

GUICtrlCreateLabel("Returns to the start page after this time without touch, mouse or keyboard input (0 min 0 s = off). " & _
    "home: only if the visitor left the start page. reload: always reset after use.", 245, 462, 390, 55)

; -----------------------------------------------------------------------------
; Video tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("Video")

GUICtrlCreateLabel("Videos and still images from the folder VIDEO on the drive SHOWPLAYPI play in alphabetical " & _
    "order in a loop (operating mode video). Subfolders are additional playlists.", 45, 65, 590, 40)

Global $g_idVideoAutostart = GUICtrlCreateCheckbox("Start playing automatically", 245, 115, 390, 24)
_SetCheckboxFromIni($g_idVideoAutostart, IniRead($g_sIniPath, "VIDEO", "AUTOSTART", "yes"))

GUICtrlCreateLabel("Start playlist", 45, 160, 180, 20)
Global $g_idVideoPlaylist = GUICtrlCreateInput(IniRead($g_sIniPath, "VIDEO", "PLAYLIST", "VIDEO"), 245, 155, 200, 26)
GUICtrlSetTip($g_idVideoPlaylist, "VIDEO or the name of a subfolder of VIDEO")

GUICtrlCreateLabel("Transition", 45, 205, 180, 20)
Global $g_idVideoTransition = GUICtrlCreateCombo("", 245, 200, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idVideoTransition, "crossfade|black", _ListValue(IniRead($g_sIniPath, "VIDEO", "TRANSITION", "crossfade"), "crossfade|black"))

GUICtrlCreateLabel("Fade time (milliseconds)", 45, 250, 180, 20)
Global $g_idVideoFade = GUICtrlCreateInput(IniRead($g_sIniPath, "VIDEO", "FADE", "1000"), 245, 245, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("Still image duration (seconds)", 45, 295, 180, 20)
Global $g_idVideoStillDuration = GUICtrlCreateInput(IniRead($g_sIniPath, "VIDEO", "STILL_DURATION", "10"), 245, 290, 120, 26, $ES_NUMBER)

GUICtrlCreateLabel("Still image scaling", 45, 340, 180, 20)
Global $g_idVideoStillFit = GUICtrlCreateCombo("", 245, 335, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idVideoStillFit, "fit|fill", _ListValue(IniRead($g_sIniPath, "VIDEO", "STILL_FIT", "fit"), "fit|fill"))

GUICtrlCreateLabel("Volume (percent)", 45, 385, 180, 20)
Global $g_idVideoVolume = GUICtrlCreateInput(IniRead($g_sIniPath, "VIDEO", "VOLUME", "100"), 245, 380, 70, 26, $ES_NUMBER)
GUICtrlCreateUpdown($g_idVideoVolume, BitOR($UDS_ALIGNRIGHT, $UDS_SETBUDDYINT, $UDS_ARROWKEYS, $UDS_NOTHOUSANDS))
GUICtrlSetLimit(-1, 100, 0)

GUICtrlCreateLabel("crossfade is in preparation and fades through black for now. fit: whole image visible; " & _
    "fill: screen filled, edges cut off. A duration in the file name wins, e.g. ""Sponsors [15sec].jpg"".", _
    245, 425, 390, 60)

; -----------------------------------------------------------------------------
; Audio tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("Audio")

GUICtrlCreateLabel("Jingles from the folder AUDIO and background music from AUDIO/LOOP (subfolders are further " & _
    "playlists), controlled via OSC - an optional extra that runs next to the chosen operating mode.", 45, 65, 590, 40)

Global $g_idAudioEnabled = GUICtrlCreateCheckbox("Switch the audio player on", 245, 110, 390, 24)
_SetCheckboxFromIni($g_idAudioEnabled, IniRead($g_sIniPath, "AUDIO", "ENABLED", "no"))

Global $g_idAudioAutostart = GUICtrlCreateCheckbox("Start the background music automatically", 245, 140, 390, 24)
_SetCheckboxFromIni($g_idAudioAutostart, IniRead($g_sIniPath, "AUDIO", "AUTOSTART", "no"))

GUICtrlCreateLabel("Volume: all / music / jingles (%)", 45, 185, 195, 20)
Global $g_idAudioVolume = GUICtrlCreateInput(IniRead($g_sIniPath, "AUDIO", "VOLUME", "100"), 245, 180, 70, 26, $ES_NUMBER)
GUICtrlCreateUpdown($g_idAudioVolume, BitOR($UDS_ALIGNRIGHT, $UDS_SETBUDDYINT, $UDS_ARROWKEYS, $UDS_NOTHOUSANDS))
GUICtrlSetLimit(-1, 100, 0)
Global $g_idAudioLoopVolume = GUICtrlCreateInput(IniRead($g_sIniPath, "AUDIO", "LOOP_VOLUME", "80"), 325, 180, 70, 26, $ES_NUMBER)
GUICtrlCreateUpdown($g_idAudioLoopVolume, BitOR($UDS_ALIGNRIGHT, $UDS_SETBUDDYINT, $UDS_ARROWKEYS, $UDS_NOTHOUSANDS))
GUICtrlSetLimit(-1, 100, 0)
Global $g_idAudioJingleVolume = GUICtrlCreateInput(IniRead($g_sIniPath, "AUDIO", "JINGLE_VOLUME", "100"), 405, 180, 70, 26, $ES_NUMBER)
GUICtrlCreateUpdown($g_idAudioJingleVolume, BitOR($UDS_ALIGNRIGHT, $UDS_SETBUDDYINT, $UDS_ARROWKEYS, $UDS_NOTHOUSANDS))
GUICtrlSetLimit(-1, 100, 0)

GUICtrlCreateLabel("While a jingle plays", 45, 230, 180, 20)
Global $g_idAudioJingleMode = GUICtrlCreateCombo("", 245, 225, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idAudioJingleMode, "duck|pause", _ListValue(IniRead($g_sIniPath, "AUDIO", "JINGLE_MODE", "duck"), "duck|pause"))
GUICtrlSetTip($g_idAudioJingleMode, "duck = the music gets quieter, pause = the music pauses; afterwards it continues")

GUICtrlCreateLabel("Music while ducked (%)", 45, 275, 180, 20)
Global $g_idAudioDuckLevel = GUICtrlCreateInput(IniRead($g_sIniPath, "AUDIO", "DUCK_LEVEL", "30"), 245, 270, 70, 26, $ES_NUMBER)
GUICtrlCreateUpdown($g_idAudioDuckLevel, BitOR($UDS_ALIGNRIGHT, $UDS_SETBUDDYINT, $UDS_ARROWKEYS, $UDS_NOTHOUSANDS))
GUICtrlSetLimit(-1, 100, 0)

GUICtrlCreateLabel("Repeat the music", 45, 320, 180, 20)
Global $g_idAudioRepeat = GUICtrlCreateCombo("", 245, 315, 200, 26, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_idAudioRepeat, "all|one|off", _ListValue(IniRead($g_sIniPath, "AUDIO", "REPEAT", "all"), "all|one|off"))
GUICtrlSetTip($g_idAudioRepeat, "all = endless loop, one = the current track, off = once")

Global $g_idAudioShuffle = GUICtrlCreateCheckbox("Random order", 245, 355, 390, 24)
_SetCheckboxFromIni($g_idAudioShuffle, IniRead($g_sIniPath, "AUDIO", "SHUFFLE", "no"))

GUICtrlCreateLabel("The sound plays on all outputs at once: HDMI, the headphone jack of the Pi 4 and a USB sound card.", _
    245, 395, 390, 40)

; -----------------------------------------------------------------------------
; Companion / Ontime tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("Companion / Ontime")

GUICtrlCreateLabel("Operating mode companion: Bitfocus Companion runs on ShowPlayPI. Set it up in a browser at " & _
    "http://<device name>.local:8000 - the screen shows its emulator chooser (touch, mouse and keyboard work); " & _
    "an emulator can be selected there or via OSC.", 45, 65, 590, 55)

GUICtrlCreateLabel("Operating mode ontime: Ontime runs on ShowPlayPI. Its editor: http://<device name>.local:4001 - " & _
    "the screen shows the view below.", 45, 140, 590, 40)

GUICtrlCreateLabel("Ontime view", 45, 200, 180, 20)
Global $g_idOntimeView = GUICtrlCreateCombo("", 245, 195, 390, 26, $CBS_DROPDOWN)
GUICtrlSetData($g_idOntimeView, "timer|backstage|countdown|studio|timeline", _OntimeViewFromIni(IniRead($g_sIniPath, "ONTIME", "VIEW", "timer")))
GUICtrlSetTip($g_idOntimeView, "A view, optionally with the options of its settings, e.g. backstage?stopCycle=true")

GUICtrlCreateLabel("An own target URL on the Browser tab replaces these views. If Companion's or Ontime's own OSC input " & _
    "is enabled, it must not use UDP port 23878 (ShowPlayPI).", 45, 255, 590, 40)

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

GUICtrlCreateLabel("VNC shows the actual picture on HDMI – the browser or the video player.", 245, 165, 390, 40)

; -----------------------------------------------------------------------------
; Network share tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("Share")

Global $g_idShareEnabled = GUICtrlCreateCheckbox("Share the SHOWPLAYPI drive on the network", 245, 75, 390, 24)
_SetCheckboxFromIni($g_idShareEnabled, IniRead($g_sIniPath, "NETWORK_SHARE", "ENABLED", "yes"))

GUICtrlCreateLabel( _
    "Configuration and files (HTML, VIDEO, AUDIO, PRESETS) can then also be edited over the network:" & @CRLF & @CRLF & _
    "Windows:  \\<device name>.local\SHOWPLAYPI" & @CRLF & _
    "Mac:  smb://<device name>.local/SHOWPLAYPI" & @CRLF & @CRLF & _
    "User name admin, password admin.", _
    245, 120, 390, 130)

Global $g_idUpnpEnabled = GUICtrlCreateCheckbox("Announce web interfaces on the network (UPnP)", 245, 275, 390, 24)
_SetCheckboxFromIni($g_idUpnpEnabled, IniRead($g_sIniPath, "DISCOVERY", "UPNP", "yes"))
GUICtrlCreateLabel("The running web interfaces (Companion, Ontime) appear in Windows under ""Network"" " & _
    "and open with a double-click.", 245, 302, 390, 40)

; -----------------------------------------------------------------------------
; OSC tab
; -----------------------------------------------------------------------------
GUICtrlCreateTabItem("OSC")

Global $g_idOscEnabled = GUICtrlCreateCheckbox("Enable OSC remote control", 245, 75, 300, 24)
_SetCheckboxFromIni($g_idOscEnabled, IniRead($g_sIniPath, "OSC", "ENABLED", "yes"))

GUICtrlCreateLabel("UDP port", 45, 125, 180, 20)
Global $g_idOscPort = GUICtrlCreateInput("23878", 245, 120, 120, 26, $ES_READONLY)
GUICtrlSetState($g_idOscPort, $GUI_DISABLE)

GUICtrlCreateLabel( _
    "OSC uses UDP port 23878. Changes made via OSC (for example a new URL or idle timeout) " & _
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

Global $g_idStatus = GUICtrlCreateLabel("Configuration file: " & $g_sIniPath, 25, 545, 290, 22)
Global $g_idSaveRestart = GUICtrlCreateButton("Save and Restart", 330, 540, 170, 34)
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

        Case $g_idSaveRestart
            If _SaveConfiguration(True) Then
                ExitLoop
            EndIf

        Case $g_idDownloadPage
            ShellExecute($g_sDownloadUrl)
    EndSwitch
WEnd

GUIDelete($g_hGui)


Func _CreateDefaultIni()
    Local $bSuccess = True

    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "MODE", "browser") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "HOSTNAME", "showplaypi") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "TIMEZONE", "auto") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "NTP_SERVER", "192.53.103.108") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "USB_CONFIG_MODE", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "BOOT_MESSAGES", "no") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "MODE", "dhcp") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "IP", "") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "NETMASK", "255.255.255.0") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "GATEWAY", "") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "DNS1", "") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK", "DNS2", "8.8.8.8") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "URL", "") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IGNORE_CERTIFICATE_ERRORS", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "WATCHDOG_ENABLED", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "WATCHDOG_INTERVAL", "5") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "RELOAD_INTERVAL", "0") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_TIMEOUT", "0") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_ACTION", "home") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "BROWSER", "IDLE_CLEAR_SESSION", "no") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "AUTOSTART", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "PLAYLIST", "VIDEO") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "TRANSITION", "crossfade") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "FADE", "1000") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "STILL_DURATION", "10") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "STILL_FIT", "fit") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "VOLUME", "100") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "ONTIME", "VIEW", "timer") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "ENABLED", "no") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "AUTOSTART", "no") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "VOLUME", "100") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "LOOP_VOLUME", "80") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "JINGLE_VOLUME", "100") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "JINGLE_MODE", "duck") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "DUCK_LEVEL", "30") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "REPEAT", "all") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "SHUFFLE", "no") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "MODE", "auto") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "FALLBACK", "1920x1080@60") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "RESOLUTION", "1920x1080") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "REFRESH", "60") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "VNC", "ENABLED", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VNC", "PORT", "5900") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK_SHARE", "ENABLED", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISCOVERY", "UPNP", "yes") And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "OSC", "ENABLED", "yes") And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "OSC", "PORT", "23878") And $bSuccess

    _FlushToDrive($g_sIniPath)
    Return $bSuccess
EndFunc


; Writes the file to the drive immediately instead of leaving it in the Windows write cache.
; The flush reaches ShowPlayPI as SYNCHRONIZE CACHE, which stores the drive on its SD card
; before this function returns - the user can unplug the cable right after saving.
Func _FlushToDrive($sPath)
    Local Const $GENERIC_WRITE = 0x40000000
    Local Const $FILE_SHARE_READ_WRITE = 0x3
    Local Const $OPEN_EXISTING = 3

    Local $aFile = DllCall("kernel32.dll", "handle", "CreateFileW", "wstr", $sPath, "dword", $GENERIC_WRITE, _
        "dword", $FILE_SHARE_READ_WRITE, "ptr", 0, "dword", $OPEN_EXISTING, "dword", 0, "ptr", 0)
    If @error Or $aFile[0] = Ptr(-1) Then Return False

    Local $aFlush = DllCall("kernel32.dll", "bool", "FlushFileBuffers", "handle", $aFile[0])
    Local $bFlushed = (Not @error) And $aFlush[0] <> 0
    DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aFile[0])

    Return $bFlushed
EndFunc


Func _SaveConfiguration($bRestart = False)
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
    Local $iIdleMinutes = Number(GUICtrlRead($g_idIdleMinutes))
    Local $iIdleSeconds = Number(GUICtrlRead($g_idIdleSeconds))
    Local $iIdleTimeout = $iIdleMinutes * 60 + $iIdleSeconds
    Local $sIdleAction = StringLower(GUICtrlRead($g_idIdleAction))
    Local $sDisplayMode = StringLower(GUICtrlRead($g_idDisplayMode))
    Local $sFallback = _DisplayLabelToValue(StringStripWS(GUICtrlRead($g_idFallback), 3))
    Local $sResolution = StringStripWS(GUICtrlRead($g_idResolution), 3)
    Local $sRefresh = StringStripWS(GUICtrlRead($g_idRefresh), 3)
    Local $iVncPort = Number(GUICtrlRead($g_idVncPort))
    Local $sVideoPlaylist = StringStripWS(GUICtrlRead($g_idVideoPlaylist), 3)
    Local $iVideoFade = Number(GUICtrlRead($g_idVideoFade))
    Local $iVideoStillDuration = Number(GUICtrlRead($g_idVideoStillDuration))
    Local $iVideoVolume = Number(GUICtrlRead($g_idVideoVolume))
    Local $sOntimeView = StringStripWS(GUICtrlRead($g_idOntimeView), 3)
    Local $iAudioVolume = Number(GUICtrlRead($g_idAudioVolume))
    Local $iAudioLoopVolume = Number(GUICtrlRead($g_idAudioLoopVolume))
    Local $iAudioJingleVolume = Number(GUICtrlRead($g_idAudioJingleVolume))
    Local $iAudioDuckLevel = Number(GUICtrlRead($g_idAudioDuckLevel))

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

    If $sUrl <> "" And Not StringRegExp($sUrl, "(?i)^(https?|file)://.+") Then
        _ValidationError("The target URL must begin with http://, https:// or file:// (or stay empty for the default page).", $g_idUrl)
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

    If $iIdleSeconds < 0 Or $iIdleSeconds > 59 Then
        _ValidationError("The idle timeout seconds must be between 0 and 59.", $g_idIdleSeconds)
        Return
    EndIf

    If $iIdleMinutes < 0 Or $iIdleTimeout > 86400 Then
        _ValidationError("The idle timeout can be at most 24 hours (1440 minutes).", $g_idIdleMinutes)
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

    If $sVideoPlaylist = "" Or StringRegExp($sVideoPlaylist, "[\\/:*?""<>|]") Then
        _ValidationError("Enter VIDEO or the name of a subfolder of VIDEO as start playlist.", $g_idVideoPlaylist)
        Return
    EndIf

    If $iVideoFade > 60000 Then
        _ValidationError("The fade time can be at most 60000 milliseconds.", $g_idVideoFade)
        Return
    EndIf

    If $iVideoStillDuration < 1 Or $iVideoStillDuration > 86400 Then
        _ValidationError("The still image duration must be between 1 and 86400 seconds.", $g_idVideoStillDuration)
        Return
    EndIf

    If $iVideoVolume > 100 Then
        _ValidationError("The volume must be between 0 and 100 percent.", $g_idVideoVolume)
        Return
    EndIf

    If Not StringRegExp($sOntimeView, "^[A-Za-z0-9_-]+(\?\S+)?$") Then
        _ValidationError("Choose an Ontime view, optionally with options, e.g. backstage?stopCycle=true.", $g_idOntimeView)
        Return
    EndIf

    If $iAudioVolume > 100 Or $iAudioLoopVolume > 100 Or $iAudioJingleVolume > 100 Or $iAudioDuckLevel > 100 Then
        _ValidationError("Audio volumes must be between 0 and 100 percent.", $g_idAudioVolume)
        Return
    EndIf

    Local $bSuccess = True
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "MODE", GUICtrlRead($g_idMode)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "HOSTNAME", $sHostname) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "TIMEZONE", $sTimezone) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "NTP_SERVER", $sNtp) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "USB_CONFIG_MODE", _CheckboxValue($g_idUsbConfigMode)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "SYSTEM", "BOOT_MESSAGES", _CheckboxValue($g_idBootMessages)) And $bSuccess

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

    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "AUTOSTART", _CheckboxValue($g_idVideoAutostart)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "PLAYLIST", $sVideoPlaylist) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "TRANSITION", GUICtrlRead($g_idVideoTransition)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "FADE", String($iVideoFade)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "STILL_DURATION", String($iVideoStillDuration)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "STILL_FIT", GUICtrlRead($g_idVideoStillFit)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VIDEO", "VOLUME", String($iVideoVolume)) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "ONTIME", "VIEW", $sOntimeView) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "ENABLED", _CheckboxValue($g_idAudioEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "AUTOSTART", _CheckboxValue($g_idAudioAutostart)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "VOLUME", String($iAudioVolume)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "LOOP_VOLUME", String($iAudioLoopVolume)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "JINGLE_VOLUME", String($iAudioJingleVolume)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "JINGLE_MODE", GUICtrlRead($g_idAudioJingleMode)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "DUCK_LEVEL", String($iAudioDuckLevel)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "REPEAT", GUICtrlRead($g_idAudioRepeat)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "AUDIO", "SHUFFLE", _CheckboxValue($g_idAudioShuffle)) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "MODE", $sDisplayMode) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "FALLBACK", $sFallback) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "RESOLUTION", $sResolution) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISPLAY", "REFRESH", $sRefresh) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "VNC", "ENABLED", _CheckboxValue($g_idVncEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "NETWORK_SHARE", "ENABLED", _CheckboxValue($g_idShareEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "DISCOVERY", "UPNP", _CheckboxValue($g_idUpnpEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "VNC", "PORT", String($iVncPort)) And $bSuccess

    $bSuccess = IniWrite($g_sIniPath, "OSC", "ENABLED", _CheckboxValue($g_idOscEnabled)) And $bSuccess
    $bSuccess = IniWrite($g_sIniPath, "OSC", "PORT", "23878") And $bSuccess

    If Not $bSuccess Then
        MsgBox($MB_ICONERROR, "ShowPlayPI Configurator", _
            "The configuration could not be saved." & @CRLF & @CRLF & _
            "Make sure the drive is not write-protected and try again.")
        Return
    EndIf

    ; Over USB-C, ShowPlayPI writes what the computer saved to its SD card within about a second;
    ; wait with a safety margin before telling the user to unplug the cable.
    GUICtrlSetData($g_idStatus, "Saving the configuration on ShowPlayPI ...")
    GUISetCursor(15, 1, $g_hGui)
    Local $bFlushed = _FlushToDrive($g_sIniPath)
    If $bRestart Then $bRestart = _RequestRestart()
    Sleep(3000)
    GUISetCursor(2, 0, $g_hGui)

    Local $bNetwork = (DriveGetType(@ScriptDir) = "Network")
    Local $sNext
    If $bRestart And $bNetwork Then
        $sNext = "ShowPlayPI restarts in a few seconds and applies the changes."
    ElseIf $bNetwork Then
        $sNext = "The changes are applied the next time ShowPlayPI starts."
    ElseIf $bFlushed Or $bRestart Then
        ; Over USB-C, unplugging the cable restarts ShowPlayPI anyway (USB configuration mode)
        $sNext = "You can unplug the USB cable now: ShowPlayPI then restarts with the new settings." & @CRLF & @CRLF & _
            "If ShowPlayPI is powered by this computer, start it with its power supply or PoE afterwards."
    Else
        $sNext = "Eject the drive before unplugging the USB cable, then restart ShowPlayPI to apply the changes."
    EndIf

    GUICtrlSetData($g_idStatus, "Configuration saved.")
    MsgBox($MB_ICONINFORMATION, "ShowPlayPI Configurator", "Configuration saved." & @CRLF & @CRLF & $sNext)
    Return True
EndFunc


; Asks ShowPlayPI to restart and apply the configuration: a hidden request file next to showplaypi.ini,
; picked up at once over the network, or when the drive is ejected over USB-C.
Func _RequestRestart()
    Local $sFile = @ScriptDir & "\.restart-request"
    Local $hFile = FileOpen($sFile, $FO_OVERWRITE)
    If $hFile = -1 Then Return False

    FileWrite($hFile, "Restart requested by the ShowPlayPI Configurator" & @CRLF)
    FileClose($hFile)
    FileSetAttrib($sFile, "+H")
    _FlushToDrive($sFile)
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
    Return "auto|UTC|" & _
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

Func _ModeFromIni($sValue)
    Return _ListValue($sValue, "browser|video|ontime|companion")
EndFunc

; The value if it is one of the list entries (case-insensitive), otherwise the first entry
Func _ListValue($sValue, $sList)
    Local $aEntries = StringSplit($sList, "|")
    $sValue = StringLower(StringStripWS($sValue, 3))
    For $i = 1 To $aEntries[0]
        If $aEntries[$i] = $sValue Then Return $aEntries[$i]
    Next
    Return $aEntries[1]
EndFunc


; A view name, optionally with options ("backstage?stopCycle=true"); anything else: timer
Func _OntimeViewFromIni($sValue)
    $sValue = StringStripWS($sValue, 3)
    If StringRegExp($sValue, "^[A-Za-z0-9_-]+(\?\S+)?$") Then Return $sValue
    Return "timer"
EndFunc
