# PuTTY Fork OSC52 Clipboard Support Plan

## Purpose

Add practical, safe OSC52 clipboard write support to the h4rm0n1c PuTTY fork.

This is a tiny modernisation pass, not a rewrite of PuTTY.

The first goal is simple:

- Allow remote terminal programs to copy text into the local Windows clipboard using OSC52.
- Keep the existing F13-F24 behaviour intact.
- Reuse PuTTY's existing terminal parser and clipboard backend.
- Avoid adding broad new terminal-emulator complexity.

This document is written for a coding agent working in the existing PuTTY fork.

## Repository

Target repo:

    https://github.com/h4rm0n1c/putty-ignorehighfkeys

Known local checkout:

    ~/putty

Known branch:

    h4rm0n1c/ignorehighfkeys

Known build directory:

    ~/putty/build-win64

Known rebuild command:

    cd ~/putty
    cmake --build build-win64 --target putty

Output binary:

    ~/putty/build-win64/putty.exe

## High-level implementation summary

PuTTY already has most of the infrastructure needed:

- OSC parser state exists in `terminal/terminal.h`.
- OSC parsing and dispatch already happen in `terminal/terminal.c`.
- `do_osc()` already handles several OSC commands.
- There is no existing `case 52` handler.
- The terminal/window abstraction already exposes clipboard writing through `TermWin.clip_write`.
- The Windows frontend already implements clipboard writing using the Win32 clipboard.
- Existing base64 helpers exist in the repo.

So the feature should be added as a narrow path:

    OSC parser
      -> do_osc()
        -> case 52
          -> parse OSC52 target and base64 payload
          -> enforce policy
          -> base64 decode
          -> UTF-8 decode / sanitise
          -> call existing clipboard write path

Do not add a separate Windows clipboard implementation unless absolutely necessary.

## Donor implementations and attribution

This implementation should use existing open-source terminal emulators as behavioural references.

Do not copy large blocks of donor source code.

Borrow the shape, semantics, and pitfalls.

### mintty

Project:

    https://github.com/mintty/mintty

Relevant files:

    src/termout.c
    src/base64.c
    src/base64.h

Useful pattern:

- `OSC 52` is handled in a small dedicated function.
- It parses the clipboard selector before the second semicolon.
- Missing selector effectively defaults to clipboard.
- `?` is treated as clipboard query/read.
- Write requires a config flag.
- Read/query requires a separate config flag.
- Payload is base64-decoded.
- Decoded text is sent to the existing Windows clipboard helper.

Why it matters:

mintty is the closest structural donor because it is C and Windows-terminal-adjacent.

For PuTTY, mintty's useful lesson is:

    Keep OSC52 as a small parser and policy gate, then call the terminal's existing clipboard path.

### Alacritty

Project:

    https://github.com/alacritty/alacritty

Relevant files:

    alacritty_terminal/src/term/mod.rs
    alacritty_terminal/src/event.rs
    alacritty/src/config/terminal.rs

Useful pattern:

Alacritty exposes a clear OSC52 policy enum:

    Disabled
    OnlyCopy
    OnlyPaste
    CopyPaste

Useful behaviour:

- Clipboard write is allowed only in `OnlyCopy` or `CopyPaste`.
- Clipboard read is allowed only in `OnlyPaste` or `CopyPaste`.
- `c` maps to clipboard.
- `p` and `s` map to selection on platforms that support it.
- Payload must be valid base64.
- Decoded payload must be valid UTF-8.
- Terminal emulation emits a clipboard event rather than directly owning every platform clipboard detail.

Why it matters:

Alacritty provides the cleanest safety model.

For PuTTY, the useful lesson is:

    Read and write permissions must be separate. Copy/write is useful. Paste/read is dangerous.

### WezTerm

Project:

    https://github.com/wezterm/wezterm

Relevant files:

    wezterm-escape-parser/src/osc.rs
    term/src/terminalstate/performer.rs

Useful pattern:

