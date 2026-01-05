#!/bin/bash

# Memanggil file konfigurasi
source ./0.sh

echo "Sedang menjalankan Speedtest..."

# 2. Jalankan Speedtest (tanpa --simple agar bisa ambil info ISP, lalu kita filter manual)
# Kita simpan output lengkap ke variabel untuk di-parse
FULL_OUTPUT=$(speedtest-cli)

if [ -z "$FULL_OUTPUT" ]; then
    PESAN="❌ *GAGAL*
Tidak dapat terhubung ke server Speedtest."
else
    # Parsing Data (Menggunakan grep & awk untuk fleksibilitas)
    ISP=$(echo "$FULL_OUTPUT" | grep "Testing from" | sed 's/Testing from //g' | cut -d'(' -f1)
    PING=$(echo "$FULL_OUTPUT" | grep "Hosted by" | awk -F': ' '{print $2}')
    DOWNLOAD=$(echo "$FULL_OUTPUT" | grep "Download:" | awk '{print $2, $3}')
    UPLOAD=$(echo "$FULL_OUTPUT" | grep "Upload:" | awk '{print $2, $3}')
    WAKTU=$(date +"%d %b %Y, %H:%M")
    IP_PUB=$(curl -s https://ifconfig.me)

    # Menyusun Pesan dengan Format Markdown
    # ```text ... ``` digunakan agar angka terlihat seperti kode (monospace)
    PESAN="🚀 *NETWORK REPORT* 🚀
=========================
📅 *$WAKTU*
💻 Host: *$DEVICE_NAME*
🌐 ISP: *$ISP*
🌐 IP PUB: *$IP_PUB*
=========================
📊 *Statistics:*
\`Ping      : $PING\`
\`Download  : $DOWNLOAD\`
\`Upload    : $UPLOAD\`
========================="
fi

# 3. Kirim Hasil
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$GROUP_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null