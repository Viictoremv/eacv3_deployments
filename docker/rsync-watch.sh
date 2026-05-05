#!/bin/bash
set -e

while true; do
  rsync -a --delete /mnt/easv3_code/assets/ /var/www/html/assets/
  rsync -a --delete /mnt/easv3_code/src/ /var/www/html/src/
  rsync -a --delete /mnt/easv3_code/templates/ /var/www/html/templates/
  rsync -a --delete /mnt/easv3_code/migrations/ /var/www/html/migrations/
  rsync -a --delete /mnt/easv3_code/public/ /var/www/html/public/
  rsync -a --delete /mnt/easv3_code/tests/ /var/www/html/tests/
  sleep 3
done
