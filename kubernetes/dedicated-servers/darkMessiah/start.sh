#!/usr/bin/env bash
set -e

# Validar que existan credenciales
if [ -z "$STEAM_USER" ] || [ -z "$STEAM_PASS" ]; then
  echo "ERROR: Debes definir STEAM_USER y STEAM_PASS como variables de entorno"
  exit 1
fi

# Directorio de instalación
INSTALL_DIR="/home/steam/dm_srv"

# Solo descargar si no existe ya el servidor
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Descargando Dark Messiah Dedicated Server..."
  steamcmd +@sSteamCmdForcePlatformType windows \
           +force_install_dir "$INSTALL_DIR" \
           +login "$STEAM_USER" "$STEAM_PASS" \
           +app_update 2145 validate \
           +quit
fi

# Lanzar el servidor bajo Wine
exec wine cmd /c "srcds.exe -game dmom \
  +port ${PORT:-27015} \
  +maxplayers ${MAXPLAYERS:-16} \
  +map ${MAP:-arena_big} \
  +exec server.cfg"
