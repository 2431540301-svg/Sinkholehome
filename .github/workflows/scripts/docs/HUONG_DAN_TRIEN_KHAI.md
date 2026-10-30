# Hướng dẫn triển khai SinkholeHome (TV1)

Hệ thống gồm: **Pi-hole** (chặn quảng cáo/DNS sinkhole) → **Unbound** (DNS đệ quy riêng) và **WireGuard** (VPN để điện thoại dùng Pi-hole ở ngoài nhà).

## 0. Chuẩn bị chung

- Máy cài Linux (Ubuntu/Debian/Raspberry Pi OS) hoặc Windows có Docker Desktop.
- Mở cổng: `53/tcp+udp` (DNS, chỉ cần trong mạng nội bộ), `51820/udp` (WireGuard), `8081/tcp` (web Pi-hole, chỉ nên mở nội bộ).

## 1. Cài nhanh (Linux / Pi / VPS)

```bash
git clone <link-repo> sinkholehome
cd sinkholehome
./install.sh
```

Windows (PowerShell, chạy bằng quyền Administrator):

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

Kiểm tra:

```bash
docker compose ps
```

Cả `pihole`, `unbound`, `wireguard` phải ở trạng thái `Up` (pihole có thêm `healthy`). Vào `http://<ip-may>:8081/admin`, đăng nhập bằng mật khẩu trong `.env`.

## 2. Triển khai trên VPS

1. Thuê VPS Ubuntu 22.04+, mở firewall: `51820/udp` (WireGuard) và `22/tcp` (SSH).
2. **Không mở cổng 53 ra Internet** (sẽ bị lợi dụng tấn công DDoS khuếch đại). Điện thoại dùng DNS qua VPN WireGuard là đủ.
3. Sửa `.env`: `WG_SERVERURL=<IP public của VPS>`.
4. Chạy `./install.sh`, rồi `docker compose restart wireguard` nếu vừa đổi `WG_SERVERURL`.
5. Nếu mở trang web quản trị, chỉ truy cập qua VPN (địa chỉ `http://172.20.0.2/admin` hoặc `http://10.13.13.1:8081/admin`).

## 3. Triển khai trên Raspberry Pi

1. Cài Raspberry Pi OS Lite 64-bit, bật SSH, đặt **IP tĩnh** (sửa `/etc/dhcpcd.conf` hoặc đặt DHCP reservation trên router).
2. Chạy `./install.sh`.
3. Port-forward trên router: `51820/udp` → IP của Pi (để dùng VPN từ ngoài nhà).
4. Nếu nhà không có IP public cố định, dùng DDNS (DuckDNS, No-IP) và điền vào `WG_SERVERURL`.

## 4. Dùng cho cả mạng nhà qua router

1. Vào trang quản trị router (thường `192.168.1.1`).
2. Mục **DHCP / LAN**, đặt **DNS server** = IP của Pi/máy chạy SinkholeHome.
3. Khởi động lại Wi-Fi trên thiết bị hoặc `ipconfig /renew` (Windows).
4. Nếu router không cho đổi DNS: đổi DNS thủ công trên từng thiết bị (xem mục 6).

## 5. WireGuard và mã QR cho điện thoại

Số thiết bị chỉnh ở `.env`: `WG_PEERS=phone,laptop`. Sau khi sửa: `docker compose up -d wireguard`.

```bash
./scripts/show-qr.sh phone
```

Trên điện thoại:
1. Cài app **WireGuard** (App Store / Google Play).
2. Bấm **+ → Quét mã QR** (Scan from QR code), quét mã trong terminal.
3. Đặt tên tunnel, bật công tắc. Truy cập thử `https://ads-blocker.com/testing/` hoặc trang có quảng cáo để kiểm tra.

File `.conf` nằm tại `./wireguard/peer_phone/peer_phone.conf` (dùng cho laptop: import vào app WireGuard).

> Không đưa thư mục `wireguard/` và file `.env` lên GitHub (đã có trong `.gitignore`), vì chứa khóa riêng.

## 6. Hướng dẫn cài trên từng thiết bị (không dùng VPN)

| Thiết bị | Cách đặt DNS thủ công |
|---|---|
| Windows | Cài đặt → Mạng → Wi-Fi → Thuộc tính → Gán máy chủ DNS → Thủ công → IPv4 → nhập IP máy chạy Pi-hole |
| Android | Cài đặt → Wi-Fi → giữ tên mạng → Sửa → IP: Tĩnh → DNS 1 = IP Pi-hole |
| iOS | Cài đặt → Wi-Fi → (i) → Cấu hình DNS → Thủ công → thêm IP Pi-hole, xóa DNS cũ |

## 7. Lỗi thường gặp

**Lỗi cổng 53 đang bị chiếm (Ubuntu):** do `systemd-resolved`.

```bash
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
docker compose up -d
```

**Không có mạng sau khi bật VPN:** kiểm tra đã mở `51820/udp` trên firewall/router và `WG_SERVERURL` đúng.

**Pi-hole không `healthy`:** xem log `docker compose logs pihole`.

**Cập nhật:** `docker compose pull && docker compose up -d`.

## 8. Đối chiếu với tài liệu API (api.md)

- Backend gọi Pi-hole qua `PIHOLE_URL=http://pihole:80` (tên service trong mạng Docker).
- `GET /api/health` của backend dùng cho healthcheck (đã cấu hình trong compose).
- Phiên bản Pi-hole đã dùng: ghi vào README sau khi chạy `docker exec pihole pihole -v`.
