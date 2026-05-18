# PuTTY Modernised Fork

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![PuTTY fork](https://img.shields.io/badge/PuTTY-fork-blue)
![OSC52](https://img.shields.io/badge/OSC52-write--only-green)
![URLs](https://img.shields.io/badge/clickable-visible%20URLs-green)
![OSC8](https://img.shields.io/badge/OSC8-none-lightgrey)

A Windows-focused PuTTY fork with quality-of-life features for coding-agent,
remote TUI, Stream Deck, and AutoHotkey workflows.

This fork keeps PuTTY's normal terminal behaviour, but adds the practical
pieces modern coding-agent workflows expect:

- **OSC52 clipboard write support** &mdash; remote programs can set your local
  Windows clipboard.
- **Clickable visible http/https URLs** &mdash; hover for a hand cursor and
  tooltip, Ctrl+LeftClick to open.
- **F13-F24 ignore behaviour** &mdash; stops PuTTY from typing unwanted input
  when those keys are used for out-of-band hotkeys.

## Feature summary

| Feature | What it does | Why it matters |
|---------|-------------|----------------|
| OSC52 clipboard write support | Lets remote terminal apps write to the local Windows clipboard | Useful for OpenCode, coding agents, and remote TUIs |
| Clickable visible URLs | Underlines visible http/https URLs and opens them with Ctrl+LeftClick | OAuth/device-login links and long wrapped URLs become clickable |
| Right-click paste | Plain right-click pastes the Windows clipboard into the remote session via PuTTY's normal paste path | Complements OSC52 copy-out (select/drag copies out, right-click pastes back) |
| Ignore F13-F24 | Stops PuTTY from typing escape/input for F13-F24 | Plays nicely with Stream Deck, AutoHotkey, push-to-talk, and out-of-band hotkeys |

## Why this fork exists

Modern coding-agent workflows often run inside SSH sessions or terminal
TUIs. Two things matter immediately:

1. Remote tools need to copy useful text back to the local machine.
2. Users need to open long auth/OAuth/device-login URLs without manually
   selecting wrapped terminal text.

**OSC52** handles terminal-to-local clipboard writes.
**Clickable visible URLs** handle auth links and other visible http/https
links.

This fork deliberately avoids hidden-target hyperlink behaviour. If a URL
opens, the URL text was visible in the terminal.

## Security model

- **OSC52 support is write-only.** Clipboard read/query is intentionally
  not implemented. Remote programs can request clipboard writes only when
  OSC52 is explicitly enabled in Settings.
- **Clickable URLs are visible-text only.** OSC8 hidden-target hyperlinks
  are deliberately not supported. `file://` and custom URI schemes are not
  opened. If a URL opens, the URL text was visible in the terminal.

## OSC52 clipboard support

OSC52 clipboard writes let programs on the remote host set your local
Windows clipboard by emitting OSC 52 escape sequences.

**Settings:** Terminal &rarr; Features &rarr; "Allow remote clipboard writes
(OSC 52)"

**Behaviour:**

- Reads and decodes base64-encoded clipboard content from the remote host.
- The payload is decoded as UTF-8 and written to the Windows system
  clipboard.
- Clipboard **read/query** (`OSC 52 ; c ; ?`) is intentionally **not
  implemented**, so the remote host cannot request your local clipboard
  contents.
- Only the system clipboard target (`c`) and empty target are accepted.
  Primary selection and cut-buffer targets are silently ignored.
- Default is enabled for convenience. Leave disabled for untrusted hosts if
  you do not want remote programs to modify your local clipboard.
- Tested with OpenCode: selecting text in the remote TUI emits OSC52 on
  mouse-up and updates the local Windows clipboard. Paste back into the
   remote session uses the normal user-triggered PuTTY paste path
   (Shift+Insert or plain right-click). Ctrl+RightClick opens the
   PuTTY context menu.

**Test script:**

```sh
sh contrib/test-osc52.sh
```

**Attribution:** OSC52 support in this fork was implemented by studying the
behaviour and structure of existing open-source terminal emulators,
especially mintty, Alacritty, WezTerm, and kitty. The implementation is
original to this fork and reuses PuTTY's existing parser and clipboard
abstractions, but the design deliberately follows established
terminal-emulator behaviour for OSC52 clipboard handling.

## Clickable visible URL support

This fork detects visible `http://` and `https://` URLs in terminal output.

**Behaviour:**

- URLs are underlined in the terminal.
- Hovering over a URL changes the mouse cursor to a hand.
- A tooltip appears near the cursor: *Ctrl + Click to Open Link*
- Ctrl+LeftClick opens the URL with your default browser.
- Long soft-wrapped URLs are reconstructed across PuTTY soft wraps.
- UTF-8 / Unicode / IRI URL text is preserved and opened through the
  Windows wide-character API.
- Only URLs visibly present in the terminal are opened.
- OSC8 hidden-target hyperlinks are deliberately not supported.
- `file://` and custom URI schemes are not opened.

**Security:** This fork intentionally implements visible URL clicking, not
OSC8 hidden target links. The visible terminal URL is the authority.

**Test script:**

```sh
sh contrib/test-clickable-url.sh
```

## F13-F24 hotkey interoperability

F13-F24 virtual key codes received on Windows are silently ignored by
PuTTY's input handling. This is useful when F13-F24 are mapped to hotkeys
in Stream Deck, AutoHotkey, push-to-talk, or other out-of-band
applications. Without this change, PuTTY would type unwanted input when
those keys are pressed while the PuTTY window has focus.

## Build

Local build command for this fork (cross-compile from Linux with MinGW):

```sh
cmake --build build-win64 --target putty
```

Expected output:

```
build-win64/putty.exe
```

This repository keeps upstream PuTTY's CMake build system. See the upstream
PuTTY section below for general build instructions.

## Testing

Manual feature tests can be run inside a PuTTY session:

```sh
sh contrib/test-osc52.sh
sh contrib/test-clickable-url.sh
```

## Releases

Tagged releases are built by GitHub Actions. Release assets include `putty.exe`,
a zip package, SHA256 hashes, and a Defender scan log when available.

Hashes prove artifact integrity, not malware innocence.

## Upstream PuTTY

<details>
<summary>Upstream PuTTY source notes</summary>

This is a fork of [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/),
a free Windows and Unix Telnet and SSH client.

PuTTY is built using [CMake](https://cmake.org/). To compile in the
simplest way (on any of Linux, Windows or Mac), the general method is:

```sh
cmake .
cmake --build .
```

These commands will expect to find a usable compile toolchain on your
path. So if you're building on Windows with MSVC, you'll need to make
sure that the MSVC compiler (cl.exe) is on your path, by running one
of the 'vcvars32.bat' setup scripts provided with the tools. Then the
cmake commands above should work.

To install in the simplest way on Linux or Mac:

```sh
cmake --build . --target install
```

On Unix, pterm would like to be setuid or setgid, as appropriate, to
permit it to write records of user logins to `/var/run/utmp` and
`/var/log/wtmp`. (Of course it will not use this privilege for
anything else, and in particular it will drop all privileges before
starting up complex subsystems like GTK.) The cmake install step
doesn't attempt to add these privileges, so if you want user login
recording to work, you should manually ch{own,grp} and chmod the
pterm binary yourself after installation. If you don't do this,
pterm will still work, but not update the user login databases.

Documentation (in various formats including Windows Help and Unix
`man` pages) is built from the Halibut (`.but') files in the `doc`
subdirectory. If you aren't using one of our source snapshots,
you'll need to do this yourself. Halibut can be found at
<https://www.chiark.greenend.org.uk/~sgtatham/halibut/>.

The PuTTY home web site is:

    https://www.chiark.greenend.org.uk/~sgtatham/putty/

See the file [LICENCE](LICENCE) for the licence conditions.

</details>
