#!/bin/bash
set -e

# Run our custom initialization script in the background
# It waits for the DB, so it won't fail immediately.
bash /usr/local/bin/run-init-tasks.sh &

# Execute the official Docker entrypoint
# This handles recursive chown, copying WP files, and starting Apache
exec docker-entrypoint.sh "$@"
