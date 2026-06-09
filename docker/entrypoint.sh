#!/bin/sh
set -e

# Wait for database to be ready
if [ "$DB_HOST" ]; then
    echo "Waiting for database at $DB_HOST:$DB_PORT..."
    max_retries=30
    retry=0
    until mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" 2>/dev/null || [ $retry -eq $max_retries ]; do
        retry=$((retry + 1))
        echo "Database not ready, attempt $retry/$max_retries..."
        sleep 1
    done
    
    if [ $retry -eq $max_retries ]; then
        echo "Database connection failed after $max_retries attempts"
        exit 1
    fi
    echo "Database is ready!"
fi

# Generate APP_KEY if not set
if [ -z "$APP_KEY" ]; then
    echo "Generating APP_KEY..."
    php artisan key:generate --force
fi

# Run migrations
echo "Running migrations..."
php artisan migrate --force

# Clear and cache configuration
echo "Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Fix permissions
chmod -R 775 storage bootstrap/cache

# Start supervisor
echo "Starting application..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
