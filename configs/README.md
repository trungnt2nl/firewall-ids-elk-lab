# configs/

| Duong dan | Noi dung |
|---|---|
| `elk/docker-compose.yml` | ELK 8.13.4 (Elasticsearch, Logstash, Kibana), chi dung trong lab |
| `elk/logstash/pipeline/pfsense.conf` | Pipeline nhan syslog UDP 5140, tach `filterlog` va canh bao Suricata |
| `elk/elasticsearch/index-template.json` | Kieu du lieu (ip, integer, keyword) cho `pfsense-parsed-*` |
| `suricata/custom.rules` | 3 rule tu viet (Telnet SYN, Telnet established, port scan) |
| `ubuntu/netplan-elk.yaml`, `ubuntu/ufw.sh` | IP tinh va firewall cua may ELK |
| `windows/victim-setup.ps1`, `windows/attack-commands.ps1` | Chuan bi Victim va lenh tan cong mo phong |

Cau hinh pfSense (interface, NAT, rule WAN, Suricata, Remote Logging) mo ta o `02-pfsense/` va `03-suricata/`.
KHONG dua `config.xml` cua pfSense len GitHub (co chua mat khau/khoa).