WezTerm parses OSC52 as selection manipulation, with clear semantic variants:

    ClearSelection(selection)
    QuerySelection(selection)
    SetSelection(selection, text)

Useful behaviour:

- OSC command `52` maps to selection manipulation.
- Selectors are parsed as a set of destinations.
- `c` means clipboard.
- `p` means primary selection.
- `s` means select.
- `0` through `9` mean cut buffers.
- `?` means query/read.
- Base64 payload is decoded before being turned into text.

Why it matters:

WezTerm provides the cleanest parser model.

For PuTTY, the useful lesson is:

    Keep OSC52 grammar explicit: set, query, and clear are different operations.

### kitty

Project:

    https://github.com/kovidgoyal/kitty

Relevant files:

    kitty/clipboard.py

Useful pattern:

kitty has a much more advanced clipboard request manager.

Useful behaviour:

- Distinguishes clipboard and primary selection.
- Supports read and write requests.
- Has permission handling.
- Handles partial or streamed OSC52 payloads.
- Uses a streaming base64 decoder.
- Enforces maximum clipboard size.
- Uses temporary storage for large transfers.
- Allows per-session permission decisions.

Why it matters:

kitty is the best long-term robustness reference.

For PuTTY first pass, do not copy kitty's complexity.

Borrow later if needed:

- Size caps.
- Streaming decode.
- Prompt/permission model.
- Session allow/deny state.

## Attribution requirement

Add an attribution note in the fork documentation.

Suggested wording:

    OSC52 support in this fork was implemented by studying the behaviour and structure of existing open-source terminal emulators, especially mintty, Alacritty, WezTerm, and kitty. The implementation is original to this fork and reuses PuTTY's existing parser and clipboard abstractions, but the design deliberately follows established terminal-emulator behaviour for OSC52 clipboard handling.

Also mention:

    Thanks to the maintainers of mintty, Alacritty, WezTerm, and kitty for their open implementations of OSC52 handling and related clipboard policy models.

Do not imply their code was copied unless it actually was.

If any donor code is copied directly, stop and check licence compatibility first.

## Non-goals for first pass

Do not implement these in the first pass:

- OSC52 clipboard read/query support.
- `OSC 52 ; c ; ?` returning local clipboard contents.
- Primary selection support.
- Cut buffer support.
- MIME clipboard support.
- kitty OSC 5522 support.
- Permission prompt UI.
- Session password/OTP permission model.
- Streaming clipboard transfers.
- A new Win32 clipboard backend.
- Cross-platform Unix frontend support.
- Broad terminal emulator refactors.
- A new configuration UI page unless needed.

First pass must be write-only.

## First-pass supported OSC52 forms

Support these:

    ESC ] 52 ; c ; BASE64 BEL
    ESC ] 52 ; c ; BASE64 ESC \
    ESC ] 52 ; ; BASE64 BEL
    ESC ] 52 ; ; BASE64 ESC \

Meaning:

- `c` means system clipboard.
- Empty selector is accepted as system clipboard for compatibility.
- Payload is base64 encoded UTF-8 text.

Reject or ignore these in first pass:

    ESC ] 52 ; c ; ? BEL
    ESC ] 52 ; p ; BASE64 BEL
    ESC ] 52 ; s ; BASE64 BEL
    ESC ] 52 ; 0 ; BASE64 BEL
    ESC ] 52 ; 1 ; BASE64 BEL
    ESC ] 52 ; 2 ; BASE64 BEL
    ESC ] 52 ; 3 ; BASE64 BEL
    ESC ] 52 ; 4 ; BASE64 BEL
    ESC ] 52 ; 5 ; BASE64 BEL
    ESC ] 52 ; 6 ; BASE64 BEL
    ESC ] 52 ; 7 ; BASE64 BEL
    ESC ] 52 ; 8 ; BASE64 BEL
    ESC ] 52 ; 9 ; BASE64 BEL

The unsupported forms should fail silently or log to PuTTY's event log if that is easy and consistent with existing style.

Do not beep.

