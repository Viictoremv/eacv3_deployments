#!/bin/bash

set -e

MIGRATION_MARKER="/var/www/html/var/.migrations-completed"

# Check for marker file
if [ -f "$MIGRATION_MARKER" ]; then
    echo "🔄 Migrations have already been run. Skipping..."
    exit 0
fi

echo "🧹 Clearing Symfony cache..."
php bin/console cache:clear || {
  echo "❌ Failed to clear cache"
  exit 1
}

# # Fix PSR-4 test namespace issues
# echo "🔧 Fixing PSR-4 test namespaces..."
# find ./tests -name "*Test.php" -type f -exec sed -i '' 's/namespace App\Tests\\/namespace App\\Tests\\/g' {} +

echo "📜 Running all pending Doctrine migrations..."
if ! php bin/console doctrine:migrations:migrate --no-interaction; then
  echo "❌ Doctrine migrations failed." >&2
  exit 1
fi

echo
echo "🚀 Running post-migration application commands..."

FAILED_COMMANDS=()
COMMANDS=(
  "app:convert-drug-countries"
  "app:convert-drug-documents"
  "app:convert-drug-resource-docs"
  "app:convert-last-doc-types"
  "app:convert-rid-status"
  "app:fill-permission"
  "app:fill-role-permission"
  "app:fill-user-group-role"
)

for CMD in "${COMMANDS[@]}"; do
  echo "➡️ php bin/console $CMD"
  if ! php bin/console "$CMD" --no-interaction; then
    echo "❌ Command failed: $CMD" >&2
    FAILED_COMMANDS+=("$CMD")
  fi
done

echo
echo "✅ Script finished."

if [ ${#FAILED_COMMANDS[@]} -ne 0 ]; then
  echo "❗ Post-migration commands failed:"
  for CMD in "${FAILED_COMMANDS[@]}"; do
    echo "  - $CMD"
  done
  exit 1
fi

# Create marker file only if everything succeeds
touch "$MIGRATION_MARKER"
echo "🎉 All migrations and post-migration steps completed successfully."
