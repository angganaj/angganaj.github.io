#!/bin/bash

# Memanggil file konfigurasi
# Gunakan path absolut jika dijalankan via Crontab, contoh: source /home/pi/config.sh
source ./0config.sh

# 1. Mengambil Data Sistem
WAKTU=$(date +"%d-%m-%Y %H:%M:%S")
SUHU=$(vcgencmd measure_temp | cut -d'=' -f2)
UPTIME=$(uptime -p | sed 's/up //')
DISK_INFO=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

# 2. Mengambil IP Address
IP_LIST=$(hostname -I | awk '{for(i=1;i<=NF;i++) printf "- %s (http://%s) ", $i, $i}')

# 3. Menyusun Pesan (Menggunakan $DEVICE_NAME dari config)
PESAN="$DEVICE_NAME
==================
📅 Waktu	: $WAKTU
🏠 Device	: $DEVICE_NAME
🌡️ Suhu CPU	: $SUHU
⏱️ Uptime	: $UPTIME
💾 Disk Used	: $DISK_INFO
==============================
🌐 Koneksi IP:
$IP_LIST
=============================="

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" > /dev/null

echo "Laporan $DEVICE_NAME telah dikirim!"