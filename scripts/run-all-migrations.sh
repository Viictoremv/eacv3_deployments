#!/bin/bash
set -e

# --- DB readiness check (with timeout) ---
wait_for_db() {
  echo "⏳ Waiting for MySQL to be ready..."

  MAX_WAIT=300  # 5 minutes
  COUNTER=0

  until mysqladmin ping -h"$DATABASE_HOST" --silent; do
    sleep 2
    COUNTER=$((COUNTER+2))
    if [ $COUNTER -ge $MAX_WAIT ]; then
      echo "❌ MySQL did not become ready in time. Exiting."
      exit 1
    fi
  done

  echo "✅ MySQL is ready."
}

# --- Validation of required DB variables ---
validate_db_env() {
  REQUIRED_VARS=("DATABASE_HOST" "DATABASE_USER" "DATABASE_PASSWORD" "DATABASE_NAME")

  for VAR in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!VAR}" ]]; then
      echo "❌ Missing required DB variable: $VAR (check .env.local.override)"
      exit 1
    fi
  done
}

run_migrations() {
  APP_NAME="$1"
  APP_PATH="$2"

  echo "🔍 Checking $APP_NAME for pending Doctrine migrations..."

  cd "$APP_PATH"

  if [[ ! -f "bin/console" ]]; then
    echo "⚠️  Skipping $APP_NAME: no Symfony console found at $APP_PATH"
    return
  fi
 
  # Load environment variables
  set -o allexport
  source .env.local.override
  set +o allexport

  # --- Validate DB env vars before connecting ---
  validate_db_env

  # --- Wait for MySQL to be ready before Doctrine touches it ---
  wait_for_db

  PENDING=$(php bin/console doctrine:migrations:status --no-interaction | grep "New" | awk '{print $5}')

  if [[ "$PENDING" == "0" ]]; then
    echo "✅ [$APP_NAME] No new migrations to run."
  else
    echo "⚠️  [$APP_NAME] $PENDING new migration(s) found. Running now..."
    php -d memory_limit=1G bin/console doctrine:migrations:migrate --no-interaction
    echo "✅ [$APP_NAME] Migrations completed successfully."
  fi
}

run_migrations "Child App" "/workspace/child"
run_migrations "Parent App" "/workspace/parent"

echo "🏁 All migrations checked."