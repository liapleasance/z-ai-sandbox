#!/usr/bin/env bash
# install_php.sh — PHP Runner v1.0
# Install the latest PHP (8.5 or 8.6 if available) into $HOME/.local — NO root,
# NO source compile.
#
# Strategy: download pre-compiled .deb packages from deb.sury.org (the canonical
# upstream PHP packager for Debian/Ubuntu) and extract them locally with
# `dpkg-deb -x`. Total time: ~5 s.
#
# The script tries the latest branch first (8.6 if released, else 8.5) by
# probing sury.org's pool index. Falls back to 8.5 if 8.6 isn't there yet.
#
# Idempotent: re-running exits fast if PHP is already installed at the
# requested version.
#
# What you get:
#   - $HOME/.local/usr/bin/php8.5      (real binary)
#   - $HOME/.local/bin/php             (wrapper that sets extension_dir,
#                                       PHP_INI_SCAN_DIR, LD_LIBRARY_PATH)
#   - $HOME/.local/etc/php/8.5/cli/php.ini          (base ini)
#   - $HOME/.local/etc/php/8.5/cli/conf.d/*.ini     (one per extension)
#   - $HOME/.local/usr/lib/php/<PHP_API>/*.so       (extension modules)
#
# Built-in modules: Core, date, filter, hash, json, lexbor, libxml, openssl,
# pcntl, pcre, random, Reflection, session, sodium, SPL, standard, uri,
# Zend OPcache, zlib.
#
# Loaded via conf.d: bcmath, calendar, ctype, curl, dom, exif, FFI, fileinfo,
# ftp, gd, gettext, gmp, iconv, intl, mbstring, mysqli, mysqlnd, pdo,
# pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, readline, shmop,
# SimpleXML, soap, sockets, sqlite3, sysvmsg, sysvsem, sysvshm, tokenizer,
# xml, xmlreader, xmlwriter, xsl, zip.
set -euo pipefail

# Prefer 8.6 (when released), fall back to 8.5 (stable, supported).
# Update this list when new PHP branches are released.
PHP_BRANCHES_TRY=("8.5")
# Add 8.6 to the front of the try-list when it's released (Nov 19, 2026).
# PHP_BRANCHES_TRY=("8.6" "8.5")  # uncomment after 8.6 release

LOCAL_ROOT="${HOME}/.local"
LOCAL_PREFIX="${LOCAL_ROOT}/usr"        # .deb files expand here
LOCAL_BIN="${LOCAL_ROOT}/bin"
PHP_INI_DIR_BASE="${LOCAL_ROOT}/etc/php"
DEB_CACHE="${LOCAL_ROOT}/var/debs"
LIB_DEB_CACHE="${LOCAL_ROOT}/var/debs-libs"

log()  { printf '[INFO] %s\n' "$*"; }
ok()   { printf '[ OK ] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERR ] %s\n' "$*" >&2; }

