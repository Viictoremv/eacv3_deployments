#!/bin/bash
set -e

# 1) Ensure Symfony/ZIP temp dirs exist and are writable
mkdir -p /var/www/html/var/{cache,log,export,tmp,sessions}
chown -R apache:apache /var/www/html/var
chmod -R ug+rwX /var/www/html/var

# --- Minimal addition: uploads/assets ownership & perms (idempotent) ---
ASSETS_DIR="/var/www/html/assets"
APACHE_USER="apache"
APACHE_GROUP="apache"

mkdir -p "$ASSETS_DIR"

# If running as root, ensure correct owner (fast check to avoid slow full chown)
if [ "$(id -u)" -eq 0 ]; then
  if command -v stat >/dev/null 2>&1; then
    CUR="$(stat -c '%U:%G' "$ASSETS_DIR" 2>/dev/null || echo '')"
  else
    CUR=""
  fi
  if [ "$CUR" != "${APACHE_USER}:${APACHE_GROUP}" ]; then
    echo "$(date +%F\ %T) | 🔧 Fixing ownership on $ASSETS_DIR -> ${APACHE_USER}:${APACHE_GROUP}"
    chown -R "${APACHE_USER}:${APACHE_GROUP}" "$ASSETS_DIR" || true
  fi
else
  echo "$(date +%F\ %T) | ℹ️ Not root; skipping chown on $ASSETS_DIR"
fi

# Group-write + setgid so new files inherit group
chmod 2775 "$ASSETS_DIR" || true

# Encourage group-writable files created by the app
umask 0002
# --- End minimal addition ---

# 2) Point PHP/Composer/libzip temp to our app tmp
mkdir -p /etc/opt/remi/php82/php.d
cat > /etc/opt/remi/php82/php.d/99-temp.ini <<'INI'
sys_temp_dir=/var/www/html/var/tmp
upload_tmp_dir=/var/www/html/var/tmp
INI

# Configure OpenTelemetry auto-prepend for bootstrap
cat > /etc/opt/remi/php82/php.d/99-otel.ini <<'INI'
auto_prepend_file=/var/www/html/config/bootstrap_otel.php
INI

export TMPDIR=/var/www/html/var/tmp

# --- MODE SWITCH ---------------------------------------------------------
# RSYNC_ENABLED=1  => local dev: enable rsync, use .env.local(.php)
# RSYNC_ENABLED!=1 => k8s mode:  disable rsync, use live env from the pod
# -------------------------------------------------------------------------

if [ "${RSYNC_ENABLED:-0}" = "1" ]; then
  # === Local dev mode ===
  echo "$(date +%F\ %T) | 🧩 Mode: LOCAL DEV (RSYNC enabled)"

  # Pre-create critical subdirectories to prevent rsync --delete from removing them
  mkdir -p /var/www/html/assets/{uploads,csv}

  # 3a) Start RSYNC loop (non-fatal on transient errors)
  (
    echo "$(date +%F\ %T) | 🌀 Starting RSYNC sync loop..."
    while true; do
      common_opts="-a --no-o --no-g --delete --exclude .git/ --exclude .hg/ --exclude .svn/ --exclude node_modules/ --exclude vendor/"
      rsync $common_opts --exclude /uploads/ --exclude /csv/  /mnt/easv3_code/assets/     /var/www/html/assets/     || true
      rsync $common_opts                     /mnt/easv3_code/src/        /var/www/html/src/        || true
      rsync $common_opts                     /mnt/easv3_code/templates/  /var/www/html/templates/  || true
      rsync $common_opts                     /mnt/easv3_code/migrations/ /var/www/html/migrations/ || true
      rsync $common_opts                     /mnt/easv3_code/public/     /var/www/html/public/     || true
      rsync $common_opts                     /mnt/easv3_code/tests/      /var/www/html/tests/      || true
      rsync $common_opts                     /mnt/easv3_code/config/     /var/www/html/config/     || true
      sleep 3
    done
  ) &

  # 3b) Local-only override (if present)
  if [ -f /var/www/html/.env.local.override ]; then
    cp -f /var/www/html/.env.local.override /var/www/html/.env.local || true
  fi

  # 3c) Local dev: it’s fine to bake env for speed/consistency
  # composer dump-env dev || true

else
  # === K8S mode ===
  echo "$(date +%F\ %T) | ☸️  Mode: K8S (RSYNC disabled)"
  echo "$(date +%F\ %T) | ⏭️ RSYNC loop disabled (RSYNC_ENABLED!=1)"

  # Ensure K8S env vars are visible to PHP-FPM
  cat >/etc/opt/remi/php82/php-fpm.d/zz-env.conf <<'CONF'
; Keep pod env vars available to PHP-FPM workers
clear_env = no
catch_workers_output = yes
CONF

  # Critical: never mask K8S env with compiled/file envs from the image
  rm -f /var/www/html/.env.local.php /var/www/html/.env.local || true

  # Do NOT copy .env.local.override in K8S mode (env comes from envFrom)
fi

UPLOADS_DIR=/var/www/html/assets/uploads
chown -R apache:apache "$UPLOADS_DIR"
chmod -R 775 "$UPLOADS_DIR"

# --- Ensure CSV export directory exists ---
CSV_DIR=/var/www/html/assets/csv
mkdir -p "$CSV_DIR"
chown -R apache:apache "$CSV_DIR"
chmod -R 775 "$CSV_DIR"

# 4) Warm/clear cache (non-fatal)
php bin/console cache:clear || true

echo "$(date +"%F %T") | 🔧 Restoring file-based session handler..."

cat > /etc/opt/remi/php82/php.d/99-session.ini <<'EOF'
session.save_handler = files
session.save_path = "/var/www/html/var/sessions"
session.locking_enabled = 1
EOF

echo "$(date +"%F %T") | 🔧 Final permission normalize (PVC aware)..."
find /var/www/html/var -type d -exec chmod 775 {} \;
find /var/www/html/var -type f -exec chmod 664 {} \;
chown -R apache:apache /var/www/html/var

# 5) Start PHP-FPM (only if not already running), then Apache
echo "$(date +"%F %T") | ▶️ Starting PHP-FPM and Apache..."
pgrep -x php-fpm >/dev/null || /opt/remi/php82/root/usr/sbin/php-fpm
exec /usr/sbin/httpd -D FOREGROUND