===============================================================================
ShowPlayPI
Configuration Guide
===============================================================================

ShowPlayPI turns a Raspberry Pi 5 or 4 into a playout device for events. It
works in one of four modes:

    browser     full-screen web page (kiosk)
    video       videos and still images in an endless loop
    companion   Bitfocus Companion runs on the device
    ontime      the Ontime timer runs on the device

An audio player for background music and jingles can be switched on in
every mode.

All settings are in one file:

    showplaypi.ini

Changes are applied the next time ShowPlayPI starts.

On the first start ShowPlayPI creates a second drive, SHOWPLAYPI, in the free
space of the SD card. It holds the same showplaypi.ini, the Windows
configurator and folders for your own files (HTML, VIDEO, AUDIO, PRESETS). It
is reachable over USB-C, over the network and with a card reader. Edit either
copy of showplaypi.ini: the changed one is applied at the next start and the
other one is updated.

To use the card for something else, start Clear-SD-Card.cmd on this drive
(Windows). After a confirmation it removes all ShowPlayPI partitions and
leaves an empty card with one partition SDCARD. It works only on the
ShowPlayPI card it is started from.

Full documentation:  https://github.com/robertskiba/ShowPlayPI
Support:             https://konftools.com  -  support@konftools.com


===============================================================================
Quick Start
===============================================================================

With the configurator (Windows, recommended):

1. Connect the computer to the USB-C port of ShowPlayPI (on a Pi 5 use a
   USB-C or USB 3 port of the computer).
2. Open the drive SHOWPLAYPI and start ShowPlayPI-Configurator.exe.
3. Choose the mode and the settings, then save.
4. Unplug the cable. ShowPlayPI restarts with the new settings.

With a text editor (any computer):

1. Power off ShowPlayPI and remove the SD card.
2. Insert the SD card into a computer and open the drive bootfs or
   SHOWPLAYPI.
3. Open showplaypi.ini with a plain-text editor, e.g. set a web page:

       [SYSTEM]
       MODE=browser

       [BROWSER]
       URL=http://192.168.1.100

4. Save the file, safely eject the SD card, insert it into ShowPlayPI and
   power it on.

Without a configured web page, the browser mode shows the setup page with
the device name and IP address.


===============================================================================
System Settings
===============================================================================

[SYSTEM]

MODE=browser

    browser     full-screen web page (section [BROWSER])
    video       videos and still images from the folder VIDEO on the drive
                SHOWPLAYPI (section [VIDEO])
    companion   Bitfocus Companion runs on the device; the screen shows its
                emulator chooser. Set up Companion in a browser at
                http://showplaypi-xxxxxx.local:8000
    ontime      Ontime runs on the device; the screen shows its timer
                (section [ONTIME]). Editor:
                http://showplaypi-xxxxxx.local:4001

    showplaypi-xxxxxx is the device name (see HOSTNAME). The mode is changed
    only here, never via OSC.


HOSTNAME=showplaypi

    Device name used on the network.

    The default "showplaypi" becomes "showplaypi-" plus the last six digits
    of the MAC address, for example:

        showplaypi-e84042

    Every device thus has its own name from the first start. It is
    reachable as <name>.local (e.g. showplaypi-e84042.local); the name is
    shown on the setup page. Any other name is used as it is: letters,
    digits and hyphens - other characters such as _ or a space become a
    hyphen (stage_left becomes stage-left).


TIMEZONE=auto

    auto = detected from the internet connection at every start (the public
    IP address is sent to a free service); without internet the last
    detected time zone is kept, at first Europe/Berlin.

    Or a time zone name, which is always used as it is, for example:

        Europe/Berlin
        Europe/London
        America/New_York
        Asia/Tokyo


NTP_SERVER=192.53.103.108

    NTP server used for automatic clock synchronisation.

    The default IP belongs to a public PTB time server in Germany.
    An IP address works without DNS. Public time servers and the time
    servers the router announces are a reserve.

    Without internet the clock starts from the latest known time: the time
    of the last run, or the time showplaypi.ini was last saved on a computer.


USB_CONFIG_MODE=yes

    USB configuration mode. While a computer is connected via USB-C,
    ShowPlayPI is a drive, not a player: playback pauses and a status screen
    is shown. After unplugging the cable, ShowPlayPI restarts with the new
    settings (when powered by PoE or its power supply; powered by the
    computer it simply switches off).

    yes = configuration mode while a computer is connected
    no  = playback continues; the drive SHOWPLAYPI still goes to the
          computer, so local pages from it are not available meanwhile


BOOT_MESSAGES=no

    yes = show the system messages on the screen while ShowPlayPI starts
          (for troubleshooting)
    no  = show the startup image

    A change restarts ShowPlayPI once more automatically.


===============================================================================
Network Settings
===============================================================================

[NETWORK]

MODE=dhcp
IP=
NETMASK=255.255.255.0
GATEWAY=
DNS1=
DNS2=8.8.8.8