# ─────────────────────────────────────────────────────────────────────────────
# Step 0: Already installed? Verify and exit fast.
# Checks the wrapper at ~/.local/bin/php — if it works and reports a version
# >= any of our candidate branches, we're done.
# ─────────────────────────────────────────────────────────────────────────────
PHP_WRAPPER="${LOCAL_BIN}/php"
if [ -x "$PHP_WRAPPER" ]; then
    for branch in "${PHP_BRANCHES_TRY[@]}"; do
        if "$PHP_WRAPPER" -r 'exit(version_compare(PHP_VERSION,"'"${branch}"'")>=0?0:1);' 2>/dev/null; then
            ok "PHP $("$PHP_WRAPPER" -r 'echo PHP_VERSION;') already installed at $PHP_WRAPPER"
            "$PHP_WRAPPER" -v
            exit 0
        fi
    done
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Detect OS codename → sury.org URL suffix.
# ─────────────────────────────────────────────────────────────────────────────
detect_codename() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}/${VERSION_CODENAME:-}" in
            debian/*) echo "debian${VERSION_ID:-13}" ;;
            ubuntu/*) echo "ubuntu${VERSION_ID:-24.04}" ;;
            *) echo "debian13" ;;
        esac
    else
        echo "debian13"
    fi
}
CODENAME="$(detect_codename)"
log "Detected codename: $CODENAME"

# Detect architecture
ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$ARCH" in
    amd64|x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) err "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: For each candidate branch, try to find a php-<branch>-cli .deb on
# sury.org. Pick the first branch that has one.
# ─────────────────────────────────────────────────────────────────────────────
PHP_VERSION=""
PHP_API=""
CLI_DEB_NAME=""
DEB_FILENAME_VERSION=""
PHP_PATCH=""

for branch in "${PHP_BRANCHES_TRY[@]}"; do
    SURY_POOL="https://packages.sury.org/php/pool/main/p/php${branch}/"
    log "Trying PHP ${branch} — fetching package list from ${SURY_POOL} ..."
    INDEX_HTML="$(curl -sL --max-time 30 --retry 2 "$SURY_POOL" || true)"
    if [ -z "$INDEX_HTML" ]; then
        warn "Could not fetch sury.org pool index for PHP ${branch}. Skipping."
        continue
    fi

    # Parse the pool index to find the full filename of php${branch}-cli .deb
    # matching our codename+arch. sury URL-encodes '+' as %2B in hrefs.
    CLI_DEB_NAME="$(printf '%s\n' "$INDEX_HTML" \
        | grep -oE "php${branch}-cli_[^\"']+_${ARCH}\.deb" \
        | grep -vE 'dbgsym' \
        | grep -E "${CODENAME}~1" \
        | sort -u \
        | head -1 || true)"
    if [ -z "$CLI_DEB_NAME" ]; then
        warn "No php${branch}-cli .deb for ${CODENAME}/${ARCH} on sury.org. Skipping."
        continue
    fi

    PHP_VERSION="$branch"
    PHP_PATCH="$(printf '%s' "$CLI_DEB_NAME" | grep -oE "${branch}\.[0-9]+" | head -1)"
    DEB_FILENAME_VERSION="$(printf '%s' "$CLI_DEB_NAME" \
        | sed -E "s/^php${branch}-cli_//" \
        | sed -E "s/_${ARCH}\.deb$//")"
    ok "Selected: $CLI_DEB_NAME"
    ok "Latest PHP on sury.org for ${CODENAME}: ${PHP_PATCH}"
    break
done

if [ -z "$PHP_VERSION" ]; then
    err "Could not find a suitable PHP .deb package on sury.org for any of: ${PHP_BRANCHES_TRY[*]}"
    err "Available codenames: debian11, debian12, debian13, ubuntu22.04, ubuntu24.04."
    exit 1
fi

PHP_REAL="${LOCAL_PREFIX}/bin/php${PHP_VERSION}"
PHP_INI_DIR="${PHP_INI_DIR_BASE}/${PHP_VERSION}/cli"
PHP_INI="${PHP_INI_DIR}/php.ini"
PHP_CONF_D="${PHP_INI_DIR}/conf.d"

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Discover PHP_API (module API version, e.g. 20250925) from the
# already-downloaded CLI binary. We need it for extension_dir.
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$DEB_CACHE"

# Download just the cli package first (we need its binary to query PHP_API).
CLI_DEB="${DEB_CACHE}/php${PHP_VERSION}-cli.deb"
url="${SURY_POOL}${CLI_DEB_NAME}"
log "Downloading php${PHP_VERSION}-cli ($(printf '%s' "$CLI_DEB_NAME" | sed 's/%2B/+/g'))..."
if ! curl -sL --max-time 60 --retry 2 -o "$CLI_DEB" "$url"; then
    err "Failed to download $url"
    exit 1
fi
if ! file "$CLI_DEB" | grep -q "Debian binary package"; then
    err "Downloaded file is not a valid .deb: $CLI_DEB"
    rm -f "$CLI_DEB"
    exit 1
fi

# Extract cli to a temp dir to query PHP_API before the full extract.
TMP_EXTRACT=$(mktemp -d)
dpkg-deb -x "$CLI_DEB" "$TMP_EXTRACT" 2>/dev/null
TMP_PHP_BIN="${TMP_EXTRACT}/usr/bin/php${PHP_VERSION}"
if [ ! -x "$TMP_PHP_BIN" ]; then
    err "Could not find php${PHP_VERSION} binary in cli package"
    rm -rf "$TMP_EXTRACT"
    exit 1
fi

# Query PHP API (PHP_EXTENSION_API, called "PHP API" in `php -i` output).
# Set LD_LIBRARY_PATH for the probe in case libs aren't on the system yet — but
# if the binary needs missing libs, the probe will fail and we'll fall through
# to the runtime-libs step.
PHP_API=""
# Method 1: grep from `php -i` (most reliable)
PHP_API="$(LD_LIBRARY_PATH="${TMP_EXTRACT}/usr/lib/x86_64-linux-gnu:${TMP_EXTRACT}/usr/lib:${LD_LIBRARY_PATH:-}" \
    "$TMP_PHP_BIN" -i 2>/dev/null | grep -oE 'PHP API => [0-9]+' | awk '{print $4}' | head -1 || true)"
# Method 2: list files in the extracted extension directory
if [ -z "$PHP_API" ]; then
    PHP_API="$(find "${TMP_EXTRACT}/usr/lib/php" -maxdepth 1 -mindepth 1 -type d -regex '.*/[0-9]+' 2>/dev/null | head -1 | xargs basename 2>/dev/null || true)"
