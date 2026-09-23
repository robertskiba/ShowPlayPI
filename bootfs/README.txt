===============================================================================
ShowPlayPI
Configuration Guide
===============================================================================

ShowPlayPI opens a configured website automatically in fullscreen kiosk mode.

Configuration is stored in:

    showplaypi.ini

Edit showplaypi.ini with a plain-text editor, save the file and safely eject the
SD card before inserting it into ShowPlayPI.

Changes are applied after restarting ShowPlayPI.


===============================================================================
Quick Start
===============================================================================

1. Power off ShowPlayPI.
2. Remove the SD card.
3. Insert the SD card into a Windows, macOS or Linux computer.
4. Open the bootfs drive.
5. Open showplaypi.ini with a plain-text editor.
6. Enter the desired address under [BROWSER]:

       URL=http://192.168.1.100

7. Save the file.
8. Safely eject the SD card.
9. Insert the card into ShowPlayPI and power it on.


===============================================================================
System Settings
===============================================================================

[SYSTEM]

HOSTNAME=showplaypi

    Network hostname used for SSH and local discovery.

    The device may be reachable as:

        showplaypi.local


TIMEZONE=Europe/Berlin

    Linux timezone name.

    Examples:

        Europe/Berlin
        Europe/London
        America/New_York
        Asia/Tokyo


NTP_SERVER=192.53.103.108

    NTP server used for automatic clock synchronisation.

    The default IP belongs to a public PTB time server in Germany.
    An IP address works without DNS.


===============================================================================
DHCP Network Configuration
===============================================================================

[NETWORK]
MODE=dhcp
IP=
NETMASK=255.255.255.0
GATEWAY=
DNS1=
DNS2=8.8.8.8

DHCP obtains the IP address, subnet mask, gateway and primary DNS server
automatically.

DNS1 and DNS2 may contain additional DNS servers. They are added to the DNS
servers supplied by DHCP.

The default additional DNS server is Google Public DNS:

    8.8.8.8


===============================================================================
Static Network Configuration
===============================================================================

Example:

[NETWORK]
MODE=static
IP=192.168.1.100
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=192.168.1.1
DNS2=8.8.8.8

IP

    Static IPv4 address assigned to ShowPlayPI.

NETMASK

    Dotted-decimal IPv4 subnet mask.

GATEWAY

    Default gateway. This may remain empty in an isolated local network.

DNS1

    Primary DNS server. This may remain empty when DNS is not required.

DNS2

    Secondary DNS server. This may remain empty.

Invalid network values are rejected. The previously prepared NetworkManager
profile remains unchanged.

A syntactically valid but incorrect static address can make ShowPlayPI
unreachable. In that case, correct showplaypi.ini directly on the SD card.


===============================================================================
Browser Settings
===============================================================================

[BROWSER]

URL=http://192.168.1.100

    Website opened automatically in fullscreen kiosk mode.

    Supported address types:

        http://
        https://
        file://


IGNORE_CERTIFICATE_ERRORS=yes

    Available values:

        yes
        no

    Use yes for local websites with self-signed, expired or otherwise invalid
    HTTPS certificates.


WATCHDOG_ENABLED=yes

    Available values:

        yes
        no

    Enables monitoring of the configured website.


WATCHDOG_INTERVAL=5

    Number of seconds between availability checks.

    Valid range:

        2 to 300 seconds


RELOAD_INTERVAL=0

    Periodically reloads the website.

    Use 0 to disable periodic reloads.

    Examples:

        60      reload every minute
        300     reload every five minutes
        3600    reload every hour

    Dynamic websites and WebSocket applications normally use:

        RELOAD_INTERVAL=0


===============================================================================
Idle Timeout (Kiosk Mode)
===============================================================================

[BROWSER]

IDLE_TIMEOUT=0
IDLE_ACTION=home
IDLE_CLEAR_SESSION=no


