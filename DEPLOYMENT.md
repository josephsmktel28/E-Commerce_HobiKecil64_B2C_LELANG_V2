# HobiKecil E-Commerce - Docker & Render Deployment Guide

## Prerequisites

- Docker & Docker Compose (untuk local development)
- Git account dengan GitHub
- Render.com account
- Aiven account dengan PostgreSQL database

## Project Structure

```
.
├── Dockerfile                 # Docker image configuration
├── docker-compose.yml        # Local development environment
├── docker/
│   ├── entrypoint.sh        # Container startup script
│   ├── nginx.conf           # Nginx web server config
│   ├── php-fpm.conf         # PHP-FPM configuration
│   └── supervisord.conf     # Process management
├── render.yaml              # Render.com deployment config
├── .env.render             # Production environment variables
└── .dockerignore           # Docker build exclusions
```

## Local Development dengan Docker

### 1. Setup Local Environment

```bash
# Clone repository
git clone <your-github-repo>
cd HobiKecil64-ECOM_fix

# Copy environment file
cp .env.example .env

# Update database credentials in .env
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=hobikecil
DB_USERNAME=hobikecil
DB_PASSWORD=password
```

### 2. Build dan Run dengan Docker Compose

```bash
# Build Docker image
docker-compose build

# Start services (app, PostgreSQL, Redis)
docker-compose up -d

# Run migrations
docker-compose exec app php artisan migrate

# Seed database (optional)
docker-compose exec app php artisan db:seed

# Clear cache
docker-compose exec app php artisan cache:clear
```

### 3. Access Application

- **Application**: http://localhost:8080
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 4. Useful Docker Commands

```bash
# View logs
docker-compose logs -f app

# Execute Artisan command
docker-compose exec app php artisan <command>

# Stop services
docker-compose down

# Remove volumes (clean database)
docker-compose down -v

# Rebuild images
docker-compose build --no-cache
```

## Deployment ke Render.com

### Step 1: Push ke GitHub

```bash
# Initialize git repository (jika belum)
git init
git add .
git commit -m "Initial commit: Docker setup for Render deployment"

# Add GitHub remote (ganti YOUR_USERNAME dan REPO_NAME)
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# Push ke GitHub
git branch -M main
git push -u origin main
```

### Step 2: Setup Aiven PostgreSQL Database

1. Login ke [Aiven Console](https://console.aiven.io)
2. Buat PostgreSQL service baru
3. Catat credentials:
   - **Host**: kafka-fc21c78-joseph-2246.d.aivencloud.com
   - **Port**: 25046
   - **Username**: avnadmin
   - **Password**: (dari Aiven dashboard)
   - **Database**: defaultdb

### Step 3: Deploy ke Render

#### Opsi A: Manual Deployment

1. Login ke [Render.com](https://render.com)
2. Click **New +** → **Web Service**
3. Hubungkan GitHub repository
4. Configure:
   - **Name**: `hobikecil-ecom`
   - **Runtime**: `Docker`
   - **Build Command**: (leave empty - uses Dockerfile)
   - **Start Command**: (leave empty - uses entrypoint.sh)
5. Add environment variables di **Environment**:

```
APP_NAME=HobiKecil
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:YOUR_APP_KEY_HERE
APP_URL=https://YOUR_RENDER_URL.onrender.com

DB_CONNECTION=pgsql
DB_HOST=kafka-fc21c78-joseph-2246.d.aivencloud.com
DB_PORT=25046
DB_DATABASE=defaultdb
DB_USERNAME=avnadmin
DB_PASSWORD=YOUR_AIVEN_PASSWORD

MAIL_MAILER=smtp
MAIL_HOST=YOUR_SMTP_HOST
MAIL_PORT=587
MAIL_USERNAME=YOUR_MAIL_USERNAME
MAIL_PASSWORD=YOUR_MAIL_PASSWORD
```

6. Click **Create Web Service**

#### Opsi B: Render with render.yaml (Recommended)

```bash
# Edit render.yaml dan set configuration Anda
# Kemudian push ke GitHub

git add render.yaml
git commit -m "Update render.yaml configuration"
git push
```

Di Render dashboard, pilih **New +** → **Web Service** dan select repository. Render akan otomatis membaca `render.yaml`.

### Step 4: Setup Database

Setelah deployment pertama kali:

```bash
# SSH ke Render service
render logs --service=hobikecil-ecom

# Atau gunakan Render Dashboard untuk run:
# - Migrations: php artisan migrate
# - Seeders: php artisan db:seed
# - Cache: php artisan config:cache
```

### Step 5: Configure Custom Domain (Optional)

1. Di Render service settings
2. Pilih **Settings** → **Custom Domain**
3. Add domain Anda
4. Update DNS records sesuai instruksi Render

## Troubleshooting

### Database Connection Failed

```bash
# Check database credentials
# Ensure Aiven PostgreSQL allows connections from Render IPs

# Re-run migrations
php artisan migrate --force

# Seed database
php artisan db:seed --force
```

### APP_KEY not set

```bash
# Generate new APP_KEY
php artisan key:generate --force

# Copy output dan set di Render environment variables
```

### File Upload Issues

- Check `storage/` directory permissions
- Configure AWS S3 atau Render Disk untuk production storage
- Update `FILESYSTEM_DISK` di `.env.render`

### Performance Issues

- Enable query caching: `CACHE_STORE=database`
- Use Redis jika available
- Configure supervisord worker pools di `docker/supervisord.conf`

## Security Checklist

- [ ] Set `APP_DEBUG=false` di production
- [ ] Set strong `DB_PASSWORD` di Aiven
- [ ] Enable SSL/HTTPS di Render
- [ ] Set `MAIL_ENCRYPTION=tls` untuk email
- [ ] Review dan set proper permissions di `.env`
- [ ] Regular backups dari Aiven PostgreSQL
- [ ] Monitor logs di Render dashboard

## Monitoring

1. **Render Dashboard**:
   - View logs in real-time
   - Monitor CPU/Memory usage
   - Check deployment history

2. **Application Logs**:
   ```bash
   # View in Render or locally:
   storage/logs/laravel.log
   ```

3. **Database**:
   - Monitor di Aiven Console
   - Check query performance
   - Backup configuration

## Update dan Deployment Workflow

```bash
# 1. Make changes locally
# 2. Test dengan docker-compose
docker-compose up -d
docker-compose exec app php artisan test

# 3. Commit dan push
git add .
git commit -m "Feature: description"
git push origin main

# 4. Render akan otomatis deploy
# 5. Monitor di Render dashboard
```

## Support & Documentation

- [Laravel Documentation](https://laravel.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Render Documentation](https://render.com/docs)
- [Aiven Documentation](https://aiven.io/docs)

---

**Last Updated**: 2026-06-09
**Laravel Version**: 11.5.0
**PHP Version**: 8.2
