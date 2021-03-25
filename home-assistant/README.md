# Home Assistant - Portainer

The docker compose provided is adapted for the addon Portainer inside Home Assistant.

Assumptions:
- You have installed the MariaDB addon
- You have added in the MariaDB addon the following configuration:
 ~~~
databases:
  - docspell
logins:
  - username: docspell
    password: some-secret
rights:
  - username: docspell
    database: docspell
 ~~~
- And you have restarted the MariaDB addon
- You have a reverse proxy configured and you change the URL in the docker-compose accordingly
