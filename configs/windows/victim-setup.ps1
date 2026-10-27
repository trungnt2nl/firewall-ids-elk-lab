# Chay tren Windows Victim (192.168.50.100) bang PowerShell quyen admin
# 1. Mo cong 23 va 80 cho Windows Defender Firewall
New-NetFirewallRule -DisplayName "Lab Telnet+HTTP" -Direction Inbound -Protocol TCP -LocalPort 23,80 -Action Allow

# 2. Gia lap dich vu Telnet bang ncat (di kem nmap). Giu cua so nay mo.
#    ncat -l -k -v -p 23
# 3. HTTP: bat IIS trong "Turn Windows features on or off"
