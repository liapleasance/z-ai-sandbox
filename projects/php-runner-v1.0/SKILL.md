---
name: php-runner
description: >
  Install and run PHP (latest 8.5.x or 8.6 when released), Composer, PHPUnit,
  and PHPStan in the z.ai web chat sandbox. No root/sudo needed — PHP installs
  to $HOME/.local via pre-compiled .deb packages from deb.sury.org (~5s);
  Composer and the test/analysis tools install via their official methods.
  Trigger on any PHP install, run/test PHP code, set up Composer, run PHPUnit
  tests, or run PHPStan static analysis.
metadata:
  version: 1.0.0
---

# PHP Runner `v1.0.0`

> **v1.0.0 (2026-11-04):** Versão inicial. Mantém a base da v5.0.1 (instalação
> via sury.org .deb packages, idempotência, smoke test) e adiciona:
> 1. **`install_phpstan.sh`** — instala PHPStan 2.x (última estável: 2.3, Oct 2026)
>    via `composer require --dev phpstan/phpstan:^2.3`. Cria `phpstan.neon` default.
> 2. **`install_all.sh`** — instala os 4 componentes em ordem (PHP → Composer →
>    PHPUnit → PHPStan) com 1 comando.
> 3. Auto-detecção de versão PHP (8.5 ou 8.6 quando lançada em Nov 19, 2026).
> 4. Versões atualizadas de todos os componentes.

Installs **PHP 8.5.x** (latest patch from sury.org — currently 8.5.12, released
Oct 21, 2026), **Composer (latest stable, currently 2.11.1, Oct 30, 2026)**,
**PHPUnit 13.x** (released Feb 6, 2026), and **PHPStan 2.x** (currently 2.3,
Oct 6, 2026) into `$HOME/.local` and project `vendor/` — no root required, no
source compilation.

## ⚡ Quick Start — One Command Install (Recommended)

```bash
# Install all 4 (PHP + Composer + PHPUnit + PHPStan) into current project:
bash /home/z/my-project/skills/php-runner/scripts/install_all.sh

# Or with a target project directory:
bash /home/z/my-project/skills/php-runner/scripts/install_all.sh /path/to/project

# Or with PHPStan globally (~/.local/bin/phpstan):
bash /home/z/my-project/skills/php-runner/scripts/install_all.sh --global
```

## ⚡ Quick Start — Step-by-Step

```bash
# 1. PHP 8.5.x (~5s: downloads pre-compiled .deb packages from deb.sury.org)
bash /home/z/my-project/skills/php-runner/scripts/install_php.sh

# 2. Composer (latest, ~6s: official installer with SHA-384 signature verification)
bash /home/z/my-project/skills/php-runner/scripts/install_composer.sh

# 3. PHPUnit 13.x (~4s: composer require into a project dir)
bash /home/z/my-project/skills/php-runner/scripts/install_phpunit.sh /path/to/project

# 4. PHPStan 2.x (~3s: composer require --dev, creates phpstan.neon)
bash /home/z/my-project/skills/php-runner/scripts/install_phpstan.sh /path/to/project
#   or globally:
bash /home/z/my-project/skills/php-runner/scripts/install_phpstan.sh --global
```

The order matters: **PHP → Composer → PHPUnit / PHPStan**. PHPUnit and
PHPStan are installed via Composer, so Composer must come first. PHPUnit and
PHPStan can be installed in any order after Composer (or in parallel).

**All scripts are idempotent** — re-running skips what's already installed.

## 📦 What Gets Installed

| Component | Version (Nov 2026) | Path |
|---|---|---|
| PHP | 8.5.12 (or 8.6 when released) | `~/.local/usr/bin/php8.5` ← wrapper at `~/.local/bin/php` |
| Composer | 2.11.1 (latest stable) | `~/.local/bin/composer` |
| PHPUnit | 13.x | `<project>/vendor/bin/phpunit` |
| PHPStan | 2.3 (or newer 2.x) | `<project>/vendor/bin/phpstan` (or `~/.local/bin/phpstan` if `--global`) |

**Why a PHP wrapper?** The real PHP binary lives at `~/.local/usr/bin/php8.5`.
The wrapper at `~/.local/bin/php` sets `LD_LIBRARY_PATH` (so PHP finds
`libzip.so.5` etc.), `PHP_INI_SCAN_DIR` (so PHP finds our `conf.d/*.ini`), and
passes `-c <our php.ini>` (which sets `extension_dir` to our extracted
`~/.local/usr/lib/php/<PHP_API>/`). Always invoke `php` (the wrapper), not
`php8.5` directly.

