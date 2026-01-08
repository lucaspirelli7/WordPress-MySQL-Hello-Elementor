#!/bin/bash
set -e

# Ejecuta el entrypoint original de WordPress para que genere wp-config si hace falta,
# y arranca Apache en background
/usr/local/bin/docker-entrypoint.sh apache2-foreground &
APACHE_PID=$!

# Corre tus tareas de init (espera DB, instala WP, theme, plugins, etc.)
/usr/local/bin/run-init-tasks.sh || true

# Mantiene el contenedor vivo
wait "$APACHE_PID"