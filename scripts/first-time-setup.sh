#!/bin/bash
set -euo pipefail

die(){ echo "❌ $*" >&2; exit 1; }
banner(){ echo -e "\n===== $* =====\n"; }

LOCK_FILE="/mnt/easv3_code/.cloned"

echo "⚠️  WARNING: This will erase existing contents in /mnt/easv3_code and /mnt/easv3parent_code"
read -p "Continue? (y/N): " confirm
if [[ "${confirm:-}" != "y" ]]; then
  echo "Aborted."
  exit 1
fi

# ------------------------------------------------------------------
# Prep workspace folders safely (avoid 'Device or resource busy')
# ------------------------------------------------------------------
cd /  # leave /workspace so bind mounts aren't "busy" while we rm
sudo mkdir -p /workspace/child /workspace/parent
sudo chown -R dev:dev /workspace/child /workspace/parent || true
sudo chmod -R 775      /workspace/child /workspace/parent || true
sudo rm -rf /workspace/child/{*,.[!.]*} /workspace/parent/{*,.[!.]*} 2>/dev/null || true

# ------------------------------------------------------------------
# Import host git identity (if mounted) + mark repos safe
# ------------------------------------------------------------------
HOST_GITCFG="/mnt/host_git/.gitconfig"

get_host_git() {
  git config --file "$HOST_GITCFG" --get "$1" 2>/dev/null || true
}

if [[ -f "$HOST_GITCFG" ]]; then
  NAME="$(get_host_git user.name)"
  EMAIL="$(get_host_git user.email)"
  [[ -n "${NAME:-}"  ]] && git config --global user.name  "$NAME"
  [[ -n "${EMAIL:-}" ]] && git config --global user.email "$EMAIL"
  AUTOSIGN="$(get_host_git commit.gpgsign)"
  [[ -n "${AUTOSIGN:-}" ]] && git config --global commit.gpgsign "$AUTOSIGN"

  echo "✅ Copied Git identity from host into container:"
  git config --global --list | grep -E '^(user\.name|user\.email|user\.signingkey|gpg\.format|init\.defaultBranch|commit\.gpgsign)=' || true
else
  echo "ℹ️  No host ~/.gitconfig mounted at $HOST_GITCFG; skipping identity import."
fi

# Avoid permission noise inside container repos
git config --global core.filemode false
git config --global --add safe.directory /workspace/child
git config --global --add safe.directory /workspace/parent

# Prefer dist globally (defense-in-depth against vendor/.git)
composer config -g preferred-install dist || true

# ------------------------------------------------------------------
# Clone both repos
# ------------------------------------------------------------------
banner "Cloning repositories"
git clone git@github.com:Early-Access-Care-LLC/eacv3.git       /workspace/child
git clone git@github.com:Early-Access-Care-LLC/easv3parent.git /workspace/parent

# Project-specific env overrides (optional)
sudo cp -f /workspace/env/child/.env.local.override  /workspace/child/.env.local.override  2>/dev/null || true
sudo cp -f /workspace/env/parent/.env.local.override /workspace/parent/.env.local.override 2>/dev/null || true

# Add lockfile markers
touch /workspace/child/.cloned
touch /workspace/parent/.cloned

# Install Node.js native module build dependencies (Python + build tools)
banner "Installing Node.js native module build dependencies"

# Install Python and build tools required for canvas, node-gyp, etc.
if ! command -v python3 &> /dev/null; then
  echo "⏳ Installing Python 3 and build tools..."
  sudo dnf install -y python3 python3-devel gcc gcc-c++ make cairo-devel jpeg-devel giflib-devel pixman-devel || \
    echo "⚠️  Warning: Some build dependencies failed to install, canvas compilation may fail"
else
  PYTHON_VER=$(python3 --version 2>&1 | awk '{print $2}')
  echo "✅ Python $PYTHON_VER already installed"
fi

# ------------------------------------------------------------------
# Install required PHP extensions BEFORE composer install
# ------------------------------------------------------------------
banner "Installing required PHP extensions"

# Install sodium and zip extensions (required by composer packages)
sudo dnf install -y php82-php-sodium php82-php-zip || die "Failed to install PHP extensions"

# Build deps for PECL extensions
sudo dnf install -y gcc make php82-php-devel php82-php-pear || die "Failed to install build deps"

# PECL tools
sudo ln -sf /opt/remi/php82/root/usr/bin/phpize /usr/bin/phpize
sudo ln -sf /opt/remi/php82/root/usr/bin/pecl   /usr/bin/pecl

