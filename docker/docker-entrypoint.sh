#!/bin/bash
set -e

echo "📦 Waiting for the database to be ready..."

until php bin/console doctrine:query:sql "SELECT 1" > /dev/null 2>&1; do
  echo "⏳ Still waiting for DB..."
  sleep 2
done

echo "✅ Database is up."

echo "🔍 Verifying Doctrine server version config..."
echo "Current DATABASE_URL: $DATABASE_URL"

if [[ "$DATABASE_URL" != *"serverVersion="* ]]; then
    echo "⚠️  No serverVersion found in DATABASE_URL, appending ?serverVersion=9.3"
    export DATABASE_URL="$DATABASE_URL?serverVersion=9.3"
else
    echo "✅ serverVersion is already present."
fi


if [ "$APP_ENV" != "prod" ]; then
  echo "📜 Running migrations for $APP_ENV environment..."
  php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration
else
  echo "🚫 Skipping migrations in production mode."
fi

echo "🚀 Starting application..."
exec "$@"
