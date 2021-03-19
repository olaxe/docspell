FROM openjdk:11-jre-slim-buster

ARG DEBIAN_FRONTEND=noninteractive

ENV BUILD_DEPS="gosu wget procps lsof bsdtar ghostscript tesseract-ocr tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf" \
    DEBUG=false \
    SOLR_VERSION="8.8.1" \
    DOCSPELL_VERSION="0.21.0" \
    TZ=Etc/UTC \
    DOCSPELL_HEADER_VALUE=none \
    DB_TYPE="mysql" \
    DB_HOST="mysql" \
    DB_PORT="3306" \
    DB_NAME="docspell" \
    DB_USER="docspell" \
    DB_PASS="docspell"

RUN apt-get update \
    && apt-get -y install --no-install-recommends ${BUILD_DEPS} \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*
    
WORKDIR /opt

RUN mkdir -p /opt/solr && wget -O /opt/solr/solr.tgz https://apache.mediamirrors.org/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz \
    && tar zxf /opt/solr/solr.tgz --strip 1 -C /opt/solr && rm /opt/solr/solr.tgz \
    && useradd --user-group --system --home-dir /opt/solr solr \
    && chown solr --recursive /opt/solr
    
VOLUME /var/solr/data
    
RUN mkdir -p /opt/docspell/joex && mkdir -p /opt/docspell/restserver \
    && wget -O /opt/docspell/docspell-restserver.zip https://github.com/eikek/docspell/releases/download/v${DOCSPELL_VERSION}/docspell-restserver-${DOCSPELL_VERSION}.zip \
    && wget -O /opt/docspell/docspell-joex.zip https://github.com/eikek/docspell/releases/download/v${DOCSPELL_VERSION}/docspell-joex-${DOCSPELL_VERSION}.zip \
    && bsdtar --strip-components=1 -xvf "/opt/docspell/docspell-joex.zip" -C /opt/docspell/joex \
    && bsdtar --strip-components=1 -xvf "/opt/docspell/docspell-restserver.zip" -C /opt/docspell/restserver \
    && rm /opt/docspell/docspell-joex.zip  && rm /opt/docspell/docspell-restserver.zip

VOLUME /config

EXPOSE 7880

WORKDIR /opt/docspell

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
