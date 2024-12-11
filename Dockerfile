# syntax=docker/dockerfile:1.4

# Base image with PostGIS
FROM postgis/postgis:15-3.4-alpine AS base

# Remove default initialization scripts
RUN rm -rf /docker-entrypoint-initdb.d/*

# Add initialization script
COPY <<-'EOF' /docker-entrypoint-initdb.d/10-init-postgis.sh
#!/bin/bash
set -e

# Function to initialize the database
init_db() {
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        -- Create postgis schema
        CREATE SCHEMA IF NOT EXISTS postgis;

        -- Set search path for installation
        SET search_path TO postgis, public;

        -- Install PostGIS into postgis schema
        CREATE EXTENSION IF NOT EXISTS postgis SCHEMA postgis;

        -- Verify installation schema
        SELECT n.nspname as schema_name, e.extname as extension
        FROM pg_extension e
        JOIN pg_namespace n ON n.oid = e.extnamespace
        WHERE e.extname = 'postgis';
EOSQL
}

# Call initialization function
init_db
EOF

# Make the init script executable
RUN chmod +x /docker-entrypoint-initdb.d/10-init-postgis.sh

# Testing image with pgTAP
FROM base AS testing

ARG PGTAP_VERSION=1.3.1

# Install dependencies and build pgTAP
RUN set -x && \
    apk update && \
    apk add --no-cache \
        perl \
        perl-dev \
        build-base \
        postgresql-dev \
        git \
        make \
        libc-dev \
        pkgconf \
        clang15 \
        llvm15 \
    && git clone --branch "v${PGTAP_VERSION}" https://github.com/theory/pgtap.git \
    && cd pgtap \
    && make CUSTOM_CC=gcc \
    && make install \
    && cd .. \
    && rm -rf pgtap \
    && apk del \
        perl-dev \
        build-base \
        postgresql-dev \
        git \
        make \
        libc-dev \
        pkgconf \
        clang15 \
        llvm15

EXPOSE 5432