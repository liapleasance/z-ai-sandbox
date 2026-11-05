#!/usr/bin/env bash
# install_composer.sh — PHP Runner v1.0
# Install Composer (latest stable) using the official installer from getcomposer.org.
# Installs to $HOME/.local/bin/composer (no root needed).
#
# Follows the official method documented at
# https://getcomposer.org/doc/00-intro.md which explicitly recommends
# `~/.local/bin` for no-root installs. We use the SHA-384 signature
# verification from composer.github.io/installer.sig to detect tampered
# or truncated installer downloads.
#
# As of Nov 2026, latest stable is Composer 2.11.1 (released Oct 30, 2026).
#
# Requires PHP already installed (run install_php.sh first).
set -euo pipefail

TARGET="${HOME}/.local/bin/composer"
PHP_BIN="${PHP_BIN:-${HOME}/.local/bin/php}"

# Resolve PHP binary
if ! command -v "$PHP_BIN" >/dev/null 2>&1; then
    if command -v php >/dev/null 2>&1; then
        PHP_BIN="$(command -v php)"
    else
        echo "[ERR] PHP is not installed. Run install_php.sh first." >&2
        exit 1
    fi
fi

mkdir -p "$(dirname "$TARGET")"

EXPECTED_INSTALLER_SIG_URL="https://composer.github.io/installer.sig"
INSTALLER="/tmp/composer-setup.php"

# ─────────────────────────────────────────────────────────────────────────────
# Idempotency: skip if the latest stable is already installed.
# We query getcomposer.org/versions (a JSON endpoint that lists all stable
# versions) and compare against the installed version.
# ─────────────────────────────────────────────────────────────────────────────
if [ -x "$TARGET" ]; then
    CURRENT="$("$PHP_BIN" "$TARGET" --version 2>/dev/null \
        | grep -oE 'Composer version [0-9.]+' \
        | awk '{print $3}' || true)"
    LATEST="$(curl -s --max-time 10 "https://getcomposer.org/versions" \
        | "$PHP_BIN" -r '
            $d = json_decode(stream_get_contents(STDIN) ?: "");
            if (is_object($d) && isset($d->stable) && is_array($d->stable) && count($d->stable) > 0) {
                echo $d->stable[0]->version ?? "";
            }
        ' 2>/dev/null || true)"
    if [ -n "$CURRENT" ] && [ -n "$LATEST" ] && [ "$CURRENT" = "$LATEST" ]; then
        echo "[ OK ] Composer ${CURRENT} (latest) already installed at ${TARGET}"
        "$PHP_BIN" "$TARGET" --version
        exit 0
    fi
    if [ -n "$CURRENT" ] && [ -z "$LATEST" ]; then
        echo "[WARN] Could not check for newer Composer (network). Keeping ${CURRENT}."
        "$PHP_BIN" "$TARGET" --version
        exit 0
    fi
    echo "[INFO] Upgrading Composer ${CURRENT:-unknown} → ${LATEST:-latest}..."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Download installer + signature, verify, then run.
# ─────────────────────────────────────────────────────────────────────────────
echo "[INFO] Downloading installer signature..."
SIG="$(curl -s --max-time 10 "$EXPECTED_INSTALLER_SIG_URL" | tr -d '[:space:]')"
if [ -z "$SIG" ] || [ ${#SIG} -ne 96 ]; then
    echo "[ERR] Could not fetch a valid SHA-384 signature from ${EXPECTED_INSTALLER_SIG_URL}" >&2
    exit 1
fi
echo "[INFO] Signature: $SIG"

echo "[INFO] Downloading installer..."
curl -sL --max-time 30 -o "$INSTALLER" "https://getcomposer.org/installer"

# Verify signature
ACTUAL_SIG="$("$PHP_BIN" -r "echo hash_file('sha384', '$INSTALLER');")"
if [ "$SIG" != "$ACTUAL_SIG" ]; then
    echo "[ERR] Installer signature mismatch — aborting." >&2
    echo "      Expected: $SIG" >&2
    echo "      Actual:   $ACTUAL_SIG" >&2
    rm -f "$INSTALLER"
    exit 1
fi
echo "[ OK ] Signature verified."

echo "[INFO] Running installer (installing to ${TARGET})..."
"$PHP_BIN" "$INSTALLER" --install-dir="$(dirname "$TARGET")" --filename="$(basename "$TARGET")" --quiet
rm -f "$INSTALLER"

echo ""
echo "=== Composer install complete ==="
"$PHP_BIN" "$TARGET" --version
echo ""
echo "Composer path: $TARGET"
echo "Make sure $(dirname "$TARGET") is in your PATH."
