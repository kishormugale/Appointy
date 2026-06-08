#!/bin/bash
set -euo pipefail

echo "=== ValidateService: Checking application health ==="

MAX_RETRIES=10
RETRY_INTERVAL=3

for i in $(seq 1 $MAX_RETRIES); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/api/health || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        echo "Health check passed (attempt $i)"
        exit 0
    fi

    echo "Health check attempt $i/$MAX_RETRIES returned HTTP $HTTP_CODE, retrying in ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

echo "ERROR: Health check failed after $MAX_RETRIES attempts"
exit 1
