# Firewall Security Monitoring & Incident Response Lab

Lab giám sát an ninh mạng: **pfSense** làm firewall/gateway, **Suricata** phát hiện hoạt động đáng ngờ, **ELK Stack (Docker)** thu thập, phân tích và trực quan hóa log, sau đó điều tra sự cố từ cảnh báo thật.

> Môi trường: VMware Workstation trên Windows host. VM: pfSense, Ubuntu Server (ELK), Windows (Victim), Windows (Attacker, có nmap).

## Mục tiêu

- Triển khai pfSense tách WAN/LAN, NAT, port forward và rule kiểm soát lưu lượng.
- Tích hợp Suricata (IDS) trên WAN, dùng bộ rule ET Open và rule tự viết.
- Mô phỏng port scan và truy cập Telnet để kiểm thử cảnh báo.
- Xây dựng ELK bằng Docker, chuyển log pfSense và Suricata về qua syslog, phân tích bằng Logstash (grok/csv).
- Dựng dashboard Kibana, điều tra sự cố theo quy trình và viết báo cáo.

## Sơ đồ

```
Windows Attacker (192.168.141.206)
        |  WAN (VMware NAT 192.168.141.0/24)
   [ pfSense ]  WAN em0: 192.168.141.145  |  LAN em1: 192.168.50.1
        |  Suricata (IDS) trên WAN
        |  LAN 192.168.50.0/24
        +-- Windows Victim   192.168.50.100  (Telnet giả lập :23, IIS :80)
        +-- Ubuntu ELK       192.168.50.20   (Elasticsearch, Logstash :5140/udp, Kibana :5601)

pfSense --syslog UDP 5140--> Logstash --> Elasticsearch --> Kibana
```

Chi tiết và sơ đồ Mermaid: [01-topology/topology.md](01-topology/topology.md).

## Công nghệ

pfSense CE, Suricata (ET Open + rule tự viết), Docker Compose, Elasticsearch / Logstash / Kibana 8.13.4, nmap, VMware.

## Luồng dữ liệu

1. Attacker quét cổng và kết nối Telnet vào IP WAN của pfSense.
2. Suricata (WAN) so khớp gói với rule và sinh cảnh báo. pfSense ghi cảnh báo và log firewall (`filterlog`) vào syslog.
3. Remote Logging chuyển syslog (UDP 5140) tới Logstash.
4. Logstash tách trường (IP, cổng, hành động, SID, mô tả), đặt giờ sự kiện, ghi vào chỉ mục `pfsense-parsed-*`.
5. Kibana hiển thị dashboard và dùng Discover để điều tra.

## Cấu trúc repo

```
.
├── 01-topology/            sơ đồ, quy hoạch IP
├── 02-pfsense/             cài đặt pfSense, NAT, rule WAN
├── 03-suricata/            Suricata, rule tự viết
├── 04-elk/                 ELK, pipeline Logstash, dashboard
├── 05-attack-simulation/   kịch bản tấn công mô phỏng
├── 06-incident-analysis/   báo cáo điều tra INC-001
├── 07-troubleshooting/     lỗi gặp phải và cách xử lý
├── configs/                docker-compose, pipeline, rule, netplan...
└── interview-notes.md      câu hỏi ôn phỏng vấn
```

Mỗi thư mục giai đoạn có `README.md` (thiết kế, lệnh, kiểm tra) và `evidence/` (ảnh chụp).

## Kết quả đạt được

Số liệu lấy từ lần chạy trên dashboard (ngày 27/10/2026).

| Hạng mục | Kết quả |
|---|---|
| nmap từ Attacker vào WAN pfSense | Cổng 23 và 80 `open` (đã port forward), 22 và 443 `filtered` |
| Suricata phát hiện scan và Telnet | Có: `LAB Telnet SYN to port 23` (136), `LAB Telnet session established` (212), `ET SCAN Nmap Scripting Engine User-Agent` (16), `ET SCAN MS Terminal Server Traffic on Non-standard Port` (8) |
| Log về ELK và tách trường | Có: `filterlog` và cảnh báo Suricata có đủ `src_ip`, `dst_ip`, `dst_port`, `sid`, `alert_msg` |
| Dashboard Kibana | Có: top IP tấn công, signature, theo thời gian, pass/block (tỉ lệ pass 73,5%, block 26,5%) |
| Điều tra sự cố | Có báo cáo [INC-001](06-incident-analysis/INC-001.md) (phần ngăn chặn chưa thực hiện, ghi rõ trong báo cáo) |

## Bài học rút ra

Xem [07-troubleshooting](07-troubleshooting/README.md): cảnh báo giả do checksum offload, Logstash không nhận log, kiểm soát nhiễu trong dashboard, Suricata ở WAN chỉ thấy IP sau NAT.

## Lưu ý bảo mật

- Lab cô lập trong mạng ảo. Telnet (không mã hóa) và `xpack.security.enabled=false` của Elasticsearch **chỉ dùng cho lab**. Môi trường thật phải mã hóa và bật xác thực.
- Không đưa `config.xml` của pfSense, mật khẩu hoặc khóa lên GitHub (`.gitignore` đã chặn các mẫu phổ biến).
- Địa chỉ IP trong repo là IP riêng (RFC 1918).