fi
# Method 3: hardcoded fallback for PHP 8.5
PHP_API="${PHP_API:-20250925}"

ok "PHP module API: ${PHP_API}"
EXT_DIR="${LOCAL_PREFIX}/lib/php/${PHP_API}"
rm -rf "$TMP_EXTRACT"

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Define which extension packages we want, then download them all.
# ─────────────────────────────────────────────────────────────────────────────
EXTENSION_PKGS=(
    php${PHP_VERSION}-cli          # binary + OPcache (built-in)
    php${PHP_VERSION}-common       # pdo, phar, posix, ffi, fileinfo, ftp, ...
    php${PHP_VERSION}-readline
    php${PHP_VERSION}-mbstring
    php${PHP_VERSION}-xml          # dom, simplexml, xml, xmlreader, xmlwriter, xsl
    php${PHP_VERSION}-curl
    php${PHP_VERSION}-gd
    php${PHP_VERSION}-intl
    php${PHP_VERSION}-bcmath
    php${PHP_VERSION}-zip
    php${PHP_VERSION}-mysql        # mysqli, pdo_mysql, mysqlnd
    php${PHP_VERSION}-pgsql        # pgsql, pdo_pgsql
    php${PHP_VERSION}-sqlite3      # sqlite3, pdo_sqlite
    php${PHP_VERSION}-soap
    php${PHP_VERSION}-gmp
)

log "Downloading ${#EXTENSION_PKGS[@]} .deb packages..."
for pkg in "${EXTENSION_PKGS[@]}"; do
    fname="${pkg}_${DEB_FILENAME_VERSION}_${ARCH}.deb"
    out="${DEB_CACHE}/${pkg}.deb"
    if [ -f "$out" ] && file "$out" | grep -q "Debian binary package"; then
        : # cache hit
    else
        url="${SURY_POOL}${fname}"
        log "  → ${pkg} ($(printf '%s' "$fname" | sed 's/%2B/+/g'))"
        if ! curl -sL --max-time 60 --retry 2 -o "$out" "$url"; then
            err "Failed to download $url"
            exit 1
        fi
        if ! file "$out" | grep -q "Debian binary package"; then
            err "Downloaded file is not a valid .deb: $out"
            err "(got: $(file "$out"))"
            rm -f "$out"
            exit 1
        fi
    fi
