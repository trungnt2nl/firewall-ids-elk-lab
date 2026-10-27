# Giai đoạn 3: Suricata (IDS) trên pfSense

## Thiết kế

- **IDS** chỉ cảnh báo, không chặn (Block Offenders tắt). Dựa trên signature (rule).
- Đặt trên **WAN** để thấy traffic tấn công đi vào, kể cả gói bị firewall chặn (Suricata đọc gói ở tầng card mạng trước khi `pf` quyết định).
- Trên WAN, Suricata thấy **địa chỉ sau NAT**: traffic của máy trong LAN đi ra hiện với nguồn là IP WAN của pfSense.

## Cài đặt

1. *System > Package Manager > Available Packages > Suricata > Install*.
2. *Services > Suricata > Global Settings*: bật **ETOpen Emerging Threats rules**, cập nhật rule ở tab Updates.
3. *Interfaces > Add*: WAN, bật **Send Alerts to System Log** (để chuyển cảnh báo về ELK) và EVE JSON Log, tắt Block Offenders.
4. Tab WAN Categories: chọn các nhóm rule (ví dụ scan, policy, info, misc, dos, exploit) và `custom.rules`.
5. Start interface, kiểm tra mũi tên xanh (running).

## Rule tự viết

File: [`configs/suricata/custom.rules`](../configs/suricata/custom.rules)

```
alert tcp any any -> any 23 (msg:"LAB Telnet SYN to port 23"; flow:to_server; flags:S,12; classtype:attempted-recon; sid:1000001; rev:2;)
alert tcp any any -> any 23 (msg:"LAB Telnet session established"; flow:to_server,established; threshold:type limit, track by_src, count 1, seconds 60; classtype:policy-violation; sid:1000002; rev:2;)
alert tcp any any -> any any (msg:"LAB Possible TCP port scan"; flags:S,12; threshold:type both, track by_src, count 20, seconds 5; classtype:attempted-recon; sid:1000003; rev:2;)
```

| Phần | Ý nghĩa |
|---|---|
| `action protocol src -> dst (options)` | Cấu trúc rule |
| `flow:to_server` | Gói đi tới server |
| `flags:S,12` | Cờ SYN, bỏ qua hai bit ECN |
| `threshold` | Chống cảnh báo lặp (`limit`) hoặc chỉ báo khi vượt ngưỡng (`both`) |
| `classtype` | Phân loại cảnh báo, dùng để lọc trong Kibana |
| `sid >= 1000000` | Dải dành cho rule tự tạo |

Dùng đích `any` vì trên WAN, Suricata thấy đích là IP WAN (chưa DNAT). Rule `established` có `threshold` vì nếu không, mọi gói trong phiên đều sinh cảnh báo.

Rule Telnet của bộ ET nhận diện bằng nội dung gói. `ncat` chỉ là cổng mở giả lập, nên kịch bản này dùng rule tự viết dựa theo cổng.

## Kiểm tra

Từ Attacker: `nmap -sS -Pn -p 1-1000 ...`, `nmap -sV -Pn -p 22,23,80,443 ...`, `telnet ... 23`. Rồi xem *Services > Suricata > Alerts* (WAN).

| Cảnh báo | Nguồn |
|---|---|
| `LAB Telnet SYN to port 23` (1000001) | Rule tự viết |
| `LAB Telnet session established` (1000002) | Rule tự viết |
| `ET SCAN Nmap Scripting Engine User-Agent Detected` (2009358) | Rule ET, nmap `-sV` hỏi IIS |
| `ET SCAN MS Terminal Server Traffic on Non-standard Port` (2023753) | Rule ET |

## Tinh chỉnh (tuning)

Cảnh báo giả `SURICATA ... invalid checksum` (SID 2200074, 2200075, 2200078...) sinh ra từ **chính traffic của pfSense** (nguồn là IP WAN, ví dụ DNS cổng 53), do card ảo giao việc tính checksum cho phần cứng. Cách xử lý:
- Gốc: *System > Advanced > Networking > Disable hardware checksum offload*, khởi động lại pfSense. (Trạng thái trong lab: ☐ chưa xác nhận đã áp dụng.)
- Trong Kibana, lọc `not alert_msg : *checksum*`.

## Bằng chứng cần có (`evidence/`)

- [ ] Package Suricata đã cài và Global Settings
- [ ] Interface WAN running, danh sách categories
- [ ] `custom.rules`
- [ ] Tab Alerts có cảnh báo scan, Telnet và `ET SCAN Nmap...`
