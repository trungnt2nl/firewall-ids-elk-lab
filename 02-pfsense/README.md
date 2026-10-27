# Giai đoạn 2: pfSense, NAT và rule WAN

## Thiết kế

- pfSense có 2 NIC: WAN (em0, NAT) và LAN (em1, `192.168.50.1/24`).
- Mặc định WAN **chặn mọi kết nối vào**, LAN **cho phép đi ra**, NAT tự động cho LAN ra WAN.
- Tắt **Block private networks** và **Block bogon networks** trên WAN, vì Attacker nằm trong dải riêng (`192.168.x.x`). Nếu bật, gói từ Attacker bị chặn trước khi tới rule và Suricata. Môi trường thật nên bật.

## Port forward (DNAT)

*Firewall > NAT > Port Forward*:

| Interface | Protocol | Dest. | Dest. port | NAT IP | NAT port | Mô tả |
|---|---|---|---|---|---|---|
| WAN | TCP | WAN address | 23 | 192.168.50.100 | 23 | Lab Telnet to Windows Victim |
| WAN | TCP | WAN address | 80 | 192.168.50.100 | 80 | Lab HTTP to Windows Victim |

Chọn "Add associated filter rule" để pfSense tự tạo rule WAN cho phép. Không có rule này, WAN vẫn chặn gói dù đã dịch địa chỉ.

## Phân biệt kết quả quét

- Cổng đã forward (23, 80): `open`.
- Cổng khác (22, 443): pfSense drop im lặng nên nmap báo `filtered`.
- pfSense không trả lời ping từ WAN, nên dùng `nmap -Pn`.

## Chuẩn bị Victim

Windows Victim `192.168.50.100`: mở cổng 23 và 80 trong Windows Defender Firewall, chạy `ncat -l -k -v -p 23` để giả lập dịch vụ, bật IIS cho cổng 80. Xem `configs/windows/victim-setup.ps1`.

Windows 10/11 không còn Telnet Server, nên `ncat` chỉ **giả lập cổng mở**, không phải Telnet thật.

## Kiểm tra

| Từ | Lệnh | Kết quả |
|---|---|---|
| Attacker | `nmap -Pn -p 22,23,80,443 192.168.141.145` | 23, 80 open; 22, 443 filtered |
| Attacker | `telnet 192.168.141.145 23` | Cửa sổ `ncat` của Victim nhận kết nối |
| pfSense | *Status > System Logs > Firewall* | Gói cổng 23, 80 pass; các cổng khác block |

## Bằng chứng cần có (`evidence/`)

- [ ] Bảng Port Forward và rule WAN
- [ ] `nmap` từ Attacker (23, 80 open; 22, 443 filtered)
- [ ] Cửa sổ `ncat` của Victim nhận kết nối
- [ ] Firewall log có dòng pass và block
- [ ] Màn hình tuỳ chọn Block private networks đã tắt

## Ghi chú

Rule WAN có sẵn từ wizard (OpenVPN UDP 1194) không thuộc lab này. Nếu không dùng, nên vô hiệu hóa để giảm bề mặt phơi ra và nhiễu log.
