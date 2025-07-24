#!/bin/bash
# Inicia un framebuffer virtual
Xvfb :0 -screen 0 1024x768x16 &

# Variables por defecto (puedes pasarlas como env vars)
: "${PORT:=27015}"
: "${MAXPLAYERS:=16}"
: "${MAP:=arena_big}"

cd /home/steam/dm_srv

# Ejecuta srcds.exe bajo Wine
exec wine cmd /c "srcds.exe -game dmom \
 +port ${PORT} \
 +maxplayers ${MAXPLAYERS} \
 +map ${MAP} \
 +exec server.cfg"