# Install OpenTelemetry extension
sudo pecl install opentelemetry || echo "⚠️ PECL installation of OpenTelemetry failed"

# Enable extensions (correct Remi PHP path)
echo "extension=opentelemetry.so" | sudo tee /etc/opt/remi/php82/php.d/60-opentelemetry.ini >/dev/null

# Force CLI to use Remi PHP
export PATH="/opt/remi/php82/root/usr/bin:$PATH"

# Verify extensions are loaded
php -m | grep -i opentelemetry && \
  echo "✅ OpenTelemetry successfully installed in dev container" || \
  echo "⚠️ OpenTelemetry extension not detected in php -m"

php -m | grep -i sodium && \
  echo "✅ Sodium extension enabled" || \
  echo "⚠️ Sodium extension not detected"

php -m | grep -i zip && \
  echo "✅ Zip extension enabled" || \
  echo "⚠️ Zip extension not detected"

# Install MySQL client tools (for migrations script mysqladmin)
sudo dnf install -y mysql || die "Failed to install mysql client tools"
echo "✅ MySQL client tools installed"

# ------------------------------------------------------------------
# Ensure wrapper bin dir exists and on PATH now + later shells
# ------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

# ------------------------------------------------------------------
# Per-project install (isolated caches; deterministic install)
# ------------------------------------------------------------------
install_project () {
  local dir="$1" name="$2"
  banner "Installing ${name} dependencies"

  # Isolated caches per project
  export COMPOSER_CACHE_DIR="/home/dev/.cache/composer-${name}"
  export npm_config_cache="/home/dev/.cache/npm-${name}"

  pushd "$dir" >/dev/null

  # Keep composer.lock (deterministic). Just clear vendor if present.
  rm -rf vendor

  # Disable xdebug while installing to reduce noise & speed things up
  export XDEBUG_MODE=off
  composer clear-cache || true
  COMPOSER_MEMORY_LIMIT=-1 composer install \
    --prefer-dist --no-scripts --no-progress --no-interaction

  if [[ -f package.json ]]; then
    # Check if package-lock.json is in sync with package.json
    if [[ -f package-lock.json || -f npm-shrinkwrap.json ]]; then
      echo "⏳ Attempting clean install with npm ci..."
      # Try npm ci first, but if it fails due to lock file sync issues, regenerate lock file
      if npm ci --legacy-peer-deps 2>/dev/null; then
        echo "✅ npm ci succeeded"
      else
        echo "⚠️  package-lock.json out of sync with package.json, regenerating lock file..."
        rm -f package-lock.json npm-shrinkwrap.json
        npm install --legacy-peer-deps
        echo "✅ Lock file regenerated successfully"
      fi
    else
      echo "⏳ No lock file found, performing fresh npm install..."
      npm install --legacy-peer-deps
    fi
    echo "⏳ Building assets..."
    npm run build || true
  fi

  # Purge any nested Git repos under vendor that confuse Git/VS Code
  find vendor -type d -name .git -prune -exec rm -rf {} + 2>/dev/null || true

  # Create per-project phpunit wrapper in ~/.local/bin
  cat > "$HOME/.local/bin/${name}-phpunit" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd /workspace/CHANGEME
export XDEBUG_MODE=coverage
exec php -dopcache.enable_cli=0 vendor/bin/phpunit "$@"
EOF
  sed -i "s|CHANGEME|${name}|" "$HOME/.local/bin/${name}-phpunit"
  chmod +x "$HOME/.local/bin/${name}-phpunit"

  popd >/dev/null
}

install_project /workspace/child  child
install_project /workspace/parent parent

echo "✅ Repos cloned and dependencies installed."

# ------------------------------------------------------------------
# VS Code extensions (works when connected via VS Code Remote-SSH)
# ------------------------------------------------------------------
code --install-extension esbenp.prettier-vscode             || true
code --install-extension GitHub.copilot-chat                || true
code --install-extension GitHub.vscode-pull-request-github  || true
code --install-extension hbenl.vscode-test-explorer         || true
code --install-extension kisstkondoros.vscode-codemetrics   || true
code --install-extension mblode.twig-language-2             || true
code --install-extension ms-playwright.playwright           || true
code --install-extension ms-vscode.live-server              || true
code --install-extension ms-vscode.test-adapter-converter   || true

banner "Done. Try:  child-phpunit --version   or   parent-phpunit --version"