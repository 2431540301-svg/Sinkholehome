# Hướng dẫn triển khai SinkholeHome (TV1)

Hệ thống gồm: **Pi-hole** (chặn quảng cáo, DNS sinkhole), **Unbound** (DNS đệ quy riêng) và **WireGuard** (VPN để điện thoại dùng Pi-hole ở ngoài nhà).

## 0. Chuẩn bị chung

- Máy Linux (Ubuntu/Debian/Raspberry Pi OS) hoặc Windows có Docker Desktop.
- Cổng cần dùng: `53/tcp+udp` (DNS, chỉ trong mạng nội bộ), `51820/udp` (WireGuard), `8081/tcp` (web Pi-hole, chỉ nên mở nội bộ).

## 1. Cài nhanh

Linux / Raspberry Pi / VPS:

```bash
git clone https://github.com/2431540301-svg/Sinkholehome.git
cd Sinkholehome
chmod +x install.sh
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

Các container `pihole`, `unbound`, `wireguard` phải ở trạng thái `Up`. Vào `http://<ip-may>:8081/admin`, đăng nhập bằng mật khẩu trong file `.env`.

## 2. Triển khai trên VPS

1. Thuê VPS Ubuntu 22.04 trở lên, mở firewall `51820/udp` (WireGuard) và `22/tcp` (SSH).
2. Không mở cổng 53 ra Internet vì dễ bị lợi dụng tấn công khuếch đại DDoS. Điện thoại dùng DNS qua VPN WireGuard là đủ.
3. Sửa `.env`: `WG_SERVERURL=<IP public của VPS>`.
4. Chạy `./install.sh`. Nếu đổi `WG_SERVERURL` sau khi đã chạy, gõ `docker compose restart wireguard`.
5. Trang quản trị chỉ truy cập qua VPN.

## 3. Triển khai trên Raspberry Pi

1. Cài Raspberry Pi OS Lite 64-bit, bật SSH, đặt IP tĩnh (hoặc đặt DHCP reservation trên router).
2. Chạy `./install.sh`.
3. Trên router, port-forward `51820/udp` về IP của Pi để dùng VPN từ ngoài nhà.
4. Nếu nhà không có IP public cố định, dùng DDNS (DuckDNS, No-IP) và điền vào `WG_SERVERURL`.

## 4. Dùng cho cả mạng nhà qua router

1. Vào trang quản trị router (thường là `192.168.1.1`).
2. Mục DHCP / LAN: đặt DNS server bằng IP của máy chạy SinkholeHome.
3. Kết nối lại Wi-Fi trên thiết bị (hoặc chạy `ipconfig /renew` trên Windows).
4. Nếu router không cho đổi DNS, đổi DNS thủ công trên từng thiết bị (xem mục 6).

## 5. WireGuard và mã QR cho điện thoại

Số thiết bị chỉnh trong `.env`: `WG_PEERS=phone,laptop`. Sau khi sửa: `docker compose up -d wireguard`.

```bash
./scripts/show-qr.sh phone
```

Trên điện thoại:
1. Cài app WireGuard (App Store hoặc Google Play).
2. Bấm dấu `+`, chọn quét mã QR, quét mã hiện trong terminal.
3. Đặt tên tunnel và bật công tắc. Mở thử một trang web có quảng cáo để kiểm tra.

File cấu hình `.conf` nằm tại `./wireguard/peer_phone/peer_phone.conf` (dùng cho laptop: import vào app WireGuard).

Lưu ý: không đưa thư mục `wireguard/` và file `.env` lên GitHub vì chứa khóa riêng và mật khẩu (đã có trong `.gitignore`).

## 6. Cài DNS thủ công trên từng thiết bị (không dùng VPN)

| Thiết bị | Cách làm |
|---|---|
| Windows | Cài đặt, Mạng, Wi-Fi, Thuộc tính, Gán máy chủ DNS, Thủ công, IPv4, nhập IP máy chạy Pi-hole |
| Android | Cài đặt, Wi-Fi, giữ tên mạng, Sửa, IP: Tĩnh, DNS 1 = IP Pi-hole |
| iOS | Cài đặt, Wi-Fi, biểu tượng (i), Cấu hình DNS, Thủ công, thêm IP Pi-hole và xóa DNS cũ |

## 7. Lỗi thường gặp

**Cổng 53 đang bị chiếm (Ubuntu):** do `systemd-resolved`.

```bash
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
docker compose up -d
```

**Không có mạng sau khi bật VPN:** kiểm tra đã mở `51820/udp` trên firewall/router và `WG_SERVERURL` đúng.

**Pi-hole không healthy:** xem log bằng `docker compose logs pihole`.

**Cập nhật:** `docker compose pull && docker compose up -d`.

## 8. Đối chiếu với tài liệu API

- Backend gọi Pi-hole qua `PIHOLE_URL=http://pihole:80` (tên service trong mạng Docker).
- `GET /api/health` của backend dùng cho healthcheck trong compose.
- Phiên bản Pi-hole đã dùng: chạy `docker exec pihole pihole -v` rồi ghi vào README.

## 9. CI/CD

Workflow `.github/workflows/ci.yml` chạy tự động mỗi lần push, gồm 3 bước: `lint` (yamllint, shellcheck), `build` (kiểm tra compose, build backend/frontend nếu có) và `test-compose` (khởi động Pi-hole + Unbound, thử phân giải DNS).
