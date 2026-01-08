#!/bin/bash
set -e

# Run init script in background, redirecting output to PID 1 stdout/stderr
# This is crucial for Railway logs.
echo "🚀 Starting WordPress (Init script DISABLED for debugging)..."

# (
#   # Wait a bit for Apache to start printing logs so ours don't get mixed up immediately
#   sleep 5
#   /usr/local/bin/init-wp.sh
# ) > /proc/1/fd/1 2> /proc/1/fd/2 &

# Start official WordPress entrypoint
# This copies WP files and starts Apache
exec docker-entrypoint.sh "$@"
