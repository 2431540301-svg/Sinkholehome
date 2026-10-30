#!/usr/bin/env bash
# Cai dat SinkholeHome tren Linux / Raspberry Pi / VPS
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Kiem tra Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "Chua co Docker. Dang cai bang script chinh thuc..."
  curl -fsSL https://get.docker.com | sh
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Thieu Docker Compose plugin. Cai: sudo apt install docker-compose-plugin"
  exit 1
fi

echo "==> Tao file .env..."
if [ ! -f .env ]; then
  cp .env.example .env
  read -r -s -p "Nhap mat khau Pi-hole: " PASS
  echo
  if [ -n "$PASS" ]; then
    sed -i "s|^PIHOLE_PASSWORD=.*|PIHOLE_PASSWORD=${PASS}|" .env
  fi
  read -r -p "Nhap IP public hoac ten mien cua may nay (Enter = auto): " URL
  if [ -n "$URL" ]; then
    sed -i "s|^WG_SERVERURL=.*|WG_SERVERURL=${URL}|" .env
  fi
else
  echo ".env da ton tai, giu nguyen."
fi

echo "==> Kiem tra cong 53..."
if ss -lntu 2>/dev/null | grep -qE ':53\s'; then
  echo "CANH BAO: cong 53 dang bi chiem (thuong la systemd-resolved)."
  echo "Xem docs/HUONG_DAN_TRIEN_KHAI.md muc 'Loi cong 53' de xu ly."
fi

echo "==> Khoi dong cac container..."
docker compose up -d

echo
echo "Xong! Giao dien Pi-hole: http://localhost:8081/admin"
echo "Lay QR WireGuard cho dien thoai: ./scripts/show-qr.sh phone"
