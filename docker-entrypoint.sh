#!/bin/bash
echo 'Container Docspell is starting...'
echo ''

echo 'Check if there is an external Docspell Restserver config file'
if [ -f "/config/docspell-server.conf" ]; then
  echo '/config/docspell-server.conf FOUND. Replacement started.'
  mv /opt/docspell/restserver/conf/docspell-server.conf /opt/docspell/restserver/conf/docspell-server.conf.bak
  mv /config/docspell-server.conf /opt/docspell/restserver/conf/docspell-server.conf
fi
echo 'Check if there is a external Docspell Joex config file'
if [ -f "/config/docspell-joex.conf" ]; then
  echo 'docspell-joex.conf FOUND. Replacement started.'
  mv /opt/docspell/joex/conf/docspell-joex.conf /opt/docspell/joex/conf/docspell-joex.conf.bak
  mv /config/docspell-joex.conf /opt/docspell/joex/conf/docspell-joex.conf
fi

echo 'Check the solr data folder'
if [ -z "$(ls -A /var/solr/data)" ]; then
  echo 'copy empty solr data structure'
  mv /opt/solr/server/solr/* /var/solr/data/
  chown solr --recursive /var/solr/data
fi
echo 'Link the solr data volume'
rm -rf /opt/solr/server/solr
ln -s /var/solr/data /opt/solr/server/solr

echo 'Starting all needed components:'
echo ' - Starting solr full text indexer'
gosu solr:solr /opt/solr/bin/solr start
gosu solr:solr /opt/solr/bin/solr status
echo ' - Ping the solr core docspell'
gosu solr:solr wget -qO- http://localhost:8983/solr/docspell/admin/ping
if [ $? -ne 0 ]; then
  echo ' - Create the solr core docspell'
  gosu solr:solr /opt/solr/bin/solr create -c docspell
  echo 'configure it'
  gosu solr:solr /opt/solr/bin/solr config -c docspell -p 8983 -action set-user-property -property update.autoCreateFields -value false
fi
/opt/docspell/joex/bin/docspell-joex &
/opt/docspell/restserver/bin/docspell-restserver &
echo ''

echo 'Docspell instances (Joex & Restserver) have been started'
while true; do sleep 100; done
