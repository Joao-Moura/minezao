#!/bin/sh
set -eu
packwiz refresh
mkdir -p dist
packwiz modrinth export -o dist/minezao.mrpack
