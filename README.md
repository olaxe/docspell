# docspell
Docspell image specifically designed for ARM64 with Solr, Docspell Joex and Docspell Rest server and can also work for AMD64

One container for Docspell that include solr, joex & restserver. You only need an extra container for the database MariaDB or PostgreSQL.

Builds are managed by the GitHub repository: https://github.com/olaxe/docspell/blob/main/.github/workflows/build_images.yml

You can find all ENV settings here: https://github.com/olaxe/docspell/blob/main/Dockerfile

For the moment, work is still in progress so don't use for production. It should be finished by end of March 2021.

If you want to test it, list of settings you need for a first startup:  
- DOCSPELL_DB_TYPE="mariadb"
- DOCSPELL_DB_HOST="mysql"
- DOCSPELL_DB_PORT="3306"
- DOCSPELL_DB_NAME="docspell" 
- DOCSPELL_DB_USER="docspell" 
- DOCSPELL_DB_PASS="some-secret" 
- DOCSPELL_RS_BASE_URL="https://dms.mydomain.com" 
For the URL, you will need a reverse proxy like traefik, Caddy or Nginx reverse proxy and map the 7880 port of the container

For volumes, you need the SOLR data: VOLUME /var/solr/data

The config volume is only provided to override config files so no need by default.
