# Giai đoạn 5: Mô phỏng tấn công

> Chỉ thực hiện trong lab của chính bạn, trên mạng ảo cô lập.

## Kịch bản

Một máy bên ngoài (Windows Attacker, `192.168.141.206`) trinh sát và truy cập vào pfSense WAN (`192.168.141.145`):

1. **Port scan** 1000 cổng bằng SYN scan.
2. **Dò dịch vụ** (`-sV`) trên các cổng 22, 23, 80, 443.
3. **Kết nối Telnet** tới cổng 23 (đã port forward tới Victim) và gõ thử thông tin đăng nhập.

Lệnh: [`configs/windows/attack-commands.ps1`](../configs/windows/attack-commands.ps1).

## Chuẩn bị

- Victim: `ncat -l -k -v -p 23` đang chạy, cổng 23 và 80 mở trong Windows Firewall.
- Suricata WAN đang running, Remote Logging về ELK đang bật.
- Ghi lại giờ trước và sau cuộc tấn công (`Get-Date`).

## Kết quả mong đợi và đã quan sát

| Hành động | Cảnh báo / log mong đợi | Quan sát được |
|---|---|---|
| `nmap -sS -p 1-1000` | `LAB Possible TCP port scan` (1000003), log `block` nhiều cổng | ☐ chưa xác nhận SID 1000003 trên dashboard |
| `nmap -sV` | `ET SCAN Nmap Scripting Engine User-Agent Detected` (2009358) trên cổng 80 | Có (16 cảnh báo) |
| nmap thăm dò | `ET SCAN MS Terminal Server Traffic on Non-standard Port` (2023753) | Có (8 cảnh báo) |
| Kết nối tới cổng 23 | `LAB Telnet SYN to port 23` (1000001) | Có (136 cảnh báo) |
| Phiên Telnet hoàn tất | `LAB Telnet session established` (1000002) | Có (212 cảnh báo, số liệu trước khi thêm `threshold` rev:2) |

Trong phiên Telnet, thông tin gõ vào hiện **dạng văn bản thường** ở cửa sổ `ncat` của Victim: minh chứng rủi ro của Telnet.

## Cảnh báo không phải tấn công

`ET INFO GNU/Linux APT User-Agent Outbound likely related to package management` (2013504, 45 cảnh báo) là máy Ubuntu ELK chạy `apt`, hiện với nguồn là IP WAN của pfSense do NAT. Đây là hoạt động quản trị bình thường.

## Bằng chứng cần có (`evidence/`)

- [ ] Lệnh nmap và kết quả từ Attacker
- [ ] Cửa sổ `ncat` của Victim hiện chữ gõ từ Telnet
- [ ] Tab Alerts của pfSense và Discover trong Kibana
- [ ] Dashboard lúc có tấn công
