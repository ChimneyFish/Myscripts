#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt install docker.io -y
sudo apt install docker-compose -y
sudo apt --fix-broken install
sudo apt install java* -y
mkdir ~/.docker-thehive.d
cat > ~/.docker-thehive.d/docker-compose.yaml << EOF
version: "3"
services:
  thehive:
    image: strangebee/thehive:5.2
    depends_on:
      - cassandra
      - elasticsearch
      - minio
      - cortex
    mem_limit: 1500m
    ports:
      - "9000:9000"
    environment:
      - JVM_OPTS="-Xms1024M -Xmx1024M"
    command:
      - --secret
      - "mySecretForTheHive"
      - "--cql-hostnames"
      - "cassandra"
      - "--index-backend"
      - "elasticsearch"
      - "--es-hostnames"
      - "elasticsearch"
      - "--s3-endpoint"
      - "http://minio:9000"
      - "--s3-access-key"
      - "minioadmin"
      - "--s3-secret-key"
      - "minioadmin"
      - "--s3-bucket"
      - "thehive"
      - "--s3-use-path-access-style"
      - "--cortex-hostnames"
      - "cortex"
      - "--cortex-keys"
      # put cortex api key once cortex is bootstraped
      - "<cortex_api_key>"

  cassandra:
    image: 'cassandra:4'
    mem_limit: 1000m
    ports:
      - "9042:9042"
    environment:
      - CASSANDRA_CLUSTER_NAME=TheHive
    volumes:
      - cassandradata:/var/lib/cassandra

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.9
    mem_limit: 512m
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    volumes:
      - elasticsearchdata:/usr/share/elasticsearch/data

  minio:
    image: quay.io/minio/minio
    mem_limit: 512m
    command: ["minio", "server", "/data", "--console-address", ":9090"]
    environment:
      - MINIO_ROOT_USER=minioadmin
      - MINIO_ROOT_PASSWORD=minioadmin
    ports:
      - "9090:9090"
    volumes:
      - "miniodata:/data"

  cortex:
    image: thehiveproject/cortex:3.1.7
    environment:
      - job_directory=/tmp/cortex-jobs
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp/cortex-jobs:/tmp/cortex-jobs
    depends_on:
      - elasticsearch
    ports:
      - "9001:9001"

volumes:
  miniodata:
  cassandradata:
  elasticsearchdata:
EOF
cat > ~/.docker-thehive.d/Dockerfile <<EOF
FROM strangebee/thehive:5.1
USER root
RUN mkdir -p /opt/thp/thehive/index
RUN mkdir -p /opt/thp/thehive/data
RUN chown -R thehive:thehive /opt/thp/thehive/index
RUN chown -R thehive:thehive /opt/thp/thehive/data
USER thehive
EOF
docker-compose up ~/.docker-thehive.d

