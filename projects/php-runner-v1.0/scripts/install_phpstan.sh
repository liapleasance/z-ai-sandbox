#!/usr/bin/env bash
# install_phpstan.sh — PHP Runner v1.0
# Install PHPStan (latest 2.x) into a target project directory via Composer.
#
# PHPStan is a static analysis tool that finds bugs without running your code.
# Latest stable: PHPStan 2.3 (released Oct 6, 2026).
# Source: https://phpstan.org/blog/releases
#
# PHPStan 2.x requires PHP 8.2+. We have PHP 8.5/8.6, so this should resolve
# cleanly. PHPStan ships prebuilt binaries (Linux/macOS/Windows x86_64+arm64)
# inside the Composer package, so no compilation needed.
#
# Usage:
#   install_phpstan.sh /path/to/project    # install PHPStan 2.x into project
#   install_phpstan.sh                     # install into current directory
#   install_phpstan.sh --global            # install globally as ~/.local/bin/phpstan
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

# ─────────────────────────────────────────────────────────────────────────────
# Detect --global flag (install as standalone tool vs project dev dep)
# ─────────────────────────────────────────────────────────────────────────────
GLOBAL_INSTALL=false
if [ "${1:-}" = "--global" ]; then
    GLOBAL_INSTALL=true
    PROJECT_DIR="${HOME}/.local"
    shift || true
    PROJECT_DIR="${1:-$PROJECT_DIR}"
fi

if [ "$GLOBAL_INSTALL" = "true" ]; then
    # Global install: composer global require
    echo "[INFO] Installing PHPStan globally (composer global require)..."
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"

    # Initialize composer.json for global installs if needed
    if [ ! -f composer.json ]; then
        COMPOSER_ALLOW_SUPERUSER=1 "$PHP_BIN" "$COMPOSER_BIN" init \
            --name="app/global-tools" \
            --type=library \
            --no-interaction \
            --quiet 2>/dev/null || true
    fi

    # Idempotency: check if phpstan is already installed globally
    if [ -x "${PROJECT_DIR}/vendor/bin/phpstan" ]; then
        INSTALLED="$("$PHP_BIN" "${PROJECT_DIR}/vendor/bin/phpstan" --version 2>/dev/null \
            | grep -oE 'PHPStan [0-9.]+' \
            | awk '{print $2}' || true)"
        if [[ "$INSTALLED" =~ ^2\. ]]; then
            echo "[ OK ] PHPStan ${INSTALLED} already installed globally"
            "$PHP_BIN" "${PROJECT_DIR}/vendor/bin/phpstan" --version
            # Symlink to ~/.local/bin for convenience
            ln -sf "${PROJECT_DIR}/vendor/bin/phpstan" "${HOME}/.local/bin/phpstan" 2>/dev/null || true
            exit 0
        fi
    fi

    COMPOSER_ALLOW_SUPERUSER=1 "$PHP_BIN" "$COMPOSER_BIN" require --no-interaction --no-progress \
        "phpstan/phpstan:^2.3"

    # Symlink phpstan into ~/.local/bin for PATH convenience
    mkdir -p "${HOME}/.local/bin"
    ln -sf "${PROJECT_DIR}/vendor/bin/phpstan" "${HOME}/.local/bin/phpstan" 2>/dev/null || true

    echo ""
    echo "=== PHPStan global install complete ==="
    "$PHP_BIN" "${HOME}/.local/bin/phpstan" --version
    echo ""
    echo "Run with:  phpstan analyse <path> [--level=5]"
    echo "Config:   create phpstan.neon in project root (see install_phpstan --template)"
    exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Project install (default): install as dev dependency
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Idempotency: skip if PHPStan 2.x is already installed in this project.
if [ -f vendor/bin/phpstan ]; then
    INSTALLED="$("$PHP_BIN" vendor/bin/phpstan --version 2>/dev/null \
        | grep -oE 'PHPStan [0-9]+\.[0-9]+\.[0-9]+' \
        | awk '{print $2}' || true)"
    if [[ "$INSTALLED" =~ ^2\. ]]; then
        echo "[ OK ] PHPStan ${INSTALLED} already installed in ${PROJECT_DIR}"
        "$PHP_BIN" vendor/bin/phpstan --version
        exit 0
    fi
    echo "[INFO] Found PHPStan ${INSTALLED:-unknown}, upgrading to 2.x..."
fi

# Initialize composer.json if not present.
if [ ! -f composer.json ]; then
    echo "[INFO] Initializing composer.json in ${PROJECT_DIR}..."
    COMPOSER_ALLOW_SUPERUSER=1 "$PHP_BIN" "$COMPOSER_BIN" init \
        --name="app/project" \
        --type=project \
        --no-interaction \
        --quiet 2>/dev/null || true
fi

# Add phpstan as dev dependency.
echo "[INFO] Installing latest PHPStan 2.x via composer require..."
COMPOSER_ALLOW_SUPERUSER=1 "$PHP_BIN" "$COMPOSER_BIN" require \
    --dev \
    --no-interaction \
    --no-progress \
    "phpstan/phpstan:^2.3"

# Create default phpstan.neon if not present
if [ ! -f phpstan.neon ]; then
    echo "[INFO] Creating default phpstan.neon config..."
    # PHPStan 2.x resolves relative paths against its internal working directory
    # (typically /tmp), not the project root. We anchor paths to the project
    # absolute path so the config works regardless of where phpstan is invoked.
    PROJECT_ABS="$(cd "$PROJECT_DIR" && pwd)"
    cat > phpstan.neon << NEON
# phpstan.neon - default config generated by PHP Runner v1.0
# Docs: https://phpstan.org/config-reference
#
# Memory limit: use --memory-limit flag (e.g. \`phpstan analyse --memory-limit=1G\`)
parameters:
    # Analysis level: 0 (basic) -> 9 (strictest). 5 is a good default.
    level: 5
    # Paths to analyse (absolute - PHPStan 2.x resolves relative paths
    # against its internal working dir, not the project root).
    paths:
        - ${PROJECT_ABS}/src
        - ${PROJECT_ABS}/tests
    # Exclude specific paths
    excludePaths:
        - */vendor/*
        - */var/cache/*
        - */runtime/*
    # Treat tips, warnings, and errors as reportable
    reportUnmatchedIgnoredErrors: false
    # Parallel processing (sandbox has 2 vCPU)
    parallel:
        maximumNumberOfProcesses: 2
NEON
    echo "[ OK ] phpstan.neon created (level 5, paths: ${PROJECT_ABS}/src, ${PROJECT_ABS}/tests)"
fi

echo ""
echo "=== PHPStan install complete ==="
"$PHP_BIN" vendor/bin/phpstan --version
echo ""
echo "Run analysis:  ${PHP_BIN} vendor/bin/phpstan analyse [path] [--level=5]"
echo "Config file:  ${PROJECT_DIR}/phpstan.neon"