MODE=dhcp obtains the IP address, subnet mask, gateway and DNS server
automatically. DNS1 and DNS2 are added to the DNS servers supplied by DHCP
(default DNS2: 8.8.8.8, Google Public DNS).

Static address, example:

    [NETWORK]
    MODE=static
    IP=192.168.1.100
    NETMASK=255.255.255.0
    GATEWAY=192.168.1.1
    DNS1=192.168.1.1
    DNS2=8.8.8.8

GATEWAY and DNS1 may remain empty in an isolated local network.

Invalid network values are rejected. A valid but wrong static address can
make ShowPlayPI unreachable - then correct showplaypi.ini on the SD card or
set MODE=dhcp.


===============================================================================
Browser Settings
===============================================================================

[BROWSER]

URL=

    Web page shown in full screen. Supported address types:

        http://
        https://
        file://     (own pages on the drive SHOWPLAYPI, e.g.
                     file:///media/showplaypi/HTML/index.html)

    Empty = the default page: the setup page in browser mode, the emulator
    chooser in companion mode, the Ontime view in ontime mode. An own URL
    replaces the Companion and Ontime views.

    Addresses may contain special characters such as umlauts - ShowPlayPI
    converts them automatically.


IGNORE_CERTIFICATE_ERRORS=yes

    yes = also show local web pages with self-signed, expired or otherwise
          invalid HTTPS certificates


WATCHDOG_ENABLED=yes
WATCHDOG_INTERVAL=5

    The watchdog checks the web page every WATCHDOG_INTERVAL seconds (2 to
    300). If the page was not reachable, it is reloaded as soon as it is
    reachable again. Local file:// pages are not checked.


RELOAD_INTERVAL=0

    Reloads the page every this number of seconds (e.g. 60, 300, 3600).
    0 = never. Dynamic pages and web apps normally use 0.


IDLE_TIMEOUT=0
IDLE_ACTION=home
IDLE_CLEAR_SESSION=no

    For touch kiosks. IDLE_TIMEOUT: return to the start page after this
    number of seconds without touch, mouse or keyboard input (0 = off,
    typical 60 to 300).

    IDLE_ACTION:

        home      open the start page again if the visitor has left it
        reload    always reload the start page after it was used (also
                  resets web apps whose address does not change)

    IDLE_CLEAR_SESSION=yes clears cookies, form data and logins when
    resetting, so the next visitor does not see the data of the previous
    one. Recommended for public kiosks.


===============================================================================
Video Settings (MODE=video)
===============================================================================

Put videos (MP4, MOV, MKV, WebM ...) and still images (JPG, PNG, WebP) into
the folder VIDEO on the drive SHOWPLAYPI. They play in alphabetical order in
an endless loop, e.g. 010_Intro.mp4, 020_Sponsors.jpg, 030_Trailer.mp4.
Subfolders of VIDEO are further playlists (selectable via OSC).

Best video format: H.265/HEVC. On the Raspberry Pi 5, H.264 videos should not
exceed 1080p with 30 frames per second.

[VIDEO]

AUTOSTART=yes          yes = play after the start, no = black until an OSC
                       play command arrives
PLAYLIST=VIDEO         VIDEO or the name of a subfolder
TRANSITION=crossfade   crossfade or black (crossfades fade through black
                       for now)
FADE=1000              fade time in milliseconds, 0 = hard cut
STILL_DURATION=10      display time of still images in seconds; a time in
                       the file name wins: "020_Sponsors [15sec].jpg"
STILL_FIT=fit          fit = whole image with black bars,
                       fill = screen filled, edges cut off
VOLUME=100             volume of the videos in percent


===============================================================================
Audio Player (optional, in every mode)
===============================================================================

Jingles: audio files in the folder AUDIO on the drive SHOWPLAYPI, played on
command (OSC), e.g. from a Companion button. Background music: the folder
AUDIO/LOOP is playlist 1, its subfolders are further playlists.
Formats: WAV, MP3, FLAC, OGG/Opus, M4A/AAC. The sound plays on all outputs at
once (HDMI, headphone jack of the Pi 4, USB sound card).

[AUDIO]

ENABLED=no             yes = switch the audio player on
AUTOSTART=no           yes = start playlist 1 after the start
VOLUME=100             volumes in percent: all audio,
LOOP_VOLUME=80         the playlist,
JINGLE_VOLUME=100      the jingles
JINGLE_MODE=duck       during a jingle the playlist gets quieter (duck) or
DUCK_LEVEL=30          pauses (pause); DUCK_LEVEL = percent while ducked
REPEAT=all             all = endless loop, one = current track, off = once
SHUFFLE=no             yes = random order


===============================================================================
Ontime Settings (MODE=ontime)
===============================================================================

[ONTIME]

VIEW=timer

    Ontime view on the screen: timer, backstage, countdown, studio or
    timeline. Options of the view can follow after "?", for example:

        backstage?stopCycle=true

    Ontime's own OSC input, if enabled in Ontime, must not use port 23878.


