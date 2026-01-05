#!/bin/bash

# Memanggil file konfigurasi
source ./0.sh

# 1. Mengambil Data Sistem
OS_INFO=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
IP_PUB=$(curl -s https://ifconfig.me)
WAKTU=$(date +"%d-%m-%Y %H:%M:%S")
SUHU=$(vcgencmd measure_temp | cut -d'=' -f2)
UPTIME=$(uptime -p | sed 's/up //')
DISK_INFO=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
RAM=$(free -m | awk '/Mem:/ { print $3 "/" $2 "MB" }')
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

# 2. Mengambil IP LAN (eth0) & Membuat Link
IP_LAN=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -n "$IP_LAN" ]; then
    LINK_LAN="[http://$IP_LAN](http://$IP_LAN)"
else
    LINK_LAN="*Disconnected*"
fi

# 3. Mengambil IP WIFI (wlan0) & Membuat Link
IP_WIFI=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -n "$IP_WIFI" ]; then
    LINK_WIFI="[http://$IP_WIFI](http://$IP_WIFI)"
else
    LINK_WIFI="*Disconnected*"
fi

# 4. Menyusun Pesan Markdown
PESAN="⚡️⚡️⚡️ *SYSTEM - $DEVICE_NAME* ⚡️⚡️⚡️
===========================
🖥️ *OS* : \`$OS_INFO\`
📅 *Waktu* : \`$WAKTU\`
📈 *CPU Load* : \`$CPU_LOAD%\`
🌡️ *Suhu CPU* : \`$SUHU\`
⏱️ *Uptime* : \`$UPTIME\`
💾 *RAM Usage* : \`$RAM\`
💽 *Disk* : \`$DISK_INFO\`
===========================
📡 *KONEKSI JARINGAN*
🔌 *LAN (eth0)* : $LINK_LAN
📶 *WiFi (wlan)* : $LINK_WIFI
🌐 *IP PUB* : $IP_PUB
===========================
🤖 *Status*: System Normal ✅"

# 5. Mengirim ke Telegram (Gunakan variabel $CHAT_ID sesuai 0.sh)
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$GROUP_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null
