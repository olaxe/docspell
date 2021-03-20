FROM openjdk:11-jre-slim-buster

ARG DEBIAN_FRONTEND=noninteractive \
    BUILD_DEPS="gosu wget ripgrep procps lsof bsdtar ghostscript tesseract-ocr tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf" \
    SOLR_VERSION="8.8.1" \
    DOCSPELL_VERSION="0.21.0" \
    DOCSPELL_CONF_SRV="/opt/docspell/restserver/conf/docspell-server.conf"

ENV DEBUG=false \
    TZ=Etc/UTC \
    DOCSPELL_HEADER_VALUE=none \
    DOCSPELL_DB_TYPE="mysql" \
    DOCSPELL_DB_HOST="mysql" \
    DOCSPELL_DB_PORT="3306" \
    DOCSPELL_DB_NAME="docspell" \
    DOCSPELL_DB_USER="docspell" \
    DOCSPELL_DB_PASS="docspell" \
    DOCSPELL_FULL_TEXT_SEARCH_ENABLED="true"

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
    && rm /opt/docspell/docspell-joex.zip && rm /opt/docspell/docspell-restserver.zip

SHELL ["/bin/bash", "-c"]
    
RUN sed -n -e '/full-text-search/,/^  }/ p' ${DOCSPELL_CONF_SRV} | sed -e '/enabled/ s/=.*/= $$\{DOCSPELL_FULL_TEXT_SEARCH_ENABLED\}/' >/tmp/__full_text_search
RUN rg --replace "$(cat /tmp/__full_text_search)" --passthru --no-line-number --multiline --multiline-dotall '  full-text-search.*?\n  }\n' "${DOCSPELL_CONF_SRV}" >"${DOCSPELL_CONF_SRV}"

VOLUME /config

EXPOSE 7880

WORKDIR /opt/docspell

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
