#!/bin/sh
# Mo cong cho ELK, chi tu dai LAN cua lab
sudo ufw allow from 192.168.50.0/24 to any port 5140 proto udp   # syslog tu pfSense
sudo ufw allow from 192.168.50.0/24 to any port 5601 proto tcp   # Kibana
