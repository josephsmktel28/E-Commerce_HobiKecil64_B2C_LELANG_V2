# Stage 1: Build Stage
FROM php:8.2-fpm-alpine as builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    zip \
    unzip \
    git \
    nodejs \
    npm \
    mysql-client \
    mysql-dev

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    gd \
    bcmath \
    ctype \
    json \
    mbstring \
    openssl \
    tokenizer \
    xml

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy composer files
COPY composer.json composer.lock* ./

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# Copy application files
COPY . .

# Build assets with Vite
RUN npm install
RUN npm run build

# Stage 2: Runtime Stage
FROM php:8.2-fpm-alpine

# Install runtime dependencies (no dev libs)
RUN apk add --no-cache \
    libpng \
    libjpeg-turbo \
    freetype \
    mysql-client \
    supervisor \
    nginx

# Install PHP extensions (minimal set, no build-base)
RUN docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    gd \
    bcmath \
    ctype \
    json \
    mbstring \
    openssl \
    tokenizer \
    xml

# Set working directory
WORKDIR /app

# Copy from builder stage
COPY --from=builder /app /app
COPY --from=builder /usr/bin/composer /usr/bin/composer

# Create necessary directories
RUN mkdir -p storage/logs bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy configuration files
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# Create app user
RUN addgroup -g 1000 appuser && \
    adduser -u 1000 -G appuser -s /bin/sh -D appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
