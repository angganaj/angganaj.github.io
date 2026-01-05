#!/bin/bash

# Memanggil file konfigurasi (Gunakan full path agar aman di crontab)
source ./0.sh

# 1. FUNGSI CEK KONEKSI INTERNET
echo "Menunggu koneksi internet..."
MAX_ATTEMPTS=200  # Maksimal 200 kali percobaan
ATTEMPT=1
IS_ONLINE=false

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    # Ping ke Google DNS (8.8.8.8) untuk cek koneksi
    if ping -c 1 8.8.8.8 &> /dev/null; then
        IS_ONLINE=true
        echo "Internet terhubung!"
        break
    else
        echo "Percobaan $ATTEMPT: Internet belum siap, mencoba lagi dalam 5 detik..."
        sleep 5
        ((ATTEMPT++))
    fi
done

# 2. JIKA INTERNET TERSEDIA, AMBIL DATA DAN KIRIM
if [ "$IS_ONLINE" = true ]; then
    # Mengambil informasi sistem
    WAKTU=$(date +"%d %b %Y, %H:%M:%S")
    IP_INTERNAL=$(hostname -I | awk '{print $1}')
    # Ambil info ISP menggunakan API ipinfo
    ISP=$(curl -s https://ipinfo.io/org | cut -d' ' -f2-)
    [ -z "$ISP" ] && ISP="Unknown"

    # Menyusun Pesan
    PESAN="🔔 *SYSTEM $DEVICE_NAME REBOOTED* 🔔
━━━━━━━━━━━━━━━━━━━━━━
📅 *Waktu Nyala* : \`$WAKTU\`
💻 *Device* : *$DEVICE_NAME*
🌐 *IP Lokal* : \`$IP_INTERNAL\`
📡 *ISP* : \`$ISP\`
━━━━━━━━━━━━━━━━━━━━━━
✅ _Internet terdeteksi setelah $ATTEMPT kali percobaan._
✅ _Sistem siap digunakan._"

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$GROUP_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null
else
    echo "Gagal mengirim notifikasi: Internet tidak tersedia setelah batas waktu."
fi