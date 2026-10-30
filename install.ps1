# Cai dat SinkholeHome tren Windows (can Docker Desktop)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "==> Kiem tra Docker..."
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Chua co Docker. Hay cai Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
}

docker compose version | Out-Null

Write-Host "==> Tao file .env..."
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    $pass = Read-Host "Nhap mat khau Pi-hole"
    if ($pass) {
        (Get-Content ".env") -replace '^PIHOLE_PASSWORD=.*', "PIHOLE_PASSWORD=$pass" | Set-Content ".env"
    }
    $url = Read-Host "Nhap IP public hoac ten mien (Enter = auto)"
    if ($url) {
        (Get-Content ".env") -replace '^WG_SERVERURL=.*', "WG_SERVERURL=$url" | Set-Content ".env"
    }
} else {
    Write-Host ".env da ton tai, giu nguyen."
}

Write-Host "==> Khoi dong cac container..."
docker compose up -d

Write-Host ""
Write-Host "Xong! Giao dien Pi-hole: http://localhost:8081/admin"
Write-Host "Lay QR WireGuard: docker exec wireguard /app/show-peer phone"
