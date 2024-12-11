# First stage - base image with PostgreSQL and PostGIS
FROM postgres:15.3-alpine AS base

ENV POSTGIS_VERSION 3.3.3

# Install PostGIS and dependencies
RUN apk add --no-cache \
    postgresql-contrib \
    geos \
    gdal \
    proj \
    protobuf-c \
    libxml2 \
    json-c \
    postgis \
    # Additional build dependencies for PostGIS
    && apk add --no-cache --virtual .postgis-rundeps \
    sqlite-libs \
    geos-dev \
    gdal-dev \
    proj-dev \
    protobuf-c-dev \
    json-c-dev \
    libxml2-dev

# Set locale
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Second stage - testing image with pgTAP
FROM base AS testing

ENV PGTAP_VERSION v1.2.0

# Install build dependencies and pgTAP
RUN apk add --no-cache --virtual .build-deps \
    git \
    perl \
    perl-dev \
    build-base \
    postgresql-dev \
    linux-headers \
    && apk add --no-cache \
    perl-ipc-run \
    # Install pgTAP
    && git clone https://github.com/theory/pgtap.git \
    && cd pgtap \
    && git checkout ${PGTAP_VERSION} \
    && make \
    && make install \
    # Install TAP::Parser::SourceHandler::pgTAP
    && cpan TAP::Parser::SourceHandler::pgTAP \
    # Cleanup
    && cd / \
    && rm -rf pgtap \
    && apk del .build-deps