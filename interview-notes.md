# Ghi chú ôn phỏng vấn (Intern Network / Security)

Trả lời ngắn gọn, nêu ví dụ từ lab của bạn.

## pfSense, NAT, firewall
1. **pfSense khác router thường ở đâu?** Là stateful firewall, có NAT, và cài thêm package như Suricata.
2. **Vì sao WAN chặn hết còn LAN cho đi ra?** Stateful: kết nối do LAN khởi tạo thì chiều về được phép; kết nối mới từ WAN vào bị chặn mặc định.
3. **Port forward (DNAT) và outbound NAT (SNAT) khác nhau thế nào?** DNAT đổi đích để công bố dịch vụ nội bộ; SNAT đổi nguồn khi ra Internet.
4. **Vì sao cần cả NAT lẫn rule WAN?** NAT chỉ dịch địa chỉ; không có rule cho phép thì WAN vẫn chặn gói.
5. **Vì sao tắt "Block private networks" trên WAN lab?** Attacker nằm trong dải riêng; môi trường thật nên bật.
6. **nmap báo `filtered` và `closed` khác nhau thế nào?** `filtered`: không phản hồi (firewall drop); `closed`: có RST.

## IDS / Suricata
7. **IDS khác IPS thế nào?** IDS chỉ cảnh báo, IPS có thể chặn. Lab chạy IDS.
8. **Suricata phát hiện bằng cách nào, bỏ sót gì?** Signature: bắt được hành vi đã biết, dễ bỏ sót tấn công mới hoặc đã mã hóa.
9. **Vì sao đặt ở WAN? Nhược điểm?** Thấy tấn công từ ngoài, kể cả gói firewall sẽ chặn; nhưng chỉ thấy địa chỉ sau NAT.
10. **Đọc rule:** `alert tcp any any -> any 23 (msg:"..."; flow:to_server; flags:S,12; sid:1000001;)` nghĩa là gì?
11. **`threshold` dùng để làm gì?** Giới hạn cảnh báo lặp (`limit`) hoặc chỉ báo khi vượt ngưỡng (`both`), cần cho phát hiện scan.
12. **False positive là gì? Bạn đã gặp cái nào?** Cảnh báo `invalid checksum` do checksum offload của máy ảo; cảnh báo `apt` là hoạt động bình thường. Xử lý bằng tuning và lọc.
13. **Sau khi firewall chặn vẫn thấy cảnh báo, vì sao?** Suricata đọc gói trước khi firewall quyết định: IDS phát hiện, firewall ngăn chặn.

## Log, syslog, ELK
14. **ELK gồm gì, mỗi cái làm gì?** Elasticsearch lưu và tìm kiếm, Logstash xử lý log, Kibana hiển thị.
15. **Vì sao phải parse log?** Chuỗi thô không lọc, đếm, tổng hợp được; tách trường mới tạo được dashboard và truy vấn.
16. **`<134>` trong syslog nghĩa là gì?** PRI = facility × 8 + severity: 16 × 8 + 6.
17. **grok khác csv filter thế nào?** grok khớp mẫu văn bản; csv tách theo dấu phân cách, nhanh và chính xác hơn cho `filterlog`.
18. **Index template và `ignore_malformed`?** Quy định kiểu dữ liệu (ip, integer) để lọc theo dải IP; `ignore_malformed` tránh mất bản ghi khi một giá trị lỗi.
19. **Syslog UDP có nhược điểm gì?** Không bảo đảm đến nơi, không mã hóa.
20. **Vì sao lab tắt xác thực Elasticsearch? Môi trường thật?** Cho đơn giản trong lab cô lập; thật phải bật bảo mật và TLS.

## Điều tra sự cố
21. **Quy trình xử lý sự cố?** Phát hiện và phân tích, ngăn chặn, loại bỏ, phục hồi, rút kinh nghiệm.
22. **Đối chiếu log firewall với cảnh báo IDS để làm gì?** IDS cho biết gói có độc hại không; firewall log cho biết có được cho qua không.
23. **Telnet có rủi ro gì?** Không mã hóa, thông tin đăng nhập hiện rõ; thay bằng SSH.

## Câu chuyện nên kể
- Từ "không thấy log" tới tìm ra nguyên nhân bằng cách tách hai đoạn (đường truyền và pipeline) và bơm log giả.
- Dashboard ban đầu coi pfSense là kẻ tấn công số một: lần theo tới cảnh báo checksum và NAT.
- Chứng minh chuỗi từ một lệnh nmap tới một cảnh báo hiện trên dashboard Kibana.
