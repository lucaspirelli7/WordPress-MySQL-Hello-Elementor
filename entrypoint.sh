#!/bin/bash
set -e

if [ -f /docker-entrypoint-initwp.d/01-init.sh ]; then
  /docker-entrypoint-initwp.d/01-init.sh || true
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"