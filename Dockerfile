FROM openjdk:11-jre-slim-buster

ARG DEBIAN_FRONTEND=noninteractive \
    BUILD_DEPS="gosu wget ripgrep procps lsof bsdtar ghostscript tesseract-ocr tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf" \
    SOLR_VERSION="8.8.1" \
    DOCSPELL_VERSION="/opt/docspell/version.txt" \
    DOCSPELL_DOWNLOAD_URLS="/tmp/__docspell_dl_urls" \
    DOCSPELL_CONF_RS="/opt/docspell/restserver/conf/docspell-server.conf" \
    DOCSPELL_CONF_JO="/opt/docspell/joex/conf/docspell-joex.conf" \
    TMP_RS_BIND="/tmp/__rs_bind" \
    TMP_RS_AUTH="/tmp/__rs_auth" \
    TMP_RS_INTEGRATION_ENDPOINT="/tmp/__rs_integration_endpoint" \
    TMP_RS_ADMIN_ENDPOINT="/tmp/__rs_admin_endpoint" \
    TMP_RS_FULL_TEXT_SEARCH="/tmp/__rs_full_text_search" \
    TMP_RS_BACKEND="/tmp/__rs_backend" \
    TMP_JO_BIND="/tmp/__jo_bind" \
    TMP_JO_JDBC="/tmp/__jo_jdbc" \

ENV DEBUG=false \
    TZ=Etc/UTC \
    DOCSPELL_HEADER_VALUE=none \
    DOCSPELL_DB_TYPE="h2" \
    DOCSPELL_DB_HOST="" \
    DOCSPELL_DB_PORT="" \
    DOCSPELL_DB_NAME="" \
    DOCSPELL_DB_USER="sa" \
    DOCSPELL_DB_PASS="" \
    DOCSPELL_DB_H2_URL="jdbc:h2://\"\${java.io.tmpdir}\"/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE" \
    DOCSPELL_RS_APP_NAME="Docspell" \
    DOCSPELL_RS_APP_ID="rest1" \
    DOCSPELL_RS_BASE_URL="http://localhost:7880" \
    DOCSPELL_RS_BIND_ADDRESS="0.0.0.0" \
    DOCSPELL_RS_BIND_PORT="7880" \
    DOCSPELL_RS_MAX_ITEM_PAGE_SIZE="200" \
    DOCSPELL_RS_MAX_NOTE_LENGTH="180" \
    DOCSPELL_RS_SHOW_CLASSIFICATION_SETTINGS="true" \
    DOCSPËLL_RS_AUTH_SERVER_SECRET="hex:caffee" \
    DOCSPËLL_RS_AUTH_SESSION_VALID="5 minutes" \
    DOCSPËLL_RS_REMEMBER_ME_ENABLED="true" \
    DOCSPËLL_RS_REMEMBER_ME_VALID="30 days" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_ENABLED="false" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_PRIORITY="low" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_SOURCE_NAME="integration" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_ALLOWED_IPS_ENABLED="false" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_ALLOWED_IPS_IPS="127.0.0.1" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_HTTP_BASIC_ENABLED="false" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_HTTP_BASIC_REALM="Docspell Integration" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_HTTP_BASIC_USER="docspell-int" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_HTTP_BASIC_PASSWORD="docspell-int" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_HTTP_HEADER_ENABLED="false" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_HTTP_HEADER_NAME="Docspell-Integration" \
    DOCSPELL_RS_INTEGRATION_ENDPOINT_HTTP_HEADER_VALUE="some-secret" \
    DOCSPELL_RS_ADMIN_ENDPOINT_SECRET="" \
    DOCSPELL_RS_FULL_TEXT_SEARCH_ENABLED="true" \
    DOCSPELL_RS_FULL_TEXT_SEARCH_SOLR_URL="http://localhost:8983/solr/docspell" \
    DOCSPELL_RS_FULL_TEXT_SEARCH_SOLR_COMMIT_WITHIN="1000" \
    DOCSPELL_RS_FULL_TEXT_SEARCH_SOLR_LOG_VERBOSE="false" \
    DOCSPELL_RS_FULL_TEXT_SEARCH_SOLR_DEF_TYPE="lucene" \
    DOCSPELL_RS_FULL_TEXT_SEARCH_SOLR_Q_OP="OR" \
    DOCSPELL_RS_BACKEND_MAIL_DEBUG="false" \
    DOCSPELL_RS_BACKEND_SIGNUP_MODE="open" \
    DOCSPELL_RS_BACKEND_SIGNUP_NEW_INVITE_PASSWORD="" \
    DOCSPELL_RS_BACKEND_SIGNUP_INVITE_TIME="3 days" \
    DOCSPELL_RS_BACKEND_FILES_CHUNK_SIZE="524288" \
    DOCSPEEL_VERSION=

