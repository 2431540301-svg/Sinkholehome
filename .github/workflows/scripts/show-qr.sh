#!/usr/bin/env bash
# Hien ma QR WireGuard cho 1 thiet bi. Vi du: ./scripts/show-qr.sh phone
set -euo pipefail
PEER="${1:-phone}"
docker exec wireguard /app/show-peer "$PEER"
echo
echo "File QR dang PNG nam o: ./wireguard/peer_${PEER}/peer_${PEER}.png"
echo "File cau hinh .conf:    ./wireguard/peer_${PEER}/peer_${PEER}.conf"
