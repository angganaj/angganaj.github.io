#!/bin/bash

# Mendapatkan lokasi direktori saat ini
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo "=== Setup Bot ==="

# Kondisi cek file 0.sh
if [ -f "$P_DIR/0.sh" ]; then
    echo "✔ File 0.sh ditemukan. Menggunakan konfigurasi yang ada..."
    # Mengambil variabel untuk tampilan konfirmasi (opsional)
    source "$P_DIR/0.sh"
    echo "   Device Name: $DEVICE_NAME"
else
    echo "ℹ File 0.sh tidak ditemukan. Silakan masukkan data baru:"
    read -p "Masukkan Nama perangkat  : " INPUT_NAMA
    read -p "Masukkan API BOT Telegram: " INPUT_TOKEN
    read -p "Masukkan Chat ID Telegram: " INPUT_ID
    read -p "Masukkan Chat ID Telegram: " GROUP_ID

    # 1. Membuat file 0.sh
    cat << EOC > "$P_DIR/0.sh"
#!/bin/bash
# File Konfigurasi Telegram
TOKEN="$INPUT_TOKEN"
CHAT_ID="$INPUT_ID"
GROUP_ID="$GROUP_ID"
DEVICE_NAME="$INPUT_NAMA"
EOC
    chmod +x "$P_DIR/0.sh"
    echo "✔ File 0.sh berhasil dibuat."
fi

# 2. Menyiapkan Lingkungan Python
echo "--- Menginstall Dependency & VENV ---"
sudo apt-get update && sudo apt-get install -y speedtest-cli python3-venv
python3 -m venv venv
./venv/bin/pip install python-telegram-bot

clear
# 3. Membuat file main.py dengan perintah /1 sampai /5
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/1_.sh && chmod +x 1_.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/2_.sh && chmod +x 2_.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/3_.sh && chmod +x 3_.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/4_.sh && chmod +x 4_.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/5_.sh && chmod +x 5_.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/6_restart_bot.sh && chmod +x 6_restart_bot.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/7_reboot.sh && chmod +x 7_reboot.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/main.py && chmod +x main.py

# crontab - crontab - crontab - crontab - crontab - crontab - crontab - crontab
(crontab -l 2>/dev/null | grep -v "$P_DIR/main.py"; \
 echo "@reboot $P_DIR/7_reboot.sh"
 echo "@reboot cd $P_DIR && $P_DIR/venv/bin/python3 main.py > $P_DIR/bot.log 2>&1 &"
 ) | crontab -


# Memanggil file konfigurasi
source ./0.sh

# Mengambil data tambahan untuk laporan instalasi
OS_INFO=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
WAKTU=$(date +"%d %b %Y, %H:%M:%S")
IP_PUB=$(curl -s https://ifconfig.me)

# Menyusun Pesan Sukses
PESAN="✅ *INSTALLATION SUCCESSFUL* ✅
━━━━━━━━━━━━━━━━━━━━━━
🤖 *Bot Name* : \`$DEVICE_NAME\`
⚙️ *Status* : \`ACTIVE / ONLINE\`
📅 *Tanggal* : \`$WAKTU\`
━━━━━━━━━━━━━━━━━━━━━━
💻 *System Info*:
OS   : \`$OS_INFO\`
IP   : \`$IP_PUB\`
━━━━━━━━━━━━━━━━━━━━━━
🚀 _Bot telah berhasil terinstal._"

# Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null


echo "------------------------------------------------"
echo "SETUP SELESAI!"
echo "Notifikasi instalasi berhasil telah dikirim!"
echo "------------------------------------------------"

./6_restart_bot.sh
sleep 2

rm -- "$0"