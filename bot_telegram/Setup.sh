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
    echo "--- kosongkan Group ID jika tidak ada ---"
    read -p "Masukkan Group ID Telegram: " GROUP_ID

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
# 3. Mengunduh File Bot dari Repository
wget https://github.com/angganaj/angganaj.github.io/archive/refs/heads/main.zip -O repo.zip
unzip -q repo.zip "angganaj.github.io-main/bot_telegram/*"
mv angganaj.github.io-main/bot_telegram/* .
rm -rf angganaj.github.io-main repo.zip

clear


# crontab - crontab - crontab - crontab - crontab - crontab - crontab - crontab
(crontab -l 2>/dev/null | grep -v "$P_DIR/main.py"; \
 echo "@reboot $P_DIR/7_.sh"
 echo "0 */3 * * * $P_DIR/1_.sh"
 echo "@reboot cd $P_DIR && $P_DIR/venv/bin/python3 main.py > $P_DIR/bot.log 2>&1 &"
 ) | crontab -

clear

echo "------------------------------------------------"
echo "SETUP SELESAI!"
echo "Notifikasi instalasi berhasil telah dikirim!"
echo "------------------------------------------------"

chmod +x *.sh
chmod +x *.py

sleep 2

# Memanggil file konfigurasi
source $P_DIR/0.sh

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

# 4. Mengirim ke Telegram
# 3. Logika penentuan target (Grup atau Chat Pribadi)
# Jika GROUP_ID tidak kosong, gunakan GROUP_ID. Jika kosong, gunakan CHAT_ID.
if [ -n "$GROUP_ID" ]; then
    TARGET_ID="$GROUP_ID"
else
    TARGET_ID="$CHAT_ID"
fi

# 4. Mengirim ke Telegram menggunakan TARGET_ID yang sudah ditentukan
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$TARGET_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null

rm *.zip
rm -- "$0"