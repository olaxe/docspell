#!/bin/ash
echo 'Container Docspell is starting'
echo ''

echo 'Starting all needed components:'
/opt/solr/bin/solr start -force
/opt/solr/bin/solr create -c docspell -force
/opt/solr/bin/solr status
/opt/docspell/joex/bin/docspell-joex
/opt/docspell/restserver/bin/docspell-restserver
echo ''

echo 'infinite waiting'
while true; do sleep 100; done
