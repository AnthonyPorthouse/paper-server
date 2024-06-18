#! /usr/bin/env bash
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}
USER=${USER:-"minecraft"}

set-up-user.sh "$USER" "$PUID" "$PGID"

if [ -z "$PAPER_BUILD" ]; then
    latest_build=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}/builds" | jq -r '.builds | map(select(.channel == "default") | .build) | .[-1]')

    if [ "$latest_build" == "null" ]; then
        echo "No build specified and no stable version found" > /dev/stderr
        exit 1
    fi

    PAPER_BUILD="$latest_build"
fi

JAR_NAME="paper-${MINECRAFT_VERSION}-${PAPER_BUILD}.jar"

if [ ! -f "$JAR_NAME" ]; then
    echo "Downloading Paper";

    server_url=https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}/builds/${PAPER_BUILD}/downloads/${JAR_NAME}

    curl -o "$JAR_NAME" -J "$server_url"
fi

echo "Accepting EULA"
echo "eula=true" > eula.txt

configure-server-properties.sh

chown -R "${USER}":"${USER}" /minecraft


COMMAND="${*:-"cd /minecraft; $(which java) ${JAVA_OPTS} -jar $JAR_NAME nogui"}"

su -l "${USER}" -c "$COMMAND"
