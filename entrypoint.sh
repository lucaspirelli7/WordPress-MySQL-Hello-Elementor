#!/bin/bash
set -e

# 1) Ejecutar entrypoint original (copia WP y crea wp-config si hay vars)
docker-entrypoint.sh "$@" &

# 2) Esperar a que exista wp-load.php (señal de que WP ya está copiado)
echo "Waiting for WordPress files..."
for i in {1..60}; do
  if [ -f /var/www/html/wp-load.php ]; then
    echo "WordPress files detected."
    break
  fi
  sleep 2
done

# 3) Correr init una sola vez si existe
if [ -f /docker-entrypoint-initwp.d/01-init.sh ]; then
  /docker-entrypoint-initwp.d/01-init.sh || true
fi

# 4) Traer al frente el proceso principal (apache)
wait -n
