#!/bin/sh
set -eu

echo "Clickable visible URL tests"
echo ""

echo "Basic URLs (should be underlined and clickable):"
echo "https://example.com"
echo "http://example.com/path?x=1"
echo ""

echo "Scheme-only (should NOT be underlined/clickable):"
echo "http://"
echo "https://"
echo ""

echo "Boundary rejection (should NOT be underlined/clickable):"
echo "xhttp://example.com"
echo "nothttp://example.com"
echo "abchttps://example.com"
echo ""

echo "Wrapped in brackets:"
echo "(https://example.com/wrapped)"
echo "[https://example.com/bracketed]"
echo ""

echo "Balanced parentheses (should keep final ):"
echo "https://en.wikipedia.org/wiki/Foo_(bar)"
echo ""

echo "Extra closers (should trim unbalanced):"
echo "https://example.com/foo))"
echo "https://example.com/foo]]"
echo ""

echo "Trailing punctuation (should be trimmed):"
echo "https://example.com/test."
echo "https://example.com/comma,"
echo "https://example.com/question?"
echo ""

echo "Non-ASCII termination (only ASCII prefix should be clickable):"
echo "https://example.com/über"
echo "https://example.com/path😀tail"
echo ""

echo "Blocked schemes (should NOT be clickable):"
echo "file:///C:/Windows/System32/cmd.exe"
echo "mailto:test@example.com"
echo "ssh://example.com"
echo ""

echo "Non-links (should NOT be underlined/clickable):"
echo "www.example.com"
echo "example.com"
echo "plain text"
echo ""

echo "Expected:"
echo "  Ctrl+LeftClick http:// and https:// URLs opens them."
echo "  Scheme-only http:// and https:// do nothing."
echo "  Prefix-attached URLs like xhttp:// do nothing."
echo "  Trailing punctuation is not included."
echo "  Balanced parentheses in URL are preserved."
echo "  Non-ASCII characters terminate URL spans; opened URLs must not contain lossy bytes."
echo "  file/mailto/ssh/www/bare domains do nothing."
echo "  URLs are underlined."
echo "  Normal selection still works."
