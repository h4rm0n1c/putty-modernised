#!/bin/sh
# OSC52 manual test helper for h4rm0n1c PuTTY fork.
# Run these commands from a shell inside the rebuilt PuTTY session.
set -eu

send_osc52() {
    label="$1"
    text="$2"
    payload="$(printf '%s' "$text" | base64 | tr -d '\n')"
    printf 'Sending: %s\n' "$label"
    printf '\033]52;c;%s\007' "$payload"
    printf ' ... done\n'
}

send_osc52_st() {
    label="$1"
    text="$2"
    payload="$(printf '%s' "$text" | base64 | tr -d '\n')"
    printf 'Sending: %s (ST terminator)\n' "$label"
    printf '\033]52;c;%s\033\\' "$payload"
    printf ' ... done\n'
}

echo "=== OSC52 Manual Tests ==="
echo "Check clipboard contents after each test."
echo ""

send_osc52 "basic" "hello from OSC52"
echo "  -> clipboard should contain: hello from OSC52"
echo ""

send_osc52 "unicode" "OSC52 works -- clipboard goblin contained."
echo "  -> clipboard should contain: OSC52 works -- clipboard goblin contained."
echo ""

send_osc52_st "ST terminator" "OSC52 ST terminator works"
echo "  -> clipboard should contain: OSC52 ST terminator works"
echo ""

echo "=== Empty selector test ==="
payload="$(printf '%s' "empty target works" | base64 | tr -d '\n')"
printf '\033]52;;%s\007' "$payload"
echo "  done."
echo "  -> clipboard should contain: empty target works"
echo ""

echo "=== Query rejection test ==="
echo "Sending query (should do nothing):"
printf '\033]52;c;?\007'
printf '\033]52;c;?\033\\'
echo "  done."
echo "  -> clipboard must NOT change"
echo ""

echo "=== Malformed base64 test ==="
echo "Sending invalid base64 (should do nothing):"
printf '\033]52;c;not-valid-base64!!!\007'
printf '\033]52;c;AAAA=\007'
printf '\033]52;c;====\007'
printf '\033]52;c;A\007'
echo "  done."
echo "  -> clipboard must NOT change, no crash"
echo ""

echo "=== Unsupported target test ==="
send_osc52 "primary (p)" "primary selection target"
echo "  -> clipboard must NOT change"
send_osc52 "selection (s)" "selection target"
echo "  -> clipboard must NOT change"
send_osc52 "cutbuf0 (0)" "cut buffer 0"
echo "  -> clipboard must NOT change"
echo ""