===============================================================================
Companion (MODE=companion)
===============================================================================

Companion has no section of its own. Set it up in a browser at
http://showplaypi-xxxxxx.local:8000. USB control surfaces such as the Stream
Deck can be plugged into ShowPlayPI. Backups are stored in COMPANION/BACKUP
on the drive SHOWPLAYPI.

Companion's own OSC receiver, if enabled, must not use port 23878.

Every Companion connection needs memory: a Pi with 1 GB is enough for about
5 connections, 2 GB for typical events, 4 GB for large setups.


===============================================================================
Display Settings
===============================================================================

[DISPLAY]

MODE=auto
FALLBACK=1920x1080@60
RESOLUTION=1920x1080
REFRESH=60

    auto    use the preferred mode of the connected display; without a
            display (or without usable display data) use FALLBACK
    fixed   always use RESOLUTION and REFRESH

Without a display ShowPlayPI outputs 1920 x 1080 at 60 Hz, so video mixers
and projectors stay locked. Use the HDMI port next to the USB-C socket.


===============================================================================
VNC Remote View
===============================================================================

[VNC]

ENABLED=yes
PORT=5900

    Shows exactly what is on the screen, in every mode. Connect with any
    VNC viewer to:

        showplaypi-xxxxxx.local:5900    (or the IP address)

    Password: admin


===============================================================================
Network Share
===============================================================================

[NETWORK_SHARE]

ENABLED=yes

    Shares the SHOWPLAYPI drive (configuration, HTML, VIDEO, AUDIO, PRESETS)
    on the local network.

    Windows:  \\showplaypi-xxxxxx.local\SHOWPLAYPI
    Mac:      smb://showplaypi-xxxxxx.local/SHOWPLAYPI

    User name admin, password admin. While a computer uses the drive over
    USB-C, the network share pauses.


===============================================================================
Time Server
===============================================================================

[TIME_SERVER]

ENABLED=yes

    Serves the time to every device on the network (NTP, UDP port 123).
    Enter showplaypi-xxxxxx.local or the IP address as time server on the
    other devices. Without an internet time source ShowPlayPI serves its own
    clock, so all devices of a network without internet share the same time.


===============================================================================
Discovery
===============================================================================

[DISCOVERY]

UPNP=yes

    Announces the running web interfaces (Companion, Ontime), so they appear
    in Windows under "Network" and open with a double-click.


===============================================================================
OSC Remote Control
===============================================================================

[OSC]

ENABLED=yes
PORT=23878

    Live control via OSC (UDP port 23878, fixed), e.g. from Bitfocus
    Companion: change the web page, control videos and audio, choose
    Companion emulators and Ontime views, black out the picture.

    Changes made via OSC last until the next restart. All commands:
    docs/OSC.md in the full documentation (see the top of this file).


===============================================================================
Security
===============================================================================

ShowPlayPI is built for isolated event networks and is deliberately easy to
use: the passwords are admin, and OSC has no password. Do not connect it
unchanged to a company network or the internet. VNC, the network share, the
time server, the UPnP announcement and OSC can each be switched off above.


===============================================================================
Automatic Recovery
===============================================================================

ShowPlayPI keeps itself running:

    The browser, the video player, Companion, Ontime and VNC restart
    automatically if they stop.
    A web page that is not reachable is loaded as soon as it is.
    Deleted folders and the configurator on the drive SHOWPLAYPI are
    restored.
    An invalid showplaypi.ini is ignored; the last working configuration
    stays active.
    Deleting showplaypi.ini resets the configuration to the delivery state
    at the next start (your files are kept).


===============================================================================
Troubleshooting
===============================================================================

The setup page appears instead of my web page:

    Check URL in [BROWSER]; it must start with http://, https:// or file://.


Companion or ontime mode shows another page:

    An own URL in [BROWSER] replaces their view - leave it empty.


Videos stutter:

    Convert them to H.265/HEVC. On a Pi 5, H.264 is only smooth up to
    1080p with 30 frames per second.


Not reachable after setting a static IP:

    Power off, put the SD card into a computer, correct [NETWORK] or set
    MODE=dhcp.


No picture on the display:

    Use the HDMI port next to the USB-C socket. Try [DISPLAY] MODE=fixed
    with a resolution the display supports.


The .local name is not found:

    Use the IP address shown on the setup page; some networks block .local
    names.


VNC does not connect:

    Make sure ENABLED=yes in [VNC] and use port 5900.


===============================================================================
Important Notes
===============================================================================

Do not rename section names or setting names.

MODE exists in [SYSTEM], [NETWORK] and [DISPLAY]. Always edit the correct
section.

Use a plain-text editor and save showplaypi.ini as UTF-8. Do not use
word-processing applications such as Microsoft Word.

Always safely eject the SD card or the drive before unplugging it.

ShowPlayPI Configuration Guide
===============================================================================
