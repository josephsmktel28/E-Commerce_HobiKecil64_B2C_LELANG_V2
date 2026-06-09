#!/bin/bash

# HobiKecil E-Commerce Quick Start Script
# This script sets up the project for development with Docker

set -e

echo "🚀 HobiKecil E-Commerce - Quick Start Setup"
echo "=========================================="

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Setup environment
echo ""
echo "📝 Setting up environment..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created .env file from .env.example"
else
    echo "ℹ️  .env file already exists"
fi

# Build Docker images
echo ""
echo "🏗️  Building Docker images..."
docker-compose build

# Start services
echo ""
echo "▶️  Starting services..."
docker-compose up -d

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Install dependencies
echo ""
echo "📦 Installing PHP dependencies..."
docker-compose exec -T app composer install

# Generate APP_KEY
echo ""
echo "🔑 Generating APP_KEY..."
docker-compose exec -T app php artisan key:generate

# Run migrations
echo ""
echo "🗄️  Running database migrations..."
docker-compose exec -T app php artisan migrate

# Seed database
echo ""
read -p "Would you like to seed the database? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose exec -T app php artisan db:seed
fi

# Clear cache
echo ""
echo "🧹 Clearing cache..."
docker-compose exec -T app php artisan cache:clear
docker-compose exec -T app php artisan config:clear

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "📱 Your application is ready at: http://localhost:8080"
echo ""
echo "Useful commands:"
echo "  - View logs:          docker-compose logs -f app"
echo "  - Run Artisan:        docker-compose exec app php artisan <command>"
echo "  - Stop services:      docker-compose down"
echo "  - Remove volumes:     docker-compose down -v"
echo ""
echo "Documentation: See DEPLOYMENT.md for more information"
echo ""
