# syntax=docker/dockerfile:1

# Base Stage
FROM composer:lts as base
WORKDIR /app

# Production Dependencies Stage
FROM base as prod-deps
RUN --mount=type=bind,source=composer.json,target=composer.json \
    --mount=type=bind,source=composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-dev --no-interaction

# Development Dependencies Stage
FROM base as dev-deps
RUN --mount=type=bind,source=composer.json,target=composer.json \
    --mount=type=bind,source=composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-interaction

# Final Stage (for Production)
FROM php:8.2-apache as final
RUN docker-php-ext-install pdo pdo_mysql
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY --from=prod-deps /app/vendor /var/www/html/vendor
COPY ./src /var/www/html
USER www-data

# Development Stage
FROM final as development
COPY --from=dev-deps /app/vendor /var/www/html/vendor
COPY ./tests /var/www/html/tests
USER www-data
