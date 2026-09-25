SHOWPLAYPI DRIVE
================

This drive belongs to ShowPlayPI. It holds the configuration and your files.
You can reach it over USB-C, or by inserting the SD card into a card reader.

Contents
--------

showplaypi.ini                 configuration
ShowPlayPI-Configurator.exe    configurator for Windows
HTML                           your own web pages for the browser
                               (URL: file:///media/showplaypi/HTML/index.html)
VIDEO                          videos and still images for the video mode
                               (MODE=video; they play in alphabetical order,
                               subfolders are further playlists;
                               best format: H.265/HEVC)
AUDIO                          jingles for the audio player
AUDIO/LOOP                     background playlist for the audio player
PRESETS                        presets, e.g. for Bitfocus Companion

Configuration
-------------

Edit showplaypi.ini with the ShowPlayPI Configurator (Windows) or with a plain
text editor. The settings are checked and applied at the next start of
ShowPlayPI.

Important
---------

- After saving, the USB cable may be disconnected right away. The Configurator
  confirms when the settings are stored on ShowPlayPI; after saving with a text
  editor, wait two or three seconds. On a Mac, eject the drive in Finder first
  (macOS keeps changes in its own cache for a while).
- Invalid settings are rejected; the previous working configuration stays active.
- Deleting showplaypi.ini resets the configuration to the delivery state at the
  next start. Your files in HTML, VIDEO, AUDIO and PRESETS are kept.
- The configurator, this README and the folders are restored automatically if
  they are deleted.
- Do not format this drive.

Support and downloads
---------------------

https://konftools.com
support@konftools.com
