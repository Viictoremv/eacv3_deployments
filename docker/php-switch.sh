#!/bin/bash
set -e

# Set the PHP version dynamically
PHP_VERSION=${1:-8.2}

# Switch PHP version using alternatives
echo "Switching PHP version to ${PHP_VERSION}..."
alternatives --set php /usr/bin/php${PHP_VERSION}

# Restart PHP-FPM service
systemctl restart php${PHP_VERSION}-php-fpm

echo "PHP version switched to $(php -v | head -n 1)"
