# ShowPlayPI

**Turn a Raspberry Pi into a full-screen web display for events, trade fairs and control rooms –
without any Raspberry Pi knowledge.**

ShowPlayPI starts straight into a full-screen browser and shows the website or local page you choose:
a stage timer, a countdown, a dashboard, a schedule, a sign. You configure it with a simple Windows program
or a text file – no Linux, no command line.

> **Status: beta.** ShowPlayPI is in active development. The current version is `1.0.0-beta.1`;
> the first stable release will be 1.0.0. See [known issues](#known-issues) before using it at a show.
> More modes (video player, Ontime, Bitfocus Companion) are planned – see the [roadmap](ROADMAP.md).

## Features

- **Full-screen kiosk browser** (Chromium) for websites (`http://`, `https://`) and local pages (`file://`)
- **Works without a display** – always outputs a 1080p60 signal (configurable), so video mixers and
  projectors stay locked
- **Kiosk-ready:** returns to the start page after a configurable time without touch input and can clear
  cookies and logins for the next visitor
- **Self-healing:** if the website goes down, ShowPlayPI keeps checking and reloads the page as soon as it
  is back; the browser restarts automatically after a crash
- **Easy configuration:** connect the Pi via USB-C and use the Windows configurator on the virtual USB
  drive, or edit a plain text file on the SD card
- **Remote control via OSC**, e.g. from Bitfocus Companion: change URL, reload, black out the picture
  without losing the HDMI signal ([OSC reference](docs/OSC.md))
- **VNC** to see exactly what is on the screen
- Network: DHCP or static IP, hostname, time zone, time server

## What you need

- **Raspberry Pi 5 or Raspberry Pi 4 Model B** (Pi 5 support is still being tested in the beta)
- A microSD card, **16 GB or larger**
- A suitable power supply (Pi 5: 27 W USB-C, Pi 4: 15 W USB-C) – **or Power over Ethernet**: the official
  PoE HATs work on both models, **PoE+ is recommended** (a single network cable for power and data)
- A micro-HDMI to HDMI cable – use the HDMI port **next to the USB-C power socket** (see
  [known issues](#known-issues))
- A network cable if the page comes from the network

## Quick start

1. **Download** the latest image `ShowPlayPI-<version>.img.xz` from the
   [releases page](https://github.com/robertskiba/ShowPlayPI/releases).
2. **Write it to the SD card** with the [Raspberry Pi Imager](https://www.raspberrypi.com/software/):
   *Choose Device* → your Pi model, *Choose OS* → *Use custom* → the downloaded file,
   *Choose Storage* → your SD card.
   When the Imager asks whether to apply **OS customisation settings, choose "No"** – ShowPlayPI brings its
   own configuration, and customisation from the Imager would interfere with it.
3. **Configure** (optional, can also be done later with the configurator via USB-C, see below):
   open the SD card on your computer – a drive called `bootfs` appears – and edit `showplaypi.ini`.
   The most important setting is the page to show:
   ```ini
   [BROWSER]
   URL=http://192.168.1.100:4001/timer/
   ```
4. **Start:** insert the card into the Pi, connect HDMI and network, then power it on.
   The first start takes a little longer, because the Pi prepares the SD card.

Without a configured URL, ShowPlayPI shows its **setup page** with the device name, IP address and
instructions.

## Configuration

All settings live in one file: **`showplaypi.ini`**. There are two ways to change it.

### 1. Via USB-C with the configurator (recommended)

Connect the Pi's **USB-C port** to a computer with a USB cable. A drive called **`SHOWPLAYPI`** appears,
containing `showplaypi.ini`, a README and **`ShowPlayPI-Configurator.exe`**.

- **Windows:** start `ShowPlayPI-Configurator.exe` from the drive. It shows all settings in a clear window,
  checks your input and saves the file on the drive.
- **Mac/Linux:** edit `showplaypi.ini` on the drive with a plain-text editor
  (a web interface for all systems is planned).

Eject the drive and restart the Pi – the changes are applied on the next start.

In this setup the Pi is powered by the computer's USB port. This works best with a Pi 4 on a powerful
USB-C port; with weak ports the Pi may not start reliably (still being tested).

### 2. On the SD card with any text editor

Power the Pi off, insert the SD card into a computer and edit `showplaypi.ini` on the `bootfs` drive with
a plain-text editor (Notepad, TextEdit – **not** Word). Lines starting with `;` are comments.
A detailed description of every setting is in `README.txt` on the same drive.

### Settings overview

| Section | Setting | Default | Meaning |
|---|---|---|---|
| `[SYSTEM]` | `HOSTNAME` | `showplaypi` | Device name, reachable as `showplaypi.local` |
| | `TIMEZONE` | `Europe/Berlin` | Time zone |
| | `NTP_SERVER` | `192.53.103.108` | Time server (PTB, Germany) |
| `[NETWORK]` | `MODE` | `dhcp` | `dhcp` or `static` |
| | `IP`, `NETMASK`, `GATEWAY` | – | Only for `MODE=static` |
| | `DNS1`, `DNS2` | –, `8.8.8.8` | Additional DNS servers (optional) |
| `[BROWSER]` | `URL` | – | Page to show (`http://`, `https://`, `file://`) |
| | `IGNORE_CERTIFICATE_ERRORS` | `yes` | Accept self-signed HTTPS certificates |
| | `WATCHDOG_ENABLED` | `yes` | Reload the page when the server is back |
| | `WATCHDOG_INTERVAL` | `5` | Seconds between checks (2–300) |
| | `RELOAD_INTERVAL` | `0` | Reload every n seconds, `0` = off |
| | `IDLE_TIMEOUT` | `0` | Return to the start page after n seconds without touch/mouse/keyboard, `0` = off |
| | `IDLE_ACTION` | `home` | `home` (only if the visitor left the start page) or `reload` (always reset after use) |
| | `IDLE_CLEAR_SESSION` | `no` | Clear cookies, form data and logins on reset (public kiosks) |
| `[DISPLAY]` | `MODE` | `auto` | `auto` (display's preferred mode) or `fixed` |
| | `FALLBACK` | `1920x1080@60` | Output when no display is connected |
| | `RESOLUTION`, `REFRESH` | `1920x1080`, `60` | Used with `MODE=fixed` |
| `[VNC]` | `ENABLED`, `PORT` | `yes`, `5900` | Remote view |
| `[OSC]` | `ENABLED` | `yes` | OSC remote control on UDP port 9000 (changes last until the next restart) |

### Local pages

Put your own HTML pages (with images, scripts, styles) into the **`content`** folder on the `bootfs`
drive and use for example:

```ini
URL=file:///boot/firmware/content/index.html
```

## Remote access

| What | How | Default login |
|---|---|---|
| **OSC** | UDP port 9000, commands such as `/showplaypi/url`, `/showplaypi/blackout` – see [docs/OSC.md](docs/OSC.md) | – |
| **VNC** | any VNC viewer, `showplaypi.local:5900` | password `admin` |
| **SSH** | `ssh admin@showplaypi.local` | user `admin`, password `admin` |

A ready-made **Bitfocus Companion page** (`ShowPlayPI Companion Demo.companionconfig`) is on the `bootfs`
drive and the USB drive – import it into Companion and set the IP of your Pi.

If `showplaypi.local` does not work on your network, use the IP address shown on the setup page.

## Security

ShowPlayPI is built for **isolated event networks** and is deliberately easy to use: the default
passwords are `admin`, and OSC has no authentication. **Do not connect it unchanged to a company network or
the internet.** Options to lock everything down (own passwords, OSC password, disabling SSH, firewall) are
planned – see the [roadmap](ROADMAP.md).

## Known issues

In this beta:

- Only the HDMI port **next to the USB-C socket** is fully supported; both outputs with the same picture
  are planned for 1.0.
- Raspberry Pi 5 support is not fully tested yet.
- Without a network connection the browser may take up to about a minute longer to appear.
- Configuration via USB-C depends on the power the computer's USB port delivers.

## Troubleshooting

| Problem | Solution |
|---|---|
| The setup page appears instead of my page | Check `URL` in `[BROWSER]` – it must start with `http://`, `https://` or `file://`. |
| Not reachable after setting a static IP | Power off, put the SD card into a computer, fix `[NETWORK]` or set `MODE=dhcp`. |
| The page does not come back after a server outage | Make sure `WATCHDOG_ENABLED=yes`. |
| No picture on the display | Use the HDMI port next to USB-C; try `[DISPLAY] MODE=fixed` with a resolution your display supports. |
| `showplaypi.local` is not found | Use the IP address from the setup page; some networks block `.local` names. |

More help: [support@konftools.com](mailto:support@konftools.com)

## More

- [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md) · [OSC reference](docs/OSC.md)
- [Development: build and test ShowPlayPI yourself](docs/DEVELOPMENT.md)
- License: [MIT](LICENSE); the image also contains third-party software under its own licenses –
  see [THIRD-PARTY.md](THIRD-PARTY.md)

---

ShowPlayPI by Robert Skiba · https://konftools.com · support@konftools.com
