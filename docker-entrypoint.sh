#!/bin/bash
echo 'Container Docspell is starting'
echo ' '

echo 'Initialize config files:'
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
/opt/solr/bin/solr start -force
/opt/solr/bin/solr create -c docspell -force
/opt/solr/bin/solr status
/opt/docspell/joex/bin/docspell-joex
/opt/docspell/restserver/bin/docspell-restserver
echo ' '

echo 'infinite waiting'
while true; do sleep 100; done