done
ok "All PHP .deb packages downloaded."

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Download runtime libs that the .deb packages need but that may
# be missing on a minimal sandbox. The most common missing one is libzip5
# (provides libzip.so.5 needed by php-zip).
# ─────────────────────────────────────────────────────────────────────────────
install_runtime_libs() {
    local libs=()
    if ! ldconfig -p 2>/dev/null | grep -q "libzip.so.5"; then
        libs+=(libzip5)
    fi
    if ! ldconfig -p 2>/dev/null | grep -q "libargon2.so.1"; then
        libs+=(libargon2-1)
    fi
    if ! ldconfig -p 2>/dev/null | grep -q "libicuuc.so.76"; then
        if ! ldconfig -p 2>/dev/null | grep -q "libicuuc.so"; then
            libs+=(libicu76)
        fi
    fi
    if ! ldconfig -p 2>/dev/null | grep -q "libsodium.so.23"; then
        if ! ldconfig -p 2>/dev/null | grep -q "libsodium.so"; then
            libs+=(libsodium23)
        fi
    fi

    if [ ${#libs[@]} -eq 0 ]; then
        ok "All runtime libs already satisfied."
        return 0
    fi

    mkdir -p "$LIB_DEB_CACHE"
    log "Auto-installing ${#libs[@]} runtime lib(s) via apt-get download: ${libs[*]}"
    ( cd "$LIB_DEB_CACHE" && apt-get download "${libs[@]}" 2>&1 | tail -3 || true )
    for deb in "$LIB_DEB_CACHE"/*.deb; do
        [ -e "$deb" ] || continue
        dpkg-deb -x "$deb" "$LOCAL_ROOT" 2>/dev/null || true
    done
    find "${LOCAL_PREFIX}/lib" -maxdepth 3 -name "*.so.*" -not -name "*.so" 2>/dev/null | while read -r sofile; do
        base="$(printf '%s' "$sofile" | sed -E 's/\.so\.[0-9]+.*$/.so/')"
        [ -e "$base" ] || ln -sf "$(basename "$sofile")" "$base"
    done
}
install_runtime_libs

# ─────────────────────────────────────────────────────────────────────────────
# Step 6: Extract all PHP .deb files into ~/.local/usr.
# ─────────────────────────────────────────────────────────────────────────────
log "Extracting .deb packages into $LOCAL_PREFIX ..."
for deb in "${DEB_CACHE}"/*.deb; do
    [ -e "$deb" ] || continue
    dpkg-deb -x "$deb" "$LOCAL_ROOT" 2>&1 | grep -v "^dpkg-deb:" || true
done

if [ ! -x "$PHP_REAL" ]; then
    err "PHP binary not found at $PHP_REAL after extraction."
    err "Files in $LOCAL_PREFIX/bin/:"
    ls -la "$LOCAL_PREFIX/bin/" 2>&1 | head -10
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 7: Build conf.d symlinks from /usr/share/php${PHP_VERSION}-*/*/*.ini.
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$PHP_CONF_D"
rm -f "$PHP_CONF_D"/*.ini 2>/dev/null || true

log "Building conf.d symlinks..."
shopt -s nullglob
for ini in "${LOCAL_PREFIX}/share/php${PHP_VERSION}-"*/*/*.ini; do
    prio=$(grep -oE 'priority=[0-9]+' "$ini" 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)
    [ -n "$prio" ] || prio=20
    name="$(basename "$ini")"
    target="${PHP_CONF_D}/$(printf '%02d' "$prio")-${name}"
    ln -sf "$ini" "$target"
done
shopt -u nullglob
ok "$(ls "$PHP_CONF_D"/*.ini 2>/dev/null | wc -l) extension ini files linked."

# ─────────────────────────────────────────────────────────────────────────────
# Step 8: Write base php.ini. extension_dir must point to our extracted
# /usr/lib/php/<PHP_API>/ — the binary's compiled-in default is /usr/lib/php/...
# but we extracted to ~/.local/usr/lib/php/... so we override.
# NOTE: this heredoc is UNQUOTED (<< EOF) on purpose so ${EXT_DIR} expands.
# Do NOT add unescaped backticks or $(...) here — bash will try to execute them.
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$PHP_INI_DIR"
cat > "$PHP_INI" << EOF
; Generated by install_php.sh — do not edit unless you know what you're doing.
[PHP]
extension_dir = "${EXT_DIR}"
memory_limit = 512M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
display_startup_errors = On
log_errors = On
date.timezone = "UTC"
default_charset = "UTF-8"
zend.exception_ignore_args = Off
zend.exception_string_param_max_len = 15
; OPcache (built-in)
opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 128
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
; Realpath cache (huge perf win on systems with many includes)
realpath_cache_size = 4096K
realpath_cache_ttl = 600
; Phar — keep phar.readonly=On (the default) for safety. If you need to
; write to a .phar (rare), pass \`-d phar.readonly=0\` for that one call.
;phar.readonly = On
EOF
ok "php.ini written to $PHP_INI"

# ─────────────────────────────────────────────────────────────────────────────
# Step 9: Write the wrapper script ~/.local/bin/php.
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$LOCAL_BIN"

MULTIARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo "${ARCH}-linux-gnu")"

cat > "$PHP_WRAPPER" << EOF
#!/usr/bin/env bash
# Auto-generated wrapper for PHP ${PHP_VERSION} (sury.org .deb install)
# Re-run install_php.sh to regenerate.
set -e
export PHP_INI_SCAN_DIR="${PHP_CONF_D}"
export LD_LIBRARY_PATH="${LOCAL_PREFIX}/lib/${MULTIARCH}:${LOCAL_PREFIX}/lib:\${LD_LIBRARY_PATH:-}"
exec "${PHP_REAL}" -c "${PHP_INI}" "\$@"
EOF
chmod +x "$PHP_WRAPPER"

# ─────────────────────────────────────────────────────────────────────────────
# Step 10: Smoke test — gd, pdo_sqlite, zip, mbstring, intl must all load.
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== PHP install complete ==="
"$PHP_WRAPPER" -v
echo ""

"$PHP_WRAPPER" -r '
$ok = [];
$fail = [];
$img = @imagecreatetruecolor(8, 8);
$img ? $ok[] = "gd" : $fail[] = "gd";
try { $pdo = new PDO("sqlite::memory:"); $pdo->exec("CREATE TABLE t (id INTEGER)"); $ok[] = "pdo_sqlite"; }
catch (Throwable $e) { $fail[] = "pdo_sqlite: " . $e->getMessage(); }
try { $z = new ZipArchive(); $ok[] = "zip"; } catch (Throwable $e) { $fail[] = "zip"; }
function_exists("mb_strtolower") ? $ok[] = "mbstring" : $fail[] = "mbstring";
class_exists("IntlChar") ? $ok[] = "intl" : $fail[] = "intl";
function_exists("curl_init") ? $ok[] = "curl" : $fail[] = "curl";
function_exists("bcadd") ? $ok[] = "bcmath" : $fail[] = "bcmath";
class_exists("DOMDocument") ? $ok[] = "dom" : $fail[] = "dom";
class_exists("SoapClient") ? $ok[] = "soap" : $fail[] = "soap";
function_exists("gmp_init") ? $ok[] = "gmp" : $fail[] = "gmp";
function_exists("mysqli_init") ? $ok[] = "mysqli" : $fail[] = "mysqli";
function_exists("pcntl_fork") ? $ok[] = "pcntl" : $fail[] = "pcntl";
json_decode("1") === 1 ? $ok[] = "json" : $fail[] = "json";
function_exists("opcache_get_status") ? $ok[] = "opcache" : $fail[] = "opcache";

echo "Loaded:  " . implode(", ", $ok) . "\n";
if ($fail) { fwrite(STDERR, "MISSING: " . implode(", ", $fail) . "\n"); exit(1); }
echo "All expected extensions loaded.\n";
' || { err "Smoke test failed — see MISSING list above."; exit 1; }

echo ""
ok "PHP installed at:       $PHP_REAL"
ok "Wrapper symlinked as:   $PHP_WRAPPER"
ok "INI file:               $PHP_INI"
ok "Conf.d dir:             $PHP_CONF_D ($(ls "$PHP_CONF_D"/*.ini 2>/dev/null | wc -l) files)"
ok "Extension dir:          $EXT_DIR"
ok "Add to PATH:            export PATH=\"$LOCAL_BIN:\$PATH\""