**PHP extensions included (58 total):** bcmath, calendar, Core, ctype, curl,
date, dom, exif, FFI, fileinfo, filter, ftp, gd (jpeg/freetype/webp), gettext,
gmp, hash, iconv, intl, json, lexbor, libxml, mbstring, mysqli, mysqlnd,
openssl, pcntl, pcre, PDO, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix,
random, readline, Reflection, session, shmop, SimpleXML, soap, sockets,
sodium, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tokenizer, uri,
xml, xmlreader, xmlwriter, xsl, Zend OPcache, zip, zlib. Run `php -m` to list.

**NOT included:** bz2, dba, enchant, interbase, ldap, litespeed, odbc, snmp,
sybase, tidy. To add them, edit `EXTENSION_PKGS` in `install_php.sh` and re-run.

## 🌐 Sandbox Facts (z.ai web chat)

| Fact | Value |
|---|---|
| Root/sudo | ❌ NOT available — install to `$HOME/.local` instead |
| `apt-get install` | ❌ Fails (no root, no dpkg lock) |
| `apt-get download` + `dpkg-deb -x` | ✅ Works — used for runtime libs (libzip5, etc.) |
| Writable paths | `$HOME/.local`, `/tmp`, `/home/z/my-project/` |
| `packages.sury.org` | ✅ Reachable (PHP 8.5 .deb packages — main install source for PHP) |
| `getcomposer.org` | ✅ Reachable (official Composer installer) |
| `repo.packagist.org` | ✅ Reachable (Composer dependency resolution for PHPUnit + PHPStan) |
| Pre-installed tools | gcc, make, autoconf, pkg-config, curl, dpkg-deb |
| Pre-installed libs (Debian 13 trixie) | libxml2, libsqlite3, libssl3, libcurl4, libonig, libreadline, libjpeg, libpng, libfreetype, libwebp, libxslt, libicu, libsodium, libargon2, zlib |
| Auto-installed by this skill | libzip5 (only if `libzip.so.5` missing) |

## 🏃 Running PHP

```bash
# Add to PATH (or prefix commands with the full path)
export PATH="$HOME/.local/bin:$PATH"

# Run a PHP file
php script.php

# Run inline PHP code (via run_php.sh — includes syntax check + timing)
bash /home/z/my-project/skills/php-runner/scripts/run_php.sh script.php
bash /home/z/my-project/skills/php-runner/scripts/run_php.sh --code 'echo PHP_VERSION;'
bash /home/z/my-project/skills/php-runner/scripts/run_php.sh --version

# Run PHPUnit tests
php vendor/bin/phpunit path/to/Test.php

# Run PHPUnit with coverage (text)
php vendor/bin/phpunit --coverage-text path/to/tests

# Run PHPStan static analysis
php vendor/bin/phpstan analyse src --level=5
php vendor/bin/phpstan analyse src tests --level=8

# Generate baseline (after first analysis, to ignore existing issues)
php vendor/bin/phpstan analyse src --level=5 --generate-baseline
```

## 🩺 Troubleshooting — Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `php: command not found` | PHP not installed or PATH not set | Run `install_php.sh`, then `export PATH="$HOME/.local/bin:$PATH"` |
| `composer: command not found` | Composer not installed | Run `install_composer.sh` (requires PHP first) |
| `phpunit: command not found` | PHPUnit not installed | Run `install_phpunit.sh <project>` (requires PHP + Composer first) |
| `phpstan: command not found` | PHPStan not installed | Run `install_phpstan.sh <project>` (requires PHP + Composer first) |
| `Unable to load dynamic library 'X.so'` | A runtime lib is missing (e.g. libzip5) | `install_php.sh` auto-detects and `apt-get download`s missing libs. If a new one shows up, add it to `install_runtime_libs()` and re-run. |
| `PHP Version: 8.4.x` instead of `8.5.x` | Old Debian default PHP picked up from PATH | Ensure `~/.local/bin` comes first in PATH: `export PATH="$HOME/.local/bin:$PATH"` |
| `E: Could not open lock file /var/lib/apt/lists/lock` | Tried `apt-get install` directly (no root) | Don't use `apt-get install`. The scripts use `apt-get download` + `dpkg-deb -x` instead, which needs no root. |
| `composer require X` fails on packagist | Shouldn't happen — packagist is reachable | If it does, check network: `curl -sI https://repo.packagist.org/p2/phpunit/phpunit.json` |
| `Could not find php8.5-cli .deb for <codename>` | Either an unsupported distro or sury.org down | Check `https://packages.sury.org/php/pool/main/p/php8.5/` in a browser. Supported codenames: debian11, debian12, debian13, ubuntu22.04, ubuntu24.04. |
| Wrapper script broken after manual edits | User edited `~/.local/bin/php` | Re-run `install_php.sh` — it regenerates the wrapper. |
| PHPStan `Allowed memory size exhausted` | Default 512M limit too low | Edit `phpstan.neon` and bump `memoryLimit: 1024M` |
| PHPStan `no errors were found` but code is buggy | Analysis level too low | Bump `level: 8` (or `max` for strictest) in `phpstan.neon` |
| PHPUnit `No tests executed!` | Test class doesn't match `*Test.php` pattern | Use `phpunit path/to/SpecificTest.php` or rename to `XxxTest.php` |