Do not display garbage in the terminal.

Do not send an error response to the remote host in first pass.

## Security policy

OSC52 writes allow a remote host to modify the user's local clipboard.

That is useful but still security-sensitive.

OSC52 reads would expose the user's local clipboard to the remote host.

That is much more dangerous.

Therefore:

- Clipboard write may be allowed by config.
- Clipboard read/query must remain disabled in first pass.
- Read/query support must not be accidentally implemented as a side effect.
- If query payload is `?`, return immediately.
- Do not send clipboard content back to the PTY.

Recommended first-pass config:

    OSC52Clipboard = copy

Better long-term config:

    off
    copy
    paste
    copypaste

Where:

- `off`: ignore OSC52 completely.
- `copy`: allow remote program to write local clipboard.
- `paste`: allow remote program to read local clipboard. Do not implement in first pass.
- `copypaste`: allow both. Do not implement in first pass.

For the personal fork, default may be `copy`.

For anything intended for broader release, safer default is `off` or `copy` with documentation.

## Size limits

PuTTY currently has a small OSC string buffer.

That is not enough for useful OSC52 copies.

First-pass options:

### Acceptable quick hack

Increase OSC string capacity to a practical hard limit.

Suggested encoded OSC payload cap:

    262144 bytes

That gives roughly 192 KiB decoded clipboard text.

This is enough for normal terminal/editor use without making accidental huge clipboard writes easy.

### Better follow-up

Replace fixed OSC string storage with a dynamic buffer plus hard cap.

Suggested decoded cap:

    256 KiB initially

Suggested encoded cap:

    350 KiB initially

Do not allow unbounded OSC strings.

Do not allocate based entirely on remote-controlled size without a cap.

Do not stream arbitrarily large payloads in first pass.

## Base64 constraints

Use existing PuTTY base64 decode helpers if practical.

Do not write a new base64 decoder unless the existing helpers cannot be used cleanly.

Rules:

- Accept standard base64.
- Ignore or reject malformed base64.
- Do not partially copy malformed payloads.
- Do not crash on malformed padding.
- Do not read past buffer end.
- Do not assume the payload is NUL-terminated unless explicitly copied into a NUL-terminated buffer.
- After decoding, validate or convert as UTF-8 text.

If the existing decoder returns binary bytes:

- Treat bytes as UTF-8.
- Invalid UTF-8 should be rejected or replaced consistently with existing PuTTY text conversion style.
- For first pass, rejection is safer than lossy conversion.

## Text encoding constraints

OSC52 payload should be treated as UTF-8 text.

Windows clipboard write path should receive Unicode text through PuTTY's existing clipboard abstraction.

Do not write ANSI-only clipboard data from OSC52.

Do not use the old `CF_TEXT` path as the primary output.

Expected data path:

    base64 bytes
      -> decoded UTF-8 bytes
      -> Unicode/wchar text
      -> TermWin.clip_write
      -> Windows frontend clipboard writer
      -> CF_UNICODETEXT

If PuTTY's `clip_write` expects a specific internal text format, match that format.

Do not bypass `clip_write` without checking the existing selection-copy code.

## Implementation file map

Likely files to inspect or modify:

    terminal/terminal.c
    terminal/terminal.h
    putty.h
    conf.h
    config.c
    windows/window.c
    utils/base64_decode.c
    utils/base64_decode_atom.c
    misc.h

Likely existing functions/concepts to inspect:

    do_osc
    term_out
    TermWin
    clip_write
    wintw_clip_write
    base64_decode
    base64_decode_atom
    CONF_no_remote_wintitle
    CONF_no_bracketed_paste

Exact names must be verified in the local tree before editing.

Do not guess type signatures.

Use ripgrep first.

Suggested inspection commands:

    cd ~/putty
    rg "do_osc|OSC_STRING|OSC_STR_MAX|osc_string|clip_write|wintw_clip_write|base64_decode|CONF_no_remote_wintitle|CONF_no_bracketed_paste" -n

