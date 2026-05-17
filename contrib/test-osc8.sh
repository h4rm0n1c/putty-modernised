#!/bin/sh
# OSC8 manual test helper for h4rm0n1c PuTTY fork.
# Run these commands from a shell inside the rebuilt PuTTY session.
set -eu

send_osc8() {
    label="$1"
    id="$2"
    url="$3"
    printf 'Sending: %s\n' "$label"
    if [ -z "$id" ]; then
        printf '\033]8;;%s\033\\' "$url"
    else
        printf '\033]8;id=%s;%s\033\\' "$id" "$url"
    fi
    printf ' ... done\n'
}

clear_osc8() {
    printf '\033]8;;\033\\'
}

echo "=== OSC8 Manual Tests ==="
echo "Ctrl+LeftClick on each link to test."
echo ""

echo "--- Test 1: Basic hyperlink ---"
send_osc8 "basic link" "" "https://example.com"
echo "  HOVER over 'basic link' text (no visual feedback yet)"
echo "  Ctrl+LeftClick -> should open https://example.com"
clear_osc8
echo ""

echo "--- Test 2: Hyperlink with id= ---"
send_osc8 "id link" "myid" "https://example.com/with-id"
echo "  Ctrl+LeftClick -> should open https://example.com/with-id"
clear_osc8
echo ""

echo "--- Test 3: file:// must NOT open ---"
send_osc8 "file link" "" "file:///etc/passwd"
echo "  Ctrl+LeftClick -> must do NOTHING (security)"
clear_osc8
echo ""

echo "--- Test 4: Link state clears after OSC8 ; ; ---"
send_osc8 "before clear" "" "https://example.com/before"
echo "  THIS text has a hyperlink"
clear_osc8
echo "  THIS text does NOT have a hyperlink"
echo "  Ctrl+LeftClick on 'THIS text does NOT' -> must do nothing"
echo ""

echo "--- Test 5: Multiple links on same line ---"
send_osc8 "first" "" "https://example.com/first"
echo -n "  [first] "
clear_osc8
send_osc8 "second" "" "https://example.com/second"
echo "[second]"
clear_osc8
echo "  Ctrl+LeftClick on [first] -> opens /first"
echo "  Ctrl+LeftClick on [second] -> opens /second"
echo ""

echo "--- Test 6: http:// (not https) should also work ---"
send_osc8 "http link" "" "http://example.com"
echo "  Ctrl+LeftClick -> should open http://example.com (non-https)"
clear_osc8
echo ""

echo "=== Done ==="
echo "Check that normal click/drag still selects text."
echo "Check that Ctrl+LeftClick on non-link text does nothing."