## 🔧 How `install_php.sh` Works

1. **Check if PHP already installed** → exit fast if yes (~100ms).
2. **Detect OS codename** (debian13, ubuntu24.04, etc.) from `/etc/os-release`.
3. **For each candidate branch** (8.6 first if released, then 8.5), fetch the
   sury.org pool index and try to find a matching `php<branch>-cli_*.deb`.
   Pick the first branch that has one.
4. **Download 15 .deb packages** (cli, common, mbstring, xml, curl, gd, intl,
   bcmath, zip, mysql, pgsql, sqlite3, soap, gmp, readline) (~3-4s).
5. **Auto-install missing runtime libs** (libzip5, libargon2-1, libicu76,
   libsodium23) via `apt-get download` + `dpkg-deb -x` if `ldconfig -p` shows
   they're missing.
6. **Extract all .deb files** into `~/.local` via `dpkg-deb -x`.
7. **Build `conf.d/*.ini` symlinks** by walking `~/.local/usr/share/php8.5-*/<pkg>/*.ini`
   and creating priority-prefixed symlinks (e.g. `10-pdo.ini`, `20-curl.ini`).
8. **Write `php.ini`** with `extension_dir`, OPcache settings, error reporting,
   timezone.
9. **Write wrapper script** `~/.local/bin/php` that exports `LD_LIBRARY_PATH` +
   `PHP_INI_SCAN_DIR` and calls `php8.5 -c <php.ini>`.
10. **Smoke test** — exercises `gd`, `pdo_sqlite`, `zip`, `mbstring`, `intl`,
    `curl`, `bcmath`, `dom`, `soap`, `gmp`, `mysqli`, `pcntl`, `json`, `opcache`.

Total wall time: **~5 seconds**.

## 🔧 How `install_composer.sh` Works

1. **Check if Composer latest is already installed** (queries
   `getcomposer.org/versions` for current stable) → exit fast if yes.
2. **Download installer signature** from `https://composer.github.io/installer.sig`
   (SHA-384, 96 hex chars).
3. **Download installer** from `https://getcomposer.org/installer`.
4. **Verify signature** — `hash_file('sha384', $installer)` must match the
   published signature.
5. **Run installer** with `--install-dir=~/.local/bin --filename=composer`.
6. **Print version** to confirm.

Total wall time: **~6 seconds**.

Follows the official method at <https://getcomposer.org/doc/00-intro.md> which
explicitly recommends `~/.local/bin` for no-root installs.

## 🔧 How `install_phpunit.sh` Works

1. **Check if PHPUnit 13.x is already installed in the target project** →
   exit fast if yes.
2. **Initialize `composer.json`** if not present (with `"name": "app/project"`).
3. **`composer require --dev phpunit/phpunit:^13`** into the project's
   `vendor/`.
4. **Print version** to confirm.

Total wall time: **~4 seconds**.

Follows the official method at <https://phpunit.de/getting-started/phpunit-13.html>
— `composer require --dev phpunit/phpunit ^13`. PHPUnit 13 officially supports
PHP 8.4 and 8.5.

## 🔧 How `install_phpstan.sh` Works (NEW in v1.0)

1. **Detect mode** — project-local (default) or `--global` (install as
   `~/.local/bin/phpstan`).
2. **If project-local**: check if PHPStan 2.x is already in
   `vendor/bin/phpstan` → exit fast if yes.
3. **If `--global`**: check if `~/.local/bin/phpstan` exists and reports 2.x →
   exit fast if yes.
4. **Initialize `composer.json`** if not present.
5. **`composer require --dev phpstan/phpstan:^2.3`** (or
   `composer global require` for `--global` mode).
6. **Create default `phpstan.neon`** with:
   - `level: 5` (good default — catches type errors, missing returns, etc.)
   - `paths: [src, tests]`
   - `excludePaths: [*/vendor/*, */tmp/*]`
   - `memoryLimit: 512M`
7. **Print version** to confirm.

Total wall time: **~3 seconds** (Composer packages are prebuilt, no compilation).

PHPStan ships prebuilt binaries inside the Composer package (Linux glibc/musl
x86_64+arm64, macOS arm64, Windows x86_64) — no compilation needed. PHPStan
picks the binary matching the running PHP and restarts itself with it loaded
via `-d extension=`.

Follows the official method at <https://phpstan.org/user-guide/getting-started>
— `composer require --dev phpstan/phpstan`.

