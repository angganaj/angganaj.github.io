#!/bin/bash

# Memanggil file konfigurasi
# Gunakan path absolut jika dijalankan via Crontab, contoh: source /home/pi/config.sh
source ./0.sh

PESAN="$DEVICE_NAME file 5
/1
/2
/3
/4
/5
/6
/7
"

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" > /dev/null
