FROM openjdk:11-jre-slim-buster

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y install --no-install-recommends wget procps lsof bsdtar ghostscript tesseract-ocr tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*
    
WORKDIR /opt

RUN mkdir -p /opt/solr

RUN wget https://apache.mediamirrors.org/lucene/solr/8.8.1/solr-8.8.1.tgz -P /opt/solr/ \
    && tar zxf /opt/solr/solr-8.8.1.tgz --strip 1 -C /opt/solr
    
RUN mkdir -p /opt/docspell && mkdir -p /opt/docspell/joex && mkdir -p /opt/docspell/restserver \
    && wget -O docspell-restserver.zip https://github.com/eikek/docspell/releases/download/v0.21.0/docspell-restserver-0.21.0.zip -P /opt/docspell/ \
    && wget -O docspell-joex.zip https://github.com/eikek/docspell/releases/download/v0.21.0/docspell-joex-0.21.0.zip -P /opt/docspell/ \
    && bsdtar --strip-components=1 -xvf "/opt/docspell/docspell-joex.zip" -C /opt/docspell/joex \
    && bsdtar --strip-components=1 -xvf "/opt/docspell/docspell-restserver.zip" -C /opt/docspell/restserver

WORKDIR /opt/docspell

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
