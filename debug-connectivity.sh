#!/usr/bin/env bash
# Check outbound connectivity from the Brave container (host run).
set -e
echo "=== Brave container — outbound IP (if any) ==="
docker exec brave-browser sh -c "wget -q -O- --timeout=8 https://ifconfig.me 2>/dev/null || echo 'FAIL'"
echo ""
echo "=== DNS ==="
docker exec brave-browser sh -c "getent hosts one.one.one.one 2>/dev/null || echo 'FAIL'"
echo ""
