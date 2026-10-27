# Troubleshooting

Mỗi lỗi: triệu chứng, kiểm tra, nguyên nhân, cách sửa, bài học. Ảnh trước và sau lưu trong `evidence/`.

---

## 1. Ubuntu ELK vẫn giữ IP của mạng NAT sau khi đổi VMnet
- **Triệu chứng:** đổi card sang VMnet2 nhưng `ip a` vẫn hiện `192.168.141.131`; không ping được `8.8.8.8`.
- **Kiểm tra:** *VM Settings > Network Adapter* (Custom VMnet2, Connected); netplan có `dhcp4: false`; `ip route`.
- **Nguyên nhân:** IP cũ là lease DHCP của mạng NAT, gateway và DNS không quyết định IP của card. Cần đặt IP tĩnh trong dải LAN.
- **Cách sửa:** netplan với `192.168.50.20/24`, gateway `192.168.50.1` (xem `configs/ubuntu/netplan-elk.yaml`), rồi `sudo netplan apply`.
- **Bài học:** ufw chỉ lọc chiều vào nên không chặn ping ra. Kiểm tra theo chặng: IP, gateway, rồi Internet.
- *(Ghi thêm nguyên nhân cuối cùng khiến ping ra Internet được, nếu bạn nhớ, ví dụ trùng IP `.1` với card host của VMware.)*

## 2. nmap báo cổng 23 `filtered` dù đã port forward
- **Triệu chứng:** lần đầu 23 `open`, lần sau `filtered`; SYN bị gửi lại.
- **Nguyên nhân:** cửa sổ `ncat` đã đóng và Windows Firewall không có rule theo cổng 23, nên Windows im lặng bỏ gói.
- **Cách sửa:** tạo rule theo cổng (`configs/windows/victim-setup.ps1`) và chạy lại `ncat -l -k -v -p 23`.
- **Bài học:** `filtered` (không phản hồi) khác `closed` (có RST).

## 3. Kibana không tạo được data view `pfsense-parsed*`
- **Triệu chứng:** "Name must match one or more data streams, indices, or index aliases".
- **Nguyên nhân:** chưa có chỉ mục nào khớp, vì Logstash chưa ghi dữ liệu vào chỉ mục mới.
- **Cách sửa:** tìm lỗi ở Logstash và đường truyền (mục 4), sinh log mới rồi tạo lại data view.

## 4. Logstash không nhận log sau khi sửa pipeline
- **Triệu chứng:** `pfsense-parsed-*` không tồn tại; không có chỉ mục của ngày mới.
- **Kiểm tra:** `docker compose ps`, `docker compose logs logstash`, `tcpdump -ni any udp port 5140`, bơm một dòng log giả bằng `echo ... > /dev/udp/127.0.0.1/5140`.
- **Nguyên nhân:** pfSense chưa chuyển log tới ELK; sau khi **Save lại** *Remote Logging Options*, log về bình thường.
- **Bài học:** tách lỗi theo hai đoạn: đường truyền (pfSense đến Logstash) và pipeline (Logstash đến Elasticsearch), bằng cách tự bơm log giả vào pipeline.

## 5. `curl` báo `media_type_header_exception`
- **Triệu chứng:** "Incorrect header [Content-Type]. Only one value should be provided".
- **Nguyên nhân:** hai lệnh `curl` bị dán dính liền thành một dòng, nên có hai header `Content-Type`.
- **Cách sửa:** chạy từng lệnh một, hoặc dùng Kibana *Dev Tools*.

## 6. Cảnh báo giả `invalid checksum`
- **Triệu chứng:** hàng nghìn cảnh báo `SURICATA TCPv4/UDPv4/UDPv6 invalid checksum` (SID 2200074, 2200075, 2200078), nguồn là IP WAN của pfSense; dashboard hiện pfSense là "kẻ tấn công" số một.
- **Nguyên nhân:** card ảo giao việc tính checksum cho phần cứng; gói do chính pfSense tạo ra chưa có checksum hoàn chỉnh lúc Suricata bắt.
- **Cách sửa:** loại khỏi dashboard bằng `not alert_msg : *checksum*` (ban đầu chỉ loại một SID nên còn sót cả họ). Sửa gốc: *System > Advanced > Networking > Disable hardware checksum offload*. (☐ chưa xác nhận đã áp dụng.)
- **Bài học:** tuning để giảm false positive; lọc cả họ cảnh báo thay vì từng SID.

## 7. Rule tự viết: cảnh báo trùng lặp và `classification` rỗng
- **Triệu chứng:** `LAB Telnet session established` xuất hiện nhiều lần cùng giây và cùng cổng nguồn; cột `classification` là `(null)`.
- **Nguyên nhân:** rule `established` khớp mọi gói trong phiên; rule chưa có `classtype`.
- **Cách sửa:** thêm `threshold:type limit, track by_src, count 1, seconds 60` và `classtype` (rev:2).

## 8. Dashboard hiển thị sai
- **Top IP đứng đầu là pfSense (`192.168.141.145`):** do cảnh báo giả checksum (mục 6) và traffic `apt` của Ubuntu hiện với nguồn là IP WAN sau NAT.
- **Bảng `dst_port` hiện 0, 20, 40...:** dùng *Intervals* thay vì **Top values**.
- **Khoảng thời gian kéo dài từ 02:03:** do bản ghi test bơm vào lúc debug (giờ UTC bị coi là giờ Việt Nam). Xoá bản ghi test và dùng khoảng thời gian tương đối.

## 9. Suricata ở WAN không thấy máy trong LAN
- **Quan sát:** traffic `apt` của Ubuntu `192.168.50.20` hiện với nguồn `192.168.141.145`.
- **Nguyên nhân:** Suricata bắt ở WAN sau NAT nên nguồn đã bị đổi.
- **Bài học:** bắt ở WAN thấy tốt tấn công từ ngoài vào, nhưng cần đối chiếu log firewall hoặc đặt thêm Suricata ở LAN để xác định máy nội bộ.

## Công cụ tách lỗi đã dùng

`docker compose logs`, `tcpdump`, `/dev/udp` để bơm log giả, `_cat/indices` và `_search` của Elasticsearch, Kibana Discover (KQL), *Services > Suricata > Alerts*, *Status > System Logs > Firewall*, nmap, `ip a` và `ip route`.
