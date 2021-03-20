FROM openjdk:11-jre-slim-buster

ARG DEBIAN_FRONTEND=noninteractive \
    BUILD_DEPS="gosu wget ripgrep procps lsof bsdtar ghostscript tesseract-ocr tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf" \
    SOLR_VERSION="8.8.1" \
    DOCSPELL_VERSION="0.21.0" \
    DOCSPELL_CONF_SRV="/opt/docspell/restserver/conf/docspell-server.conf"

ENV DEBUG=false \
    TZ=Etc/UTC \
    DOCSPELL_HEADER_VALUE=none \
    DOCSPELL_DB_TYPE="h2" \
    DOCSPELL_DB_HOST="" \
    DOCSPELL_DB_PORT="" \
    DOCSPELL_DB_NAME="" \
    DOCSPELL_DB_USER="sa" \
    DOCSPELL_DB_PASS="" \
    DOCSPELL_APP_NAME="Docspell" \
    DOCSPELL_APP_ID="rest1" \
    DOCSPELL_BASE_URL="http://localhost:7880" \
    DOCSPELL_BIND_ADDRESS="0.0.0.0" \
    DOCSPELL_BIND_PORT="7880" \
    DOCSPELL_MAX_ITEM_PAGE_SIZE="200" \
    DOCSPELL_MAX_NOTE_LENGTH="180" \
    DOCSPELL_SHOW_CLASSIFICATION_SETTINGS="true" \
    DOCSPËLL_AUTH_SERVER_SECRET="hex:caffee" \
    DOCSPËLL_AUTH_SESSION_VALID="5 minutes" \
    DOCSPËLL_REMEMBER_ME_ENABLED="true" \
    DOCSPËLL_REMEMBER_ME_VALID="30 days" \
    DOCSPELL_INTEGRATION_ENDPOINT_ENABLED="false" \
    DOCSPELL_INTEGRATION_ENDPOINT_PRIORITY="low" \
    DOCSPELL_INTEGRATION_ENDPOINT_SOURCE_NAME="integration" \
    DOCSPELL_INTEGRATION_ENDPOINT_ALLOWED_IPS_ENABLED="false" \
    DOCSPELL_INTEGRATION_ENDPOINT_ALLOWED_IPS_IPS="127.0.0.1" \
    DOCSPELL_INTEGRATION_ENDPOINT_HTTP_BASIC_ENABLED="false" \
    DOCSPELL_INTEGRATION_ENDPOINT_HTTP_BASIC_REALM="Docspell Integration" \
    DOCSPELL_INTEGRATION_ENDPOINT_HTTP_BASIC_USER = "docspell-int" \
    DOCSPELL_INTEGRATION_ENDPOINT_HTTP_BASIC_PASSWORD = "docspell-int" \
    DOCSPELL_INTEGRATION_ENDPOINT_HTTP_HEADER_ENABLED="false" \
    DOCSPELL_INTEGRATION_ENDPOINT_HTTP_HEADER_NAME="Docspell-Integration" \
    DOCSPELL_INTEGRATION_ENDPOINT_HTTP_HEADER_VALUE="some-secret" \
    DOCSPELL_ADMIN_ENDPOINT_SECRET="" \
    DOCSPELL_FULL_TEXT_SEARCH_ENABLED="true" \
    DOCSPELL_FULL_TEXT_SEARCH_SOLR_URL="http://localhost:8983/solr/docspell" \
    DOCSPELL_FULL_TEXT_SEARCH_SOLR_COMMIT_WITHIN="1000" \
    DOCSPELL_FULL_TEXT_SEARCH_SOLR_LOG_VERBOSE="false" \
    DOCSPELL_FULL_TEXT_SEARCH_SOLR_DEF_TYPE="lucene" \
    DOCSPELL_FULL_TEXT_SEARCH_SOLR_Q_OP="OR" \
    DOCSPELL_BACKEND_MAIL_DEBUG="false" \
    DOCSPELL_BACKEND_SIGNUP_MODE="open" \
    DOCSPELL_BACKEND_SIGNUP_NEW_INVITE_PASSWORD="" \
    DOCSPELL_BACKEND_SIGNUP_INVITE_TIME="3 days" \
    DOCSPELL_BACKEND_FILES_CHUNK_SIZE="524288" \
    DOCSPELL_BACKEND_FILES_VALID_MIME_TYPES=""

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

RUN sed -i -e '/app-name/ s/=.*/= $\{DOCSPELL_APP_NAME\}/' "${DOCSPELL_CONF_SRV}" \
    && sed -n -e '/full-text-search/,/^  }/ p' "${DOCSPELL_CONF_SRV}" | sed -e '/enabled/ s/=.*/= $$\{DOCSPELL_FULL_TEXT_SEARCH_ENABLED\}/' >/tmp/__full_text_search \
    && rg --replace "$(cat /tmp/__full_text_search)" --passthru --no-line-number --multiline --multiline-dotall '  full-text-search.*?\n  }\n' "${DOCSPELL_CONF_SRV}" >"${DOCSPELL_CONF_SRV}.new" \
    && mv "${DOCSPELL_CONF_SRV}" "${DOCSPELL_CONF_SRV}.origin" && mv "${DOCSPELL_CONF_SRV}.new" "${DOCSPELL_CONF_SRV}"

VOLUME /config

EXPOSE 7880

WORKDIR /opt/docspell

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
