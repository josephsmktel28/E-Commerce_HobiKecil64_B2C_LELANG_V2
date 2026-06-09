#!/bin/sh
set -e

echo "=========================================="
echo "  HobiKecil - Starting Deployment"
echo "=========================================="

# ---- Render PORT ----
# Render passes the PORT env var. Default to 10000.
PORT="${PORT:-10000}"
echo "[1/6] Configuring nginx to listen on port $PORT..."
sed -i "s/__RENDER_PORT__/$PORT/g" /etc/nginx/nginx.conf

# ---- Storage directories ----
echo "[2/6] Ensuring storage directories exist..."
mkdir -p \
    storage/logs \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/app/public \
    bootstrap/cache
chmod -R 775 storage bootstrap/cache

# ---- Storage link ----
echo "[3/6] Creating storage symlink..."
php artisan storage:link --force 2>/dev/null || true

# ---- APP_KEY ----
if [ -z "$APP_KEY" ]; then
    echo "[!] APP_KEY not set — generating one..."
    php artisan key:generate --force
fi

# ---- Database Migration ----
echo "[4/6] Running database migrations..."
max_retries=5
retry=0
until php artisan migrate --force 2>/dev/null; do
    retry=$((retry + 1))
    if [ $retry -ge $max_retries ]; then
        echo "[WARNING] Migration failed after $max_retries attempts. Continuing anyway..."
        break
    fi
    echo "  Migration attempt $retry/$max_retries failed. Retrying in 5s..."
    sleep 5
done

# ---- Cache config/routes/views ----
echo "[5/6] Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# ---- Start Supervisor (nginx + php-fpm) ----
echo "[6/6] Starting application on port $PORT..."
echo "=========================================="
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
