#!/bin/sh

packwiz refresh
packwiz modrinth export -o minezao.mrpack
sudo docker compose up -d --force-recreate minecraft
