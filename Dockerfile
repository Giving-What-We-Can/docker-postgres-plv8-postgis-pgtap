# Base image with just PostGIS/PLV8
FROM sibedge/postgres-plv8:15.3-3.1.7-bookworm AS postgis

ENV LC_ALL=C

# PostGIS installation
# http://trac.osgeo.org/postgis/wiki/UsersWikiPostGIS23UbuntuPGSQL96Apt
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" >> /etc/apt/sources.list' \
  && buildDependencies="wget" \
  && apt-get update && apt-get -y --no-install-recommends install ${buildDependencies} \
  && wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - \
  && apt-get install -y --no-install-recommends postgresql-$PG_MAJOR-postgis-3 postgresql-contrib-$PG_MAJOR postgresql-$PG_MAJOR-postgis-3-scripts \
  && apt-get clean && apt-get remove -y ${buildDependencies} && apt-get autoremove -y && apt-get autoclean -y && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Testing image where we build pg_tap
FROM postgis as testing

ENV PGTAP_VERSION v1.2.0

RUN buildDependencies="make ca-certificates git-core patch postgresql-server-dev-$PG_MAJOR" \
  && apt-get update \
  && apt-get install -y --no-install-recommends ${buildDependencies} perl \
  && git clone https://github.com/theory/pgtap \
  && cpan TAP::Parser::SourceHandler::pgTAP \
  && cd pgtap \
  && git checkout ${PGTAP_VERSION} \
  && make \
  && make install \
  && apt-get clean \
  && apt-get remove -y ${buildDependencies} \
  && apt-get autoremove -y && apt-get autoclean -y\
  && rm -rf /tmp/build /var/lib/apt/lists/*
