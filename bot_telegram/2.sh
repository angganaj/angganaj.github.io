#!/bin/bash

# Memanggil file konfigurasi (Token, Chat ID, dan Device Name)
source ./0config.sh

    # Menyusun Pesan
    PESAN="🚀** **🚀"

# Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null
echo "Sedang menjalankan Speedtest, mohon tunggu..."

# Menjalankan speedtest-cli dan menangkap outputnya
# Menggunakan --simple agar formatnya mudah dibaca (Ping, Download, Upload)
ST_RESULTS=$(speedtest-cli --simple)

if [ -z "$ST_RESULTS" ]; then
    PESAN="❌ Gagal mengambil data Speedtest pada $DEVICE_NAME"
else
    # Mengambil nilai masing-masing
    PING=$(echo "$ST_RESULTS" | grep "Ping" | cut -d' ' -f2,3)
    DOWNLOAD=$(echo "$ST_RESULTS" | grep "Download" | cut -d' ' -f2,3)
    UPLOAD=$(echo "$ST_RESULTS" | grep "Upload" | cut -d' ' -f2,3)
    WAKTU=$(date +"%d-%m-%Y %H:%M:%S")

    # Menyusun Pesan
    PESAN="🚀 **SPEEDTEST REPORT** 🚀
==============================
🏠 Device: $DEVICE_NAME
📅 Waktu: $WAKTU
==============================
latency: $PING
📥 Download: $DOWNLOAD
📤 Upload: $UPLOAD
=============================="
fi

# Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null

echo "Hasil Speedtest telah dikirim ke Telegram!"