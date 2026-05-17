#!/bin/sh
# OSC8 manual test helper for h4rm0n1c PuTTY fork.
# Run these commands from a shell inside the rebuilt PuTTY session.
set -eu

send_osc8() {
    label="$1"
    id="$2"
    url="$3"
    if [ -z "$id" ]; then
        printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$url" "$label"
    else
        printf '\033]8;id=%s;%s\033\\%s\033]8;;\033\\' "$id" "$url" "$label"
    fi
}

echo "=== OSC8 Manual Tests ==="
echo "Ctrl+LeftClick on each link to test."
echo ""

echo "--- Test 1: Basic hyperlink ---"
printf 'Basic link: '
send_osc8 "basic link" "" "https://example.com"
printf '\n'

echo "--- Test 2: Hyperlink with id= ---"
printf 'id= link: '
send_osc8 "id link" "myid" "https://example.com/with-id"
printf '\n'

echo "--- Test 3: file:// must NOT open ---"
printf 'Blocked file link: '
send_osc8 "file link" "" "file:///etc/passwd"
printf '\n'

echo "--- Test 4: Link state clears after OSC8 ; ; ---"
printf 'Clear test linked part: '
send_osc8 "before clear" "" "https://example.com/before"
printf '\nClear test plain text: THIS text does NOT have a hyperlink\n'

echo "--- Test 5: Multiple links on same line ---"
printf 'Multiple: '
send_osc8 "[first]" "" "https://example.com/first"
printf ' '
send_osc8 "[second]" "" "https://example.com/second"
printf '\n'

echo "--- Test 6: http:// (not https) should also work ---"
printf 'HTTP link: '
send_osc8 "http link" "" "http://example.com"
printf '\n'

echo ""
echo "=== Done ==="
echo "Check that normal click/drag still selects text."
echo "Check that Ctrl+LeftClick on non-link text does nothing."
