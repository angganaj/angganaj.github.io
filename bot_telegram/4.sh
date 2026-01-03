#!/bin/bash

# Memanggil file konfigurasi
# Gunakan path absolut jika dijalankan via Crontab, contoh: source /home/pi/config.sh
source ./0config.sh

PESAN="$DEVICE_NAME file 4"

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" > /dev/null

echo "Laporan $DEVICE_NAME telah dikirim!"