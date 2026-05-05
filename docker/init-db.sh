# init-db.sh (Database Initialization Script)
#!/bin/bash
set -e

if [ -z "$(ls -A /var/lib/mysql)" ]; then
    echo "Database is empty. Downloading SQL dump from Azure..."
    wget -O /tmp/dump.sql $AZURE_BLOB_URL
    mysql -uroot -p$MYSQL_ROOT_PASSWORD eas_v3parent < /tmp/dump.sql
    echo "Database import complete."
else
    echo "Database already exists. Skipping initialization."
fi