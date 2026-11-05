#!/usr/bin/env bash
# run_php.sh — PHP Runner v1.0
# PHP Runner — executes PHP files or one-liners with syntax check + timing.
# Auto-installs PHP if missing (calls install_php.sh from the same directory).
set -euo pipefail

# Usage:
#   run_php.sh file.php [args...]        Run a PHP file (with syntax check first)
#   run_php.sh --code 'echo 1+1;'        Run inline PHP code (opening tag optional)
#   run_php.sh --install                 Ensure PHP is installed (run installer if missing)
#   run_php.sh --version                 Print PHP version and exit
#   run_php.sh --help                    Show this help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────────────────────────────────────
# Locate the PHP binary. The install_php.sh script installs a wrapper at
# $HOME/.local/bin/php which sets extension_dir, PHP_INI_SCAN_DIR, and
# LD_LIBRARY_PATH correctly.
# ─────────────────────────────────────────────────────────────────────────────
find_php() {
    local wrapper="${HOME}/.local/bin/php"
    if [ -x "$wrapper" ]; then
        printf '%s' "$wrapper"
        return 0
    fi
    if command -v php >/dev/null 2>&1; then
        command -v php
        return 0
    fi
    # Try common versions installed by install_php.sh
    for ver in 8.5 8.6; do
        if [ -x "${HOME}/.local/usr/bin/php${ver}" ]; then
            printf '%s' "${HOME}/.local/usr/bin/php${ver}"
            return 0
        fi
    done
    return 1
}

PHP_BIN="${PHP_BIN:-$(find_php || true)}"

MODE="file"
CODE=""
TARGET=""

# --- Parse arguments ---
if [[ $# -eq 0 ]]; then
    cat << 'USAGE'
Usage:
  run_php.sh <file.php> [args...]      Run a PHP file (with syntax check first)
  run_php.sh --code '<php code>'       Run inline PHP code
  run_php.sh --install                 Ensure PHP is installed (run installer if missing)
  run_php.sh --version                 Print PHP version and exit
USAGE
    exit 1
fi

case "$1" in
    --code)
        MODE="inline"
        if [[ $# -lt 2 ]]; then
            echo "[ERROR] --code requires a PHP code argument." >&2
            echo "Example: run_php.sh --code 'echo PHP_VERSION;'" >&2
            exit 1
        fi
        CODE="$2"
        shift 2
        ;;
    --install)
        MODE="install"
        shift
        ;;
    --version|-V)
        MODE="version"
        shift
        ;;
    --help|-h)
        cat << 'USAGE'
Usage:
  run_php.sh <file.php> [args...]      Run a PHP file (with syntax check first)
  run_php.sh --code '<php code>'       Run inline PHP code
  run_php.sh --install                 Ensure PHP is installed (run installer if missing)
  run_php.sh --version                 Print PHP version and exit
USAGE
        exit 0
        ;;
    --*)
        echo "[ERROR] Unknown option: $1" >&2
        exit 1
        ;;
    *)
        TARGET="$1"
        shift
        ;;
esac

# --- Ensure PHP is available ---
if [[ -z "$PHP_BIN" ]] || ! command -v "$PHP_BIN" >/dev/null 2>&1; then
    echo "[INFO] PHP not found. Attempting installation..."
    INSTALLER="${SCRIPT_DIR}/install_php.sh"
    if [[ -x "$INSTALLER" ]]; then
        bash "$INSTALLER"
        # Re-resolve PHP_BIN — install_php.sh creates ~/.local/bin/php
        PHP_BIN="${HOME}/.local/bin/php"
        if ! command -v "$PHP_BIN" >/dev/null 2>&1; then
            echo "[ERROR] PHP installer ran but ~/.local/bin/php still missing." >&2
            exit 1
        fi
    else
        echo "[ERROR] PHP is not installed and installer not found at $INSTALLER" >&2
        exit 1
    fi
fi

# --- Handle --version mode ---
if [[ "$MODE" == "version" ]]; then
    "$PHP_BIN" -v
    exit 0
fi

# --- Handle --install mode ---
if [[ "$MODE" == "install" ]]; then
    "$PHP_BIN" -v
    echo "[OK] PHP is ready at $PHP_BIN"
    exit 0
fi

# Print version banner on first run
echo "[INFO] PHP $("$PHP_BIN" -r 'echo PHP_VERSION;') at $PHP_BIN"

# Helper: time a command and report elapsed ms
time_and_report() {
    local start_ns end_ns elapsed_ms
    start_ns=$(date +%s%N)
    "$@"
    local rc=$?
    end_ns=$(date +%s%N)
    elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
    echo ""
    echo "--- Execution time: ${elapsed_ms}ms ---"
    return $rc
}

# --- Inline mode ---
if [[ "$MODE" == "inline" ]]; then
    TMPFILE=$(mktemp /tmp/php_inline_XXXXXX.php)
    trap 'rm -f "$TMPFILE"' EXIT

    if [[ ! "$CODE" =~ ^\<\?php ]] && [[ ! "$CODE" =~ ^\<\? ]]; then
        echo "<?php $CODE" > "$TMPFILE"
    else
        echo "$CODE" > "$TMPFILE"
    fi

    echo "[INFO] Syntax check..."
    if ! "$PHP_BIN" -l "$TMPFILE"; then
        echo "[ERROR] Syntax errors found. Aborting."
        exit 1
    fi

    echo "[INFO] Running inline PHP..."
    EXIT_CODE=0
    time_and_report "$PHP_BIN" "$TMPFILE" "$@" || EXIT_CODE=$?
    exit ${EXIT_CODE}
fi

# --- File mode ---
if [[ ! -f "$TARGET" ]]; then
    echo "[ERROR] File not found: $TARGET" >&2
    exit 1
fi

echo "[INFO] Syntax check: $TARGET"
if ! "$PHP_BIN" -l "$TARGET"; then
    echo "[ERROR] Syntax errors found. Aborting."
    exit 1
fi

echo "[INFO] Executing: $TARGET"
EXIT_CODE=0
time_and_report "$PHP_BIN" "$TARGET" "$@" || EXIT_CODE=$?
exit ${EXIT_CODE}
