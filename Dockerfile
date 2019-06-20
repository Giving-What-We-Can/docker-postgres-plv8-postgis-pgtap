# Base image with just PostGIS/PLV8
FROM postgres:9.6 AS base

# PostGIS installation
# http://trac.osgeo.org/postgis/wiki/UsersWikiPostGIS23UbuntuPGSQL96Apt
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt xenial-pgdg main" >> /etc/apt/sources.list'
RUN apt-get update && apt-get -y install wget
RUN wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
RUN buildDependencies="build-essential \
    ca-certificates \
    curl \
    git-core \
    postgresql-server-dev-$PG_MAJOR" \
  && apt-get update \
  && apt-get install -y postgresql-9.6-postgis-2.3 postgresql-contrib-9.6 postgresql-9.6-postgis-scripts

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY ./update-postgis.sh /usr/local/bin

# PLV8 Installation
ENV PLV8_VERSION=v2.1.0 \
    PLV8_SHASUM="207d712e919ab666936f42b29ff3eae413736b70745f5bfeb2d0910f0c017a5c  v2.1.0.tar.gz"

RUN apt-get install -y make pkg-config libc++-dev libc++-dev
RUN buildDependencies="build-essential \
    ca-certificates \
    curl \
    git-core \
    postgresql-server-dev-$PG_MAJOR" \
  && apt-get update \
  && apt-get install -y --no-install-recommends ${buildDependencies}
RUN mkdir -p /tmp/build
RUN curl -o /tmp/build/${PLV8_VERSION}.tar.gz -SL "https://github.com/plv8/plv8/archive/$PLV8_VERSION.tar.gz"
RUN cd /tmp/build \
  && echo ${PLV8_SHASUM} | sha256sum -c \
  && tar -xzf /tmp/build/${PLV8_VERSION}.tar.gz -C /tmp/build/ \
  && cd /tmp/build/plv8-${PLV8_VERSION#?} \
  && ls -al \
  && sed -i 's/\(depot_tools.git\)/\1; cd depot_tools; git checkout 46541b4996f25b706146148331b9613c8a787e7e; rm -rf .git;/' Makefile.v8 \
  && make static
RUN cd /tmp/build/plv8-${PLV8_VERSION#?} ls -al && make install
RUN strip /usr/lib/postgresql/${PG_MAJOR}/lib/plv8.so
WORKDIR /
RUN apt-get clean
RUN apt-get remove -y ${buildDependencies}
RUN apt-get autoremove -y
RUN rm -rf /tmp/build /var/lib/apt/lists/*
RUN rm /docker-entrypoint-initdb.d/postgis.sh

# ==============================================================================
# Testing image where we build pg_tap
FROM base as testing

ENV PGTAP_VERSION v1.0.0

RUN apt-get install -y perl
RUN cpan TAP::Parser::SourceHandler::pgTAP
RUN git clone https://github.com/theory/pgtap \
 && cd pgtap \
 && git checkout ${PGTAP_VERSION} \
 && make \
 # && make installcheck \
 && make install