## Coding-agent constraints

The coding agent must follow these rules:

1. Keep the patch narrow.
2. Do not reformat unrelated code.
3. Do not rename existing functions unless required.
4. Do not change F13-F24 behaviour.
5. Do not change SSH/session behaviour.
6. Do not alter clipboard copy/paste UI behaviour except for OSC52.
7. Do not implement OSC52 read/query in first pass.
8. Do not add dependencies.
9. Do not vendor donor terminal emulator code.
10. Do not perform a broad PuTTY modernisation rewrite.
11. Prefer existing PuTTY helper functions and style.
12. Match PuTTY's allocation and cleanup conventions.
13. Check every allocation failure path.
14. Reject malformed OSC52 quietly.
15. Add simple tests or at least a manual test script.
16. Preserve existing build system.
17. Build with the known local MinGW/Ninja setup.
18. After build, provide exact changed files and exact test commands.

If uncertain, inspect existing PuTTY style and follow it.

Do not invent new architecture.

## Suggested first implementation steps

### Step 1: Inspect current OSC parser

Run:

    cd ~/putty
    rg "OSC_STR_MAX|osc_string|do_osc|SEEN_OSC|OSC_STRING|OSC_MAYBE_ST" terminal -n

Confirm:

- Where OSC payload is buffered.
- How payload length is limited.
- How BEL and ST termination are handled.
- How `do_osc()` receives the final payload.

### Step 2: Inspect clipboard abstraction

Run:

    cd ~/putty
    rg "clip_write|Clipboard|OpenClipboard|CF_UNICODETEXT|write_clip|wintw_clip" -n

Confirm:

- Function signature for `TermWin.clip_write`.
- Expected input text format.
- How normal selection copy reaches the Windows clipboard.

### Step 3: Inspect base64 helpers

Run:

    cd ~/putty
    rg "base64_decode|base64_decode_atom|base64" -n utils misc.h

Confirm:

- Function signatures.
- Whether decoder accepts NUL-terminated strings or length-delimited buffers.
- Whether decoder allocates output or writes into a caller buffer.
- Failure return convention.

### Step 4: Add config flag or mode

Minimal first pass:

    CONF_osc52_clipboard

Value model options:

    0 = off
    1 = copy

Long-term value model:

    0 = off
    1 = copy
    2 = paste
    3 = copypaste

In first pass, only `copy` should do anything.

Do not expose `paste` or `copypaste` in UI unless read support exists.

### Step 5: Add parser function

Add a small helper near `do_osc()` in `terminal/terminal.c`.

Suggested internal shape:

    static void do_osc52_clipboard(Terminal *term, const char *payload)

or match local style if `Terminal` is not the visible type name there.

Behaviour:

1. Check config allows copy.
2. Split payload at first semicolon.
3. `target = before first semicolon`.
4. `data = after first semicolon`.
5. If no semicolon, return.
6. If data is `?`, return.
7. If target is empty, accept.
8. If target contains `c`, accept.
9. Otherwise return.
10. Enforce encoded size cap.
11. Base64 decode.
12. Reject invalid decode.
13. Convert UTF-8 to PuTTY clipboard text format.
14. Call existing clipboard writer.
15. Free all allocations.

### Step 6: Add `case 52` to `do_osc()`

Inside `do_osc()`:

    case 52:
        do_osc52_clipboard(term, osc_payload);
        break;

Use actual local variable names.

Do not disturb existing OSC handlers.

### Step 7: Increase or modernise OSC buffer

First pass can increase fixed cap.

Better pass can use dynamic buffer.

If increasing fixed cap:

- Keep cap clearly named.
- Add a comment explaining OSC52 needs larger payloads.
- Do not make it unbounded.

Suggested comment:

    OSC52 clipboard writes need more space than title-setting OSCs.
    Keep this capped because OSC payload is remote-controlled.

### Step 8: Add documentation

Update README or add a fork-specific doc.

Mention:

