#!/bin/bash
set -e

echo "🔧 [PATCH] Fixing Apache MPM Config..."

# 1. Force disable all MPMs first to be safe
rm -f /etc/apache2/mods-enabled/mpm_event.load
rm -f /etc/apache2/mods-enabled/mpm_event.conf
rm -f /etc/apache2/mods-enabled/mpm_worker.load
rm -f /etc/apache2/mods-enabled/mpm_worker.conf
rm -f /etc/apache2/mods-enabled/mpm_prefork.load
rm -f /etc/apache2/mods-enabled/mpm_prefork.conf

# 2. Enable ONLY prefork (compatible with PHP)
ln -s /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load
ln -s /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf

echo "✅ [PATCH] MPM Config Fixed. Active modules:"
ls -l /etc/apache2/mods-enabled/mpm_*.load