IDLE_TIMEOUT=120

    Returns to the start page after this number of seconds without touch,
    mouse or keyboard input. Use 0 to disable.

    Typical values for touch kiosks: 60 to 300 seconds.

    Screens without touch, mouse or keyboard are never reset.


IDLE_ACTION=home

    home      Open the start page again if the visitor has left it.

    reload    Always reload the start page after it was used. This also
              resets web applications whose address does not change.


IDLE_CLEAR_SESSION=yes

    Clears cookies, form data and logins when resetting, so the next visitor
    does not see the data of the previous one. Recommended for public kiosks.


A page shown via OSC (/showplaypi/url) is the start page until the next
restart. The idle timeout can also be changed via OSC (/showplaypi/idle)
until the next restart.


===============================================================================
Website Watchdog
===============================================================================

The website watchdog checks the configured HTTP or HTTPS address.

If the website becomes unavailable, ShowPlayPI continues checking it at the
configured WATCHDOG_INTERVAL.

As soon as the website becomes available again, Chromium reloads the page
automatically.

The watchdog follows normal HTTP redirects.

The following responses are considered reachable:

    HTTP 2xx
    HTTP 3xx
    HTTP 4xx

Network errors and HTTP 5xx responses are considered unavailable.

Local file:// pages are not monitored.


===============================================================================
Display Settings
===============================================================================

[DISPLAY]

MODE=auto
FALLBACK=1920x1080@60
RESOLUTION=1920x1080
REFRESH=60


MODE=auto

    Uses the preferred mode reported by the connected display through EDID.

    If no usable EDID is available, ShowPlayPI uses FALLBACK.


MODE=fixed

    Always uses RESOLUTION and REFRESH.


FALLBACK=1920x1080@60

    Display mode used when no usable EDID is available.


RESOLUTION=1920x1080
REFRESH=60

    Display mode used when MODE=fixed.

The default headless and fallback output is 1920 x 1080 at 60 Hz.


===============================================================================
VNC Remote Access
===============================================================================

[VNC]

ENABLED=yes
PORT=5900


ENABLED

    Available values:

        yes
        no

    Enables or disables VNC remote access.


PORT

    TCP port used by the VNC server.

    Default:

        5900

Connect with a VNC viewer using:

    showplaypi.local:5900

or the current IP address:

    192.168.1.100:5900

VNC displays the actual Chromium kiosk session shown on the HDMI output.


===============================================================================
Automatic Recovery
===============================================================================

ShowPlayPI automatically recovers from:

    Chromium termination or crash
    Xorg termination or crash
    VNC server termination or crash
    temporary website failure
    temporary network interruption

Chromium and the graphical session restart automatically when required.

A VNC connection may disconnect briefly while Xorg restarts. Reconnect after
a few seconds.


===============================================================================
Troubleshooting
===============================================================================

The setup page appears instead of the configured website:

    Check the URL value in the [BROWSER] section.
    Make sure the address starts with http://, https:// or file://.


ShowPlayPI is not reachable after configuring a static IP:

    Power off ShowPlayPI.
    Remove the SD card.
    Open showplaypi.ini.
    Correct the [NETWORK] section or set MODE=dhcp.


A website does not return after a server outage:

    Make sure WATCHDOG_ENABLED=yes.
    Check that WATCHDOG_INTERVAL is between 2 and 300.


VNC does not connect:

    Make sure ENABLED=yes in the [VNC] section.
    Check the configured VNC port.
    Make sure the computer and ShowPlayPI can reach each other.


===============================================================================
Important Notes
===============================================================================

Do not rename section names or setting names.

MODE exists in both [NETWORK] and [DISPLAY]. Always edit the correct section.

Use a plain-text editor and save showplaypi.ini as UTF-8.

Do not use word-processing applications such as Microsoft Word.

Always safely eject the SD card before removing it from a computer.

ShowPlayPI Configuration Guide
===============================================================================