- OSC52 write support.
- Read/query is deliberately not supported.
- This allows remote programs to set the local clipboard.
- Attribution to mintty, Alacritty, WezTerm, and kitty as behavioural references.

### Step 9: Build

Run:

    cd ~/putty
    cmake --build build-win64 --target putty

Expected output:

    build-win64/putty.exe

### Step 10: Manual tests

From a remote shell inside the rebuilt PuTTY:

    printf '\033]52;c;%s\007' "$(printf 'hello from OSC52' | base64 | tr -d '\n')"

Expected:

- Windows clipboard contains:

    hello from OSC52

UTF-8 test:

    python3 - <<'PY'
    import base64, sys
    text = "OSC52 works — clipboard goblin contained.\n"
    payload = base64.b64encode(text.encode("utf-8")).decode("ascii")
    sys.stdout.write(f"\x1b]52;c;{payload}\x07")
    sys.stdout.flush()
    PY

Expected:

- Windows clipboard contains the exact Unicode text.

ST terminator test:

    python3 - <<'PY'
    import base64, sys
    text = "OSC52 ST terminator works\n"
    payload = base64.b64encode(text.encode()).decode()
    sys.stdout.write(f"\x1b]52;c;{payload}\x1b\\")
    sys.stdout.flush()
    PY

Expected:

- Windows clipboard contains the exact text.

Query rejection test:

    printf '\033]52;c;?\007'

Expected:

- PuTTY must not paste local clipboard contents into the remote shell.
- PuTTY must not send clipboard content back to the PTY.
- Clipboard should remain unchanged.

Malformed base64 test:

    printf '\033]52;c;not-valid-base64!!!\007'

Expected:

- No crash.
- No visible terminal garbage.
- Clipboard unchanged.

Unsupported target test:

    printf '\033]52;p;%s\007' "$(printf 'primary unsupported' | base64 | tr -d '\n')"

Expected:

- No crash.
- Clipboard unchanged in first pass.

## Acceptance criteria

First pass is successful when:

- `putty.exe` builds with the existing `build-win64` setup.
- Existing F13-F24 suppression still works.
- `OSC 52 ; c ; payload BEL` sets Windows clipboard.
- `OSC 52 ; c ; payload ST` sets Windows clipboard.
- Empty selector works as clipboard.
- UTF-8 text survives correctly.
- Invalid base64 does not crash.
- Unsupported selectors do nothing.
- `OSC 52 ; c ; ?` does not leak clipboard contents.
- No new external dependencies are added.
- Attribution note is present.

## Stretch goals after first pass

Do these only after write-only support is stable:

1. Add UI option for OSC52 clipboard writes.
2. Add event log messages for accepted/rejected OSC52 writes.
3. Replace fixed OSC buffer with capped dynamic buffer.
4. Add a small regression test around OSC parsing.
5. Support primary selection for Unix frontend if desired.
6. Add prompt-on-first-use permission mode.
7. Add read/query support only behind an explicit dangerous setting.
8. Add feature/capability reporting if useful.

## Strong warning about read/query support

OSC52 query support is dangerous because it lets a remote host ask for the local clipboard.

Do not implement this casually.

A safe read/query implementation would need at least:

- Explicit config.
- Default off.
- Ideally prompt-on-use.
- Visible warning text.
- Session allow/deny state.
- Tests proving denied reads return nothing.

Until that exists, `OSC 52 ; c ; ?` must be ignored.

## Minimal design target

The first patch should feel boring.

Ideal patch size:

- One small helper for OSC52 parsing/handling.
- One `case 52` in `do_osc()`.
- One config flag or constant gate.
- One buffer size adjustment or capped dynamic buffer.
- One README/doc note.

If the patch starts touching unrelated systems, stop.

That is scope creep wearing a fake moustache.

## Final implementation principle

Use PuTTY's existing architecture.

Use donor terminals as behavioural references.

Implement only the narrow useful path first.

Keep read/query disabled.

Keep the patch small enough that Future Harrison can understand it without summoning an archaeology team again.

