# syntax=docker/dockerfile:1.4

# Base image with PostGIS already installed
FROM postgis/postgis:15-3.4-alpine AS base

ENV POSTGIS_SCHEMA=postgis

# Testing image with pgTAP
FROM base AS testing

ARG PGTAP_VERSION=1.3.1

# Install dependencies and build pgTAP with verbose output
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