# Install all packages needed
RUN apt-get update \
    && apt-get -y install --no-install-recommends ${BUILD_DEPS} \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*
    
WORKDIR /opt

# Install the full-text search Apache Solr
RUN mkdir -p /opt/solr && wget -q -O /opt/solr/solr.tgz https://apache.mediamirrors.org/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz \
    && tar zxf /opt/solr/solr.tgz --strip 1 -C /opt/solr && rm /opt/solr/solr.tgz \
    && useradd --user-group --system --home-dir /opt/solr solr \
    && chown solr --recursive /opt/solr    
VOLUME /var/solr/data

# Install the latest version of Docspell
RUN mkdir -p /opt/docspell/joex && mkdir -p /opt/docspell/restserver \
    && wget -qO- "https://api.github.com/repos/eikek/docspell/releases/latest" | grep 'browser_download_url' | grep 'zip' >"${DOCSPELL_DOWNLOAD_URLS}" && cat "${DOCSPELL_DOWNLOAD_URLS}" \
    && cat "${DOCSPELL_DOWNLOAD_URLS}" | grep 'restserver' | cut -d '/' -f 8 >"${DOCSPELL_VERSION}" && cat "${DOCSPELL_VERSION}" \
    && cat "${DOCSPELL_DOWNLOAD_URLS}" | grep 'restserver' | cut -d '"' -f 4 | wget -qi - -O /opt/docspell/docspell-restserver.zip \
    && cat "${DOCSPELL_DOWNLOAD_URLS}" | grep 'joex' | cut -d '"' -f 4 | wget -qi - -O /opt/docspell/docspell-joex.zip \
    && bsdtar --strip-components=1 -xvf "/opt/docspell/docspell-joex.zip" -C /opt/docspell/joex \
    && bsdtar --strip-components=1 -xvf "/opt/docspell/docspell-restserver.zip" -C /opt/docspell/restserver \
    && cp "${DOCSPELL_CONF_RS}" "${DOCSPELL_CONF_RS}.origin" && cp "${DOCSPELL_CONF_JOEX}" "${DOCSPELL_CONF_JOEX}.origin" \
    && rm /opt/docspell/docspell-joex.zip && rm /opt/docspell/docspell-restserver.zip

# Switch to Bash for next RUN commands. useful for the file configurations
SHELL ["/bin/bash", "-c"]

# Add ENV variables to the first level options of the Restserver config file
RUN sed -i -e '/  app-name/ s/=.*/= $\{DOCSPELL_RS_APP_NAME\}/' "${DOCSPELL_CONF_RS}" \
    && sed -i -e '/  app-id/ s/=.*/= $\{DOCSPELL_RS_APP_ID\}/' "${DOCSPELL_CONF_RS}" \
    && sed -i -e '/  base-url/ s/=.*/= $\{DOCSPELL_RS_BASE_URL\}/' "${DOCSPELL_CONF_RS}" \
    && sed -i -e '/  max-item-page-size/ s/=.*/= $\{DOCSPELL_RS_MAX_ITEM_PAGE_SIZE\}/' "${DOCSPELL_CONF_RS}" \
    && sed -i -e '/  max-note-length/ s/=.*/= $\{DOCSPELL_RS_MAX_NOTE_LENGTH\}/' "${DOCSPELL_CONF_RS}" \
    && sed -i -e '/  show-classification-settings/ s/=.*/= $\{DOCSPELL_RS_SHOW_CLASSIFICATION_SETTINGS\}/' "${DOCSPELL_CONF_RS}"

# Add ENV variables to the bind block options of the Restserver config file
RUN sed -n -e '/  bind {/,/^  }/ p' "${DOCSPELL_CONF_RS}" >"${TMP_RS_BIND}" \
    && sed -i -e '/address/ s/=.*/= $$\{DOCSPELL_RS_BIND_ADDRESS\}/' "${TMP_RS_BIND}" \
    && sed -i -e '/port/ s/=.*/= $$\{DOCSPELL_RS_BIND_PORT\}/' "${TMP_RS_BIND}" \
    && cat "${TMP_RS_BIND}" \
    && rg --replace "$(cat ${TMP_RS_BIND})" --passthru --no-line-number --multiline --multiline-dotall '  bind .*?\n  }\n' "${DOCSPELL_CONF_RS}" >"${DOCSPELL_CONF_RS}.new" \
    && rm "${DOCSPELL_CONF_RS}" && mv "${DOCSPELL_CONF_RS}.new" "${DOCSPELL_CONF_RS}"

# Add ENV variables to the full-text-search block options of the Restserver config file
RUN sed -n -e '/  full-text-search {/,/^  }/ p' "${DOCSPELL_CONF_RS}" >"${TMP_RS_FULL_TEXT_SEARCH}" \
    && sed -i -e '/enabled/ s/=.*/= $$\{DOCSPELL_RS_FULL_TEXT_SEARCH_ENABLED\}/' "${TMP_RS_FULL_TEXT_SEARCH}" \
    && cat "${TMP_RS_FULL_TEXT_SEARCH}" \
    && rg --replace "$(cat ${TMP_RS_FULL_TEXT_SEARCH})" --passthru --no-line-number --multiline --multiline-dotall '  full-text-search .*?\n  }\n' "${DOCSPELL_CONF_RS}" >"${DOCSPELL_CONF_RS}.new" \
    && rm "${DOCSPELL_CONF_RS}" && mv "${DOCSPELL_CONF_RS}.new" "${DOCSPELL_CONF_RS}"

# Add ENV variables to the backend block options of the Restserver config file
RUN sed -n -e '/  backend {/,/^  }/ p' "${DOCSPELL_CONF_RS}" >"${TMP_RS_BACKEND}" \
    && sed -i -e '/      url / s/=.*/= \"jdbc:\"$$\{DOCSPELL_DB_TYPE\}\":\/\/\"$$\{DOCSPELL_DB_HOST\}\":\"$$\{DOCSPELL_DB_PORT\}\"\/\"$$\{DOCSPELL_DB_NAME\}/' "${TMP_RS_BACKEND}" \
    && sed -i -e '/      user / s/=.*/= $$\{DOCSPELL_DB_USER\}/' "${TMP_RS_BACKEND}" \
    && sed -i -e '/      password / s/=.*/= $$\{DOCSPELL_DB_PASS\}/' "${TMP_RS_BACKEND}" \
    && sed -i -e '/      mode / s/=.*/= $$\{DOCSPELL_RS_BACKEND_SIGNUP_MODE\}/' "${TMP_RS_BACKEND}" \
    && sed -i -e '/      new-invite-password / s/=.*/= $$\{DOCSPELL_RS_BACKEND_SIGNUP_NEW_INVITE_PASSWORD\}/' "${TMP_RS_BACKEND}" \
    && sed -i -e '/      invite-time / s/=.*/= $$\{DOCSPELL_RS_BACKEND_SIGNUP_INVITE_TIME\}/' "${TMP_RS_BACKEND}" \
    && sed -i -e '/      chunk-size / s/=.*/= $$\{DOCSPELL_RS_BACKEND_FILES_CHUNK_SIZE\}/' "${TMP_RS_BACKEND}" \
    && cat "${TMP_RS_BACKEND}" \
    && rg --replace "$(cat ${TMP_RS_BACKEND})" --passthru --no-line-number --multiline --multiline-dotall '  backend .*?\n  }\n' "${DOCSPELL_CONF_RS}" >"${DOCSPELL_CONF_RS}.new" \
    && rm "${DOCSPELL_CONF_RS}" && mv "${DOCSPELL_CONF_RS}.new" "${DOCSPELL_CONF_RS}"

# Add ENV variables to the JDBC block options of the Joex config file
RUN sed -n -e '/  jdbc {/,/^  }/ p' "${DOCSPELL_CONF_JO}" >"${TMP_JO_JDBC}" \
    && sed -i -e '/      url / s/=.*/= \"jdbc:\"$$\{DOCSPELL_DB_TYPE\}\":\/\/\"$$\{DOCSPELL_DB_HOST\}\":\"$$\{DOCSPELL_DB_PORT\}\"\/\"$$\{DOCSPELL_DB_NAME\}/' "${TMP_JO_JDBC}" \
    && sed -i -e '/      user / s/=.*/= $$\{DOCSPELL_DB_USER\}/' "${TMP_JO_JDBC}" \
    && sed -i -e '/      password / s/=.*/= $$\{DOCSPELL_DB_PASS\}/' "${TMP_JO_JDBC}" \
    && cat "${TMP_JO_JDBC}" \
    && rg --replace "$(cat ${TMP_JO_JDBC})" --passthru --no-line-number --multiline --multiline-dotall '  bind .*?\n  }\n' "${DOCSPELL_CONF_JO}" >"${DOCSPELL_CONF_JO}.new" \
    && rm "${DOCSPELL_CONF_JO}" && mv "${DOCSPELL_CONF_JO}.new" "${DOCSPELL_CONF_JO}"

VOLUME /config

EXPOSE 7880

WORKDIR /opt/docspell

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
