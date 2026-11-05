#!/usr/bin/env bash
# install_phpunit.sh — PHP Runner v1.0
# Install PHPUnit (latest 13.x) into a target project directory via Composer.
#
# Follows the official Composer-based install method documented at
# https://phpunit.de/getting-started/phpunit-13.html —
#   composer require --dev phpunit/phpunit ^13
#
# PHPUnit 13 officially supports PHP 8.4 and 8.5 (requires >= 8.4).
# Source: https://phpunit.de/supported-versions.html (PHPUnit 13 released
# Feb 6, 2026).
#
# Usage:
#   install_phpunit.sh /path/to/project    # install PHPUnit 13.x into project
#   install_phpunit.sh                     # install into current directory
set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
PHP_BIN="${PHP_BIN:-${HOME}/.local/bin/php}"
COMPOSER_BIN="${COMPOSER_BIN:-${HOME}/.local/bin/composer}"

# Resolve PHP
if ! command -v "$PHP_BIN" >/dev/null 2>&1; then
    if command -v php >/dev/null 2>&1; then
        PHP_BIN="$(command -v php)"
    else
        echo "[ERR] PHP not found. Run install_php.sh first." >&2
        exit 1
    fi
fi

# Resolve Composer
if ! command -v "$COMPOSER_BIN" >/dev/null 2>&1; then
    if command -v composer >/dev/null 2>&1; then
        COMPOSER_BIN="$(command -v composer)"
    else
        echo "[ERR] Composer not found. Run install_composer.sh first." >&2
        exit 1
    fi
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Idempotency: skip if PHPUnit 13.x is already installed in this project.
# ─────────────────────────────────────────────────────────────────────────────
if [ -f vendor/bin/phpunit ]; then
    INSTALLED="$("$PHP_BIN" vendor/bin/phpunit --version 2>/dev/null \
        | grep -oE 'PHPUnit [0-9]+\.[0-9]+\.[0-9]+' \
        | awk '{print $2}' || true)"
    if [[ "$INSTALLED" =~ ^13\. ]]; then
        echo "[ OK ] PHPUnit ${INSTALLED} already installed in ${PROJECT_DIR}"
        "$PHP_BIN" vendor/bin/phpunit --version
        exit 0
    fi
    echo "[INFO] Found PHPUnit ${INSTALLED:-unknown}, upgrading to 13.x..."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Initialize composer.json if not present.
# ─────────────────────────────────────────────────────────────────────────────
if [ ! -f composer.json ]; then
    echo "[INFO] Initializing composer.json in ${PROJECT_DIR}..."
    COMPOSER_ALLOW_SUPERUSER=1 "$PHP_BIN" "$COMPOSER_BIN" init \
        --name="app/project" \
        --type=project \
        --no-interaction \
        --quiet 2>/dev/null || true
fi

# ─────────────────────────────────────────────────────────────────────────────
# Add phpunit as dev dependency.
# PHPUnit 13.x requires PHP 8.4+; we have 8.5 (or 8.6 when released).
# ─────────────────────────────────────────────────────────────────────────────
echo "[INFO] Installing latest PHPUnit 13.x via composer require..."
COMPOSER_ALLOW_SUPERUSER=1 "$PHP_BIN" "$COMPOSER_BIN" require \
    --dev \
    --no-interaction \
    --no-progress \
    "phpunit/phpunit:^13"

echo ""
echo "=== PHPUnit install complete ==="
"$PHP_BIN" vendor/bin/phpunit --version
echo ""
echo "Run tests with:  ${PHP_BIN} vendor/bin/phpunit [path/to/tests]"
echo "Generate coverage: ${PHP_BIN} vendor/bin/phpunit --coverage-text [path/to/tests]"
