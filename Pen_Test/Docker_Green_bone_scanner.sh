#!/bin/bash bash



# running this installs docker and gets the Greenbone scanner up and running.
read -r "Set the Admin Password for GUI Interface:________" PASSWORD
PW=$PASSWORD
sudo apt install ca-certificates curl gnupg
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt remove $pkg; done
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
wait
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
wait
sudo usermod -aG docker "$USER" && su -c "$USER"
export DOWNLOAD_DIR=$HOME/greenbone-community-container && mkdir -p "$DOWNLOAD_DIR"
cat >> "$DOWNLOAD_DIR"/docker-compose.yml <<EOF
services:
  vulnerability-tests:
    image: greenbone/vulnerability-tests
    environment:
      STORAGE_PATH: /var/lib/openvas/22.04/vt-data/nasl
    volumes:
      - vt_data_vol:/mnt

  notus-data:
    image: greenbone/notus-data
    volumes:
      - notus_data_vol:/mnt

  scap-data:
    image: greenbone/scap-data
    volumes:
      - scap_data_vol:/mnt

  cert-bund-data:
    image: greenbone/cert-bund-data
    volumes:
      - cert_data_vol:/mnt

  dfn-cert-data:
    image: greenbone/dfn-cert-data
    volumes:
      - cert_data_vol:/mnt
    depends_on:
      - cert-bund-data

  data-objects:
    image: greenbone/data-objects
    volumes:
      - data_objects_vol:/mnt

  report-formats:
    image: greenbone/report-formats
    volumes:
      - data_objects_vol:/mnt
    depends_on:
      - data-objects

  gpg-data:
    image: greenbone/gpg-data
    volumes:
      - gpg_data_vol:/mnt

  redis-server:
    image: greenbone/redis-server
    restart: on-failure
    volumes:
      - redis_socket_vol:/run/redis/

  pg-gvm:
    image: greenbone/pg-gvm:stable
    restart: on-failure
    volumes:
      - psql_data_vol:/var/lib/postgresql
      - psql_socket_vol:/var/run/postgresql

  gvmd:
    image: greenbone/gvmd:stable
    restart: on-failure
    volumes:
      - gvmd_data_vol:/var/lib/gvm
      - scap_data_vol:/var/lib/gvm/scap-data/
      - cert_data_vol:/var/lib/gvm/cert-data
      - data_objects_vol:/var/lib/gvm/data-objects/gvmd
      - vt_data_vol:/var/lib/openvas/plugins
      - psql_data_vol:/var/lib/postgresql
      - gvmd_socket_vol:/run/gvmd
      - ospd_openvas_socket_vol:/run/ospd
      - psql_socket_vol:/var/run/postgresql
    depends_on:
      pg-gvm:
        condition: service_started
      scap-data:
        condition: service_completed_successfully
      cert-bund-data:
        condition: service_completed_successfully
      dfn-cert-data:
        condition: service_completed_successfully
      data-objects:
        condition: service_completed_successfully
      report-formats:
        condition: service_completed_successfully

  gsa:
    image: greenbone/gsa:stable
    restart: on-failure
    ports:
      - 9392:80
    volumes:
      - gvmd_socket_vol:/run/gvmd
    depends_on:
      - gvmd

  ospd-openvas:
    image: greenbone/ospd-openvas:stable
    restart: on-failure
    init: true
    hostname: ospd-openvas.local
    cap_add:
      - NET_ADMIN # for capturing packages in promiscuous mode
      - NET_RAW # for raw sockets e.g. used for the boreas alive detection
    security_opt:
      - seccomp=unconfined
      - apparmor=unconfined
    command:
      [
        "ospd-openvas",
        "-f",
        "--config",
        "/etc/gvm/ospd-openvas.conf",
        "--mqtt-broker-address",
        "mqtt-broker",
        "--notus-feed-dir",
        "/var/lib/notus/advisories",
        "-m",
        "666"
      ]
    volumes:
      - gpg_data_vol:/etc/openvas/gnupg
      - vt_data_vol:/var/lib/openvas/plugins
      - notus_data_vol:/var/lib/notus
      - ospd_openvas_socket_vol:/run/ospd
      - redis_socket_vol:/run/redis/
    depends_on:
      redis-server:
        condition: service_started
      gpg-data:
        condition: service_completed_successfully
      vulnerability-tests:
        condition: service_completed_successfully

  mqtt-broker:
    restart: on-failure
    image: greenbone/mqtt-broker
    ports:
      - 1883:1883
    networks:
      default:
        aliases:
          - mqtt-broker
          - broker

  notus-scanner:
    restart: on-failure
    image: greenbone/notus-scanner:stable
    volumes:
      - notus_data_vol:/var/lib/notus
      - gpg_data_vol:/etc/openvas/gnupg
    environment:
      NOTUS_SCANNER_MQTT_BROKER_ADDRESS: mqtt-broker
      NOTUS_SCANNER_PRODUCTS_DIRECTORY: /var/lib/notus/products
    depends_on:
      - mqtt-broker
      - gpg-data
      - vulnerability-tests

  gvm-tools:
    image: greenbone/gvm-tools
    volumes:
      - gvmd_socket_vol:/run/gvmd
      - ospd_openvas_socket_vol:/run/ospd
    depends_on:
      - gvmd
      - ospd-openvas

volumes:
  gpg_data_vol:
  scap_data_vol:
  cert_data_vol:
  data_objects_vol:
  gvmd_data_vol:
  psql_data_vol:
  vt_data_vol:
  notus_data_vol:
  psql_socket_vol:
  gvmd_socket_vol:
  ospd_openvas_socket_vol:
  redis_socket_vol:
EOF

docker compose -f "$DOWNLOAD_DIR"/docker-compose.yml -p greenbone-community-edition pull
docker compose -f "$DOWNLOAD_DIR"/docker-compose.yml -p greenbone-community-edition up -d
docker compose -f "$DOWNLOAD_DIR"/docker-compose.yml -p greenbone-community-edition logs -f
docker compose -f "$DOWNLOAD_DIR"/docker-compose.yml -p greenbone-community-edition \
    exec -u gvmd gvmd gvmd --user=admin --new-password="$PW"

xdg-open "http://127.0.0.1:9392" 2>/dev/null >/dev/null &
