#!/usr/bin/env bash
# install_all.sh — PHP Runner v1.0
# One-command install: PHP → Composer → PHPUnit → PHPStan
# Runs all 4 installers in the correct order, idempotent.
#
# Usage:
#   install_all.sh                          # install all into current dir (PHPUnit + PHPStan)
#   install_all.sh /path/to/project         # install PHPUnit + PHPStan into /path/to/project
#   install_all.sh --global                 # install PHPStan globally
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_DIR=""
GLOBAL_PHPSTAN=false

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --global)
            GLOBAL_PHPSTAN=true
            shift
            ;;
        --help|-h)
            cat << 'USAGE'
Usage:
  install_all.sh [project_dir]              Install PHP + Composer + PHPUnit + PHPStan
  install_all.sh --global                   Install PHPStan globally instead of project-local
  install_all.sh --help                     This help
USAGE
            exit 0
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

echo "╔══════════════════════════════════════════════════╗"
echo "║   PHP Runner v1.0 — Full Stack Installer          ║"
echo "║                                                  ║"
echo "║   1. PHP 8.5.x (or 8.6 when released)             ║"
echo "║   2. Composer (latest stable)                     ║"
echo "║   3. PHPUnit 13.x                                 ║"
echo "║   4. PHPStan 2.x                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Target project: ${PROJECT_DIR}"
[ "$GLOBAL_PHPSTAN" = "true" ] && echo "PHPStan install mode: GLOBAL (~/.local)" || echo "PHPStan install mode: project-local"
echo ""

# Step 1: PHP
echo "=== [1/4] Installing PHP ==="
bash "${SCRIPT_DIR}/install_php.sh"
echo ""

# Step 2: Composer
echo "=== [2/4] Installing Composer ==="
bash "${SCRIPT_DIR}/install_composer.sh"
echo ""

# Step 3: PHPUnit
echo "=== [3/4] Installing PHPUnit (into ${PROJECT_DIR}) ==="
bash "${SCRIPT_DIR}/install_phpunit.sh" "$PROJECT_DIR"
echo ""

# Step 4: PHPStan
echo "=== [4/4] Installing PHPStan ==="
if [ "$GLOBAL_PHPSTAN" = "true" ]; then
    bash "${SCRIPT_DIR}/install_phpstan.sh" --global
else
    bash "${SCRIPT_DIR}/install_phpstan.sh" "$PROJECT_DIR"
fi
echo ""

echo "╔══════════════════════════════════════════════════╗"
echo "║   ✅ PHP Runner v1.0 — All components installed    ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo "  cd \"${PROJECT_DIR}\""
echo "  php -v"
echo "  composer --version"
echo "  vendor/bin/phpunit --version"
echo "  vendor/bin/phpstan --version"
echo ""
echo "Run static analysis:  php vendor/bin/phpstan analyse src --level=5"
echo "Run tests:            php vendor/bin/phpunit tests/"
