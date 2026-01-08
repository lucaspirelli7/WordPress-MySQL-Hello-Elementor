#!/bin/bash
set -e

echo "== Fix Apache MPM (force prefork) =="

# 1) Deshabilitar los MPM que rompen
a2dismod mpm_event mpm_worker >/dev/null 2>&1 || true
a2enmod mpm_prefork >/dev/null 2>&1 || true

# 2) Borrar restos que puedan quedar habilitados igual
rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf || true
a2dismod mpm_event mpm_worker mpm_prefork >/dev/null 2>&1 || true
a2enmod mpm_prefork >/dev/null 2>&1 || true

# 3) Asegurar que prefork esté linkeado en mods-enabled
ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load || true
if [ -f /etc/apache2/mods-available/mpm_prefork.conf ]; then
  ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf || true
fi

echo "MPMs enabled now:"
apache2ctl -M 2>/dev/null | grep mpm || true

# correr init una vez (si existe) en background para no bloquear el inicio
if [ -f /docker-entrypoint-initwp.d/01-init.sh ]; then
  echo "🚀 Launching background init script..."
  nohup /docker-entrypoint-initwp.d/01-init.sh > /proc/1/fd/1 2>/proc/1/fd/2 &
fi

# seguir con el entrypoint original de WordPress
exec docker-entrypoint.sh "$@"
