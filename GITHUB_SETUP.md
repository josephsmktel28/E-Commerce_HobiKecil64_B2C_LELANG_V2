# 📋 Step-by-Step GitHub & Render Deployment Guide

## Phase 1: GitHub Setup

### Step 1.1: Create GitHub Repository

1. **Go to GitHub** - https://github.com/new
2. **Fill in the form**:
   - Repository name: `HobiKecil64-ECOM_fix` (or your preferred name)
   - Description: `E-Commerce Platform for HobiKecil`
   - Visibility: **Public** (untuk dapat menggunakan Render dengan free tier)
   - Initialize repository: ✅ **Do not initialize** (kita punya files lokal)

3. **Click "Create repository"**

### Step 1.2: Get Your Repository URL

Setelah create, Anda akan mendapat URL seperti:
```
https://github.com/YOUR_USERNAME/HobiKecil64-ECOM_fix.git
```

---

## Phase 2: Prepare Local Git Repository

### Step 2.1: Initialize Git (Windows PowerShell)

```powershell
# Navigate to project directory
cd C:\E_Commerce_hobikecil64\HobiKecil64-ECOM_fix

# Initialize git repository
git init

# Configure git (ganti dengan data Anda)
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Verify configuration
git config --list
```

### Step 2.2: Add All Files

```powershell
# Add all files
git add .

# Check status
git status
```

Anda seharusnya melihat file-file berikut dalam "Changes to be committed":
- `Dockerfile`
- `docker-compose.yml`
- `docker/nginx.conf`
- `docker/php-fpm.conf`
- `docker/supervisord.conf`
- `docker/entrypoint.sh`
- `render.yaml`
- `.env.render`
- `.dockerignore`
- `DEPLOYMENT.md`
- `.github/workflows/ci-cd.yml`
- `quick-start.sh`

### Step 2.3: Create Initial Commit

```powershell
# Commit semua files
git commit -m "Initial commit: Docker setup for Render deployment"

# Verify commit
git log
```

### Step 2.4: Add Remote Repository

```powershell
# Replace YOUR_USERNAME dan REPO_NAME dengan milik Anda
git remote add origin https://github.com/YOUR_USERNAME/HobiKecil64-ECOM_fix.git

# Verify remote
git remote -v
```

### Step 2.5: Push ke GitHub

```powershell
# Rename default branch to main (jika diperlukan)
git branch -M main

# Push ke GitHub (input username & password/token)
git push -u origin main
```

**Jika diminta password**, gunakan **Personal Access Token**:
1. Go to https://github.com/settings/tokens
2. Click "Generate new token"
3. Select scopes: `repo`, `workflow`
4. Generate dan copy token
5. Paste sebagai password di terminal

---

## Phase 3: Aiven Database Setup

### Step 3.1: Get Aiven Credentials

1. **Login ke** https://console.aiven.io
2. **Cari PostgreSQL service**
3. **Copy credentials**:
   - Host: `kafka-fc21c78-joseph-2246.d.aivencloud.com`
   - Port: `25046`
   - Username: `avnadmin` (atau sesuai akun Anda)
   - Password: (dari dashboard)
   - Database: `defaultdb`

### Step 3.2: Setup Aiven Network Access

1. **Di Aiven Console**, buka PostgreSQL service Anda
2. **Pilih "Connection pools" atau "Firewall"**
3. **Add IP addresses yang diizinkan**:
   - Render.com IPs (lihat di Render docs)
   - Atau: `0.0.0.0/0` (allow all - less secure)

---

## Phase 4: Render.com Deployment

### Step 4.1: Connect GitHub Repository

1. **Login ke** https://render.com
2. **Click "New +"** → **"Web Service"**
3. **Select "GitHub"**
4. **Authorize GitHub** (jika diminta)
5. **Select repository**: `HobiKecil64-ECOM_fix`

### Step 4.2: Configure Web Service

1. **Basic Settings**:
   - Name: `hobikecil-ecom` (atau sesuai pilihan)
   - Runtime: `Docker`
   - Region: `Singapore` (atau pilihan terdekat dengan user Anda)
   - Branch: `main`

2. **Build & Deploy**:
   - Build Command: (leave empty - gunakan Dockerfile)
   - Start Command: (leave empty - gunakan entrypoint.sh)

3. **Plan**: 
   - Free (jika tersedia)
   - atau Starter ($7/month)

### Step 4.3: Set Environment Variables

Di Render Dashboard, buka Web Service Anda:

1. **Pilih "Environment"**
2. **Add environment variables**:

```
APP_NAME=HobiKecil
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=UTC
APP_URL=https://hobikecil-ecom.onrender.com

DB_CONNECTION=pgsql
DB_HOST=kafka-fc21c78-joseph-2246.d.aivencloud.com
DB_PORT=25046
DB_DATABASE=defaultdb
DB_USERNAME=avnadmin
DB_PASSWORD=YOUR_AIVEN_PASSWORD_HERE

LOG_CHANNEL=stack
LOG_LEVEL=error

SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database

MAIL_MAILER=smtp
MAIL_HOST=YOUR_SMTP_HOST
MAIL_PORT=587
MAIL_USERNAME=YOUR_MAIL_USERNAME
MAIL_PASSWORD=YOUR_MAIL_PASSWORD
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@hobikecil.com
MAIL_FROM_NAME=HobiKecil

VITE_APP_NAME=HobiKecil
```

### Step 4.4: Generate APP_KEY

Sebelum deploy, buat APP_KEY baru:

```powershell
# Generate key lokal
php artisan key:generate

# Copy value dari .env
# Contoh output: APP_KEY=base64:xxxxxxxxxxxx...
```

Add ke Render environment variables:
```
APP_KEY=base64:xxxxxxxxxxxx...
```

### Step 4.5: Deploy

1. **Click "Create Web Service"**
2. **Tunggu build process** (biasanya 5-15 menit)
3. **Monitoring di Render Dashboard**:
   - Logs tab untuk melihat output
   - Deployments tab untuk history

### Step 4.6: Database Migration

Setelah initial deployment berhasil:

1. **Option A - Render Shell**:
   - Di Render Dashboard, buka Web Service
   - Click "Shell"
   - Run: `php artisan migrate`

2. **Option B - Connect Langsung dari Local**:
   ```powershell
   # Install psql client (jika belum)
   # Untuk Windows: https://www.postgresql.org/download/windows/
   
   # Connect ke Aiven PostgreSQL
   psql -h kafka-fc21c78-joseph-2246.d.aivencloud.com -p 25046 -U avnadmin -d defaultdb
   ```

---

## Phase 5: Testing Deployment

### Step 5.1: Check Application Status

1. **Render Dashboard**:
   - Check "Status" - seharusnya "Live"
   - Check "Open URL" untuk akses aplikasi

2. **Health Check**:
   ```
   https://hobikecil-ecom.onrender.com/health
   ```

### Step 5.2: Troubleshooting

**Jika build gagal**:
- Check Logs di Render Dashboard
- Verify Dockerfile syntax
- Ensure all dependencies di composer.json

**Jika aplikasi error**:
- Check .env variables
- Verify database connection
- Run migrations: SSH ke Render → `php artisan migrate`

**Jika database tidak connect**:
- Verify host/port/credentials
- Check Aiven firewall rules
- Test connection lokal: `psql -h host -p port -U user -d database`

---

## Phase 6: GitHub Actions & CI/CD

Workflow file sudah dibuat di `.github/workflows/ci-cd.yml`:

1. **Test** - Run unit tests
2. **Build** - Build Docker image
3. **Deploy** - Deploy ke Render (optional)

### Setup GitHub Secrets

1. **Go to** GitHub Repository → Settings → Secrets and variables → Actions
2. **Add secrets**:
   ```
   RENDER_API_KEY = <dari Render account settings>
   RENDER_SERVICE_ID = <dari Render service>
   ```

---

## Phase 7: Continuous Deployment Workflow

Setelah setup selesai, workflow untuk update:

### Make Changes

```powershell
# Edit files lokal
# Test dengan docker-compose
docker-compose up -d
docker-compose exec app php artisan test
```

### Push to GitHub

```powershell
git add .
git commit -m "Feature: description"
git push origin main
```

### Automatic Deployment

1. **GitHub Actions** akan:
   - Run tests (5-10 menit)
   - Build Docker image
   - Deploy ke Render (jika tests passed)

2. **Monitor di**:
   - GitHub: Actions tab
   - Render: Deployments tab

---

## Rollback

Jika ada masalah dengan deployment:

### Via Render Dashboard

1. Go to Web Service → Deployments
2. Click deployment sebelumnya
3. Click "Redeploy"

### Via Git

```powershell
# Revert last commit
git revert HEAD

# Push
git push origin main

# Render akan otomatis deploy ulang
```

---

## Maintenance & Monitoring

### Daily Tasks

- Monitor Render Dashboard
- Check application logs
- Monitor Aiven database performance

### Weekly Tasks

- Review error logs
- Test core functionality
- Backup database

### Security

- Rotate secrets regularly
- Update dependencies: `composer update`
- Monitor security advisories

---

## Support Commands

```powershell
# Local Development
docker-compose logs -f app          # View logs
docker-compose exec app php artisan tinker  # Interactive shell
docker-compose exec app php artisan migrate # Run migrations

# Remote (Render Shell)
php artisan config:cache           # Cache config
php artisan migrate                # Run migrations
php artisan db:seed                # Seed database
php artisan clear-all              # Clear all cache

# Git
git status                         # Check status
git log                           # View commits
git diff                          # View changes
git branch -a                     # List branches
```

---

## Final Checklist

- [ ] GitHub repository dibuat dan linked
- [ ] All Docker files created dan committed
- [ ] Aiven PostgreSQL database setup
- [ ] Render.com account active
- [ ] Web Service created di Render
- [ ] Environment variables set
- [ ] Database migrations run
- [ ] Application accessible via URL
- [ ] Health check endpoint working
- [ ] GitHub Actions workflows active
- [ ] Monitoring setup complete

---

**Jika ada masalah?, Lihat DEPLOYMENT.md untuk informasi lebih detail!**

