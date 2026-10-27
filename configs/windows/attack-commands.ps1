# Chay tren Windows Attacker (mang WAN, 192.168.141.206) bang PowerShell quyen admin
# 192.168.141.145 = IP WAN cua pfSense
Get-Date
nmap -sS -Pn -p 1-1000 192.168.141.145
nmap -sV -Pn -p 22,23,80,443 192.168.141.145
telnet 192.168.141.145 23
Get-Date
