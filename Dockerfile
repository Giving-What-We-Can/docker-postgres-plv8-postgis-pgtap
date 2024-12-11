# First stage - base image with PostgreSQL and PostGIS
FROM --platform=$TARGETPLATFORM postgres:15.3-alpine AS base

ENV POSTGIS_VERSION=3.3.3 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install PostGIS and dependencies in a single layer
RUN apk add --no-cache \
    postgresql-contrib \
    geos \
    gdal \
    proj \
    protobuf-c \
    libxml2 \
    json-c \
    postgis \
    sqlite-libs

# Second stage - testing image with pgTAP
FROM base AS testing

ENV PGTAP_VERSION=v1.2.0

# Install pgTAP and dependencies in a single layer
RUN apk add --no-cache perl perl-ipc-run \
    && apk add --no-cache --virtual .build-deps \
        git \
        perl-dev \
        build-base \
        postgresql-dev \
        linux-headers \
    && git clone --depth 1 -b ${PGTAP_VERSION} https://github.com/theory/pgtap.git /tmp/pgtap \
    && cd /tmp/pgtap \
    && make \
    && make install \
    && cpan TAP::Parser::SourceHandler::pgTAP \
    && cd / \
    && rm -rf /tmp/pgtap /root/.cpan \
    && apk del .build-deps