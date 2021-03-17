#!/bin/bash
echo 'Container Docspell is starting...'
echo ''

echo 'Initialize Docspell config files:'
if [ ! -f "/config/docspell-server.conf" ]; then
  echo 'docspell-server.conf NOT FOUND. Initialization started.'
  mv /opt/docspell/restserver/conf/docspell-server.conf /config
fi
if [ -f "/config/docspell-server.conf" ]; then
  echo 'docspell-server.conf FOUND.'
  rm /opt/docspell/restserver/conf/docspell-server.conf
  ln -s /config/docspell-server.conf /opt/docspell/restserver/conf
fi
if [ ! -f "/config/docspell-joex.conf" ]; then
  echo 'docspell-joex.conf NOT FOUND. Initialization started.'
  mv /opt/docspell/joex/conf/docspell-joex.conf /config
fi
if [ -f "/config/docspell-joex.conf" ]; then
  echo 'docspell-joex.conf FOUND.'
  rm /opt/docspell/joex/conf/docspell-joex.conf
  ln -s /config/docspell-joex.conf /opt/docspell/joex/conf
fi
 
echo 'Starting all needed components:'
echo ' - Starting solr full text indexer'
/opt/solr/bin/solr start -force
/opt/solr/bin/solr status
echo ' - Ping the solr core docspell'
wget -qO- http://localhost:8983/solr/docspell/admin/ping
if [ $? -ne 0 ]; then
  echo ' - Create the solr core docspell'
  /opt/solr/bin/solr create -c docspell -force
fi
/opt/docspell/joex/bin/docspell-joex &
/opt/docspell/restserver/bin/docspell-restserver &
echo ''

echo 'infinite waiting'
while true; do sleep 100; done
