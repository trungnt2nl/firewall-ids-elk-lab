# Giai đoạn 4: ELK Stack, pipeline và dashboard

## Thiết kế

- Ubuntu Server `192.168.50.20` trong LAN pfSense chạy Docker Compose: Elasticsearch, Logstash, Kibana (8.13.4).
- pfSense gửi syslog UDP 5140 tới Logstash. Logstash tách trường, ghi vào `pfsense-parsed-YYYY.MM.dd`.
- ELK đặt trong LAN (sau firewall, vùng tin cậy), ra Internet qua NAT của pfSense để kéo image Docker.

## Cài đặt

```
# Docker
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo sysctl -w vm.max_map_count=262144           # bắt buộc cho Elasticsearch
# Firewall Ubuntu (chỉ từ LAN)
sh configs/ubuntu/ufw.sh
# Khởi động
cd configs/elk && docker compose up -d
# Index template (kiểu dữ liệu ip, integer, keyword)
curl -X PUT 'localhost:9200/_index_template/pfsense-parsed' -H 'Content-Type: application/json' -d @elasticsearch/index-template.json
```

Đặt IP tĩnh cho Ubuntu bằng `configs/ubuntu/netplan-elk.yaml` (`dhcp4: false`).

pfSense: *Status > System Logs > Settings > Remote Logging Options*: bật, Source Address `LAN`, Remote log server `192.168.50.20:5140`, Contents: Everything. Sau khi sửa phải **Save** để dịch vụ syslog áp dụng.

## Định dạng log và pipeline

Pipeline: [`configs/elk/logstash/pipeline/pfsense.conf`](../configs/elk/logstash/pipeline/pfsense.conf).

| Log | Ví dụ | Cách tách |
|---|---|---|
| Firewall | `<134>Oct 26 21:29:15 filterlog[8232]: 76,,,1000003711,em0,match,pass,out,4,0x0,,63,8102,0,DF,17,udp,216,192.168.141.145,185.125.190.122,3590,123,196` | grok phần đầu, `csv` phần sau |
| Suricata | `<141>Oct 27 09:58:41 suricata[73724]: [1:2200075:2] SURICATA UDPv4 invalid checksum [Classification: Generic Protocol Command Decode] [Priority: 3] {UDP} 192.168.141.145:63796 -> 150.171.21.9:53` | grok |

- `<134>` = facility 16 (local0) × 8 + severity 6 (info). `<141>` = 17 (local1) × 8 + 5 (notice).
- Bộ lọc `date` lấy giờ trong log (múi giờ `Asia/Ho_Chi_Minh`) làm `@timestamp`.
- IPv6 và ICMP có bố cục `filterlog` khác nên bỏ các cột có thể sai.
- Dòng không khớp grok được gắn tag `_suricata_grok_failure` hoặc `_syslog_grok_failure` và in ra console để debug.

## Kiểm tra

| Lệnh | Kết quả đúng |
|---|---|
| `docker compose ps` | 3 container `Up` |
| `curl localhost:9200/_cat/indices/pfsense-parsed-*?v` | Có chỉ mục, `docs.count` tăng |
| Kibana Discover: `program : "filterlog"` | Bản ghi có `src_ip`, `dst_ip`, `action`, `interface` |
| `program : "suricata"` | Bản ghi có `sid`, `alert_msg`, `src_ip`, `dst_ip` |
| `tags : "_suricata_grok_failure"` | Không có kết quả |

## Dashboard

Data view `pfsense-parsed-*`, trường thời gian `@timestamp`. Truy vấn lọc cảnh báo thật (bỏ nhiễu checksum):

```
program : "suricata" and not alert_msg : *checksum*
```

| Biểu đồ | Cấu hình |
|---|---|
| Số cảnh báo | Metric, Count |
| Cảnh báo theo thời gian | Bar, X `@timestamp`, break down `alert_msg` |
| Top signature | Table: `sid`, `alert_msg`, Count |
| Top IP | Bar ngang: Top values `src_ip` |
| Mức ưu tiên | Donut: `priority` |
| Firewall pass và block | Donut: `action` (`program : "filterlog" and not dst_port : (123 or 5140 or 138)`) |
| Cổng bị chặn | Table: Top values `dst_port` (`program : "filterlog" and action : "block"`) |

Nhiễu đã loại: cổng 123 (NTP của pfSense), 5140 (chính syslog), 138 (NetBIOS của máy host).

Export dashboard: *Stack Management > Saved Objects > Export*, lưu vào `04-elk/kibana/pfsense-security-monitoring.ndjson` (☐ chưa xuất). Import lại ở *Saved Objects > Import*.

## Bằng chứng cần có (`evidence/`)

- [ ] `docker compose ps` (3 container chạy)
- [ ] Remote Logging trên pfSense
- [ ] Discover: bản ghi `filterlog` và Suricata đã tách trường
- [ ] Dashboard hoàn chỉnh (lúc bình thường và lúc có tấn công)
- [ ] File `.ndjson` của dashboard