### PHPStan levels (from phpstan.neon)

| Level | What it catches |
|---|---|
| 0 | Basic checks (return statements, callable, ...). Always enabled. |
| 1 | Unknown methods, undefined variables |
| 2 | Unknown methods on `$this`, unknown functions |
| 3 | Return type checks |
| 4 | Catch reachability, unreachable code |
| 5 | Argument count check, generics checks |
| 6 | Missing type hints |
| 7 | Partially wrong unions, nullable types |
| 8 | Calling methods and accessing properties on nullable types |
| 9 | Be strict about `mixed` type |
| max (10) | All rules enabled, strictest |

**Recommendation:** start with `level: 5`, increase to 8 once you're
comfortable. For greenfield projects, start at `level: 8`.

### PHPStan baseline

If you have legacy code with many existing issues, generate a baseline:

```bash
php vendor/bin/phpstan analyse src --level=5 --generate-baseline
```

This creates `phpstan-baseline.neon` that lists all current errors. PHPStan
won't report them on future runs — only NEW errors will surface.

## 🔧 How `install_all.sh` Works (NEW in v1.0)

Runs the 4 installers in order:
1. `install_php.sh` (PHP)
2. `install_composer.sh` (Composer)
3. `install_phpunit.sh <project>` (PHPUnit, project-local)
4. `install_phpstan.sh <project>` (PHPStan, project-local)

Or with `--global` flag, PHPStan goes to `~/.local/bin/phpstan` instead of
project vendor.

Idempotent — re-running skips what's already installed (each sub-script
checks for existing installs).

Total wall time on a fresh sandbox: **~18 seconds** (5 + 6 + 4 + 3).

## 📚 Reference Documents

Load these when writing or reviewing PHP code:

| File | When to load |
|---|---|
| `references/php-examples.md` | Writing or reviewing PHP 8.x code — covers Enums, Readonly classes, Fibers, Match expressions, Constructor property promotion, Attributes, Named arguments, Nullsafe operator, PDO+SQLite, Error handling, Composer quick start. |
| `references/phpunit-examples.md` | Writing PHPUnit 13.x tests — covers data providers, mocks, exceptions, fixtures, coverage. |
| `references/phpstan-examples.md` | Configuring PHPStan 2.x — covers phpstan.neon options, levels, baseline, ignoreErrors. |

## 🎯 Typical Workflow

```bash
# 1. Install everything
bash /home/z/my-project/skills/php-runner/scripts/install_all.sh

# 2. Set up PATH
export PATH="$HOME/.local/bin:$PATH"

# 3. Create a small project
mkdir -p ~/my-app/src ~/my-app/tests
cd ~/my-app

# 4. Write code (src/Calculator.php)
cat > src/Calculator.php << 'PHP'
<?php
namespace App;
class Calculator {
    public function add(int $a, int $b): int { return $a + $b; }
    public function divide(int $a, int $b): float {
        if ($b === 0) throw new \InvalidArgumentException('Cannot divide by zero');
        return $a / $b;
    }
}
PHP

# 5. Write test (tests/CalculatorTest.php)
cat > tests/CalculatorTest.php << 'PHP'
<?php
namespace App\Test;
use PHPUnit\Framework\TestCase;
use App\Calculator;
class CalculatorTest extends TestCase {
    public function testAdd(): void {
        $calc = new Calculator();
        $this->assertSame(5, $calc->add(2, 3));
    }
    public function testDivideByZeroThrows(): void {
        $calc = new Calculator();
        $this->expectException(\InvalidArgumentException::class);
        $calc->divide(1, 0);
    }
}
PHP

# 6. Run static analysis
php vendor/bin/phpstan analyse src --level=5

# 7. Run tests
php vendor/bin/phpunit tests

# 8. Run tests with coverage (text)
php vendor/bin/phpunit --coverage-text tests
```

## 🔗 Source URLs (validated Nov 2026)

| Component | Source | Version |
|---|---|---|
| PHP | https://www.php.net/downloads.php | 8.5.12 (Oct 21, 2026) |
| PHP source (alt) | https://github.com/php/php-src.git | 8.5.12 |
| Composer | https://getcomposer.org/doc/00-intro.md | 2.11.1 (Oct 30, 2026) |
| PHPUnit | https://phpunit.de/ | 13.x (Feb 6, 2026) |
| PHPUnit getting started | https://phpunit.de/getting-started/phpunit-13.html | 13.0.0+ |
| PHPUnit supported versions | https://phpunit.de/supported-versions.html | 13 ≥ PHP 8.4 |
| PHPStan | https://phpstan.org/ | 2.3 (Oct 6, 2026) |
| PHPStan releases | https://phpstan.org/blog/releases | latest stable |
| PHPStan getting started | https://phpstan.org/user-guide/getting-started | 2.x |
