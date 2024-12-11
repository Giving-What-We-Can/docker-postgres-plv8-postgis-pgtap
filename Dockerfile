FROM --platform=$TARGETPLATFORM postgres:15.7-bookworm AS base

# Install PostGIS packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-15-postgis-3 \
        postgresql-15-postgis-3-scripts \
    && rm -rf /var/lib/apt/lists/*

FROM base AS testing

ENV PGTAP_VERSION=v1.2.0

# Install dependencies and pgTAP
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        perl \
        ca-certificates \
        postgresql-server-dev-15 \
        cpanminus \
    && git clone --depth 1 -b ${PGTAP_VERSION} https://github.com/theory/pgtap.git /tmp/pgtap \
    && cd /tmp/pgtap \
    && make \
    && make install \
    && cpanm --notest TAP::Parser::SourceHandler::pgTAP \
    && cd / \
    && rm -rf /tmp/pgtap /root/.cpan \
    && apt-get remove -y \
        build-essential \
        git \
        postgresql-server-dev-15 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*