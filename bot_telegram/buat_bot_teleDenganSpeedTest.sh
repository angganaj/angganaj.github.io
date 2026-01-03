#!/bin/bash

echo "=== Setup Notifikasi, Bot & Speedtest Raspberry Pi ==="
# Meminta input dari user
clear
read -p "Masukkan Nama perangkat  : " INPUT_NAMA
read -p "Masukkan API BOT Telegram: " INPUT_TOKEN
read -p "Masukkan Chat ID Telegram: " INPUT_ID

# 1. Membuat file config.sh berdasarkan input
cat << EOF > config.sh
#!/bin/bash
NAMA="$INPUT_NAMA"
TOKEN="$INPUT_TOKEN"
CHAT_ID="$INPUT_ID"
EOF

# 2. Membuat file reboot.sh (DIOPTIMALKAN: Tanpa loop ping jika dipanggil bot)
cat << 'EOF' > reboot.sh
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$DIR/config.sh" ]; then source "$DIR/config.sh"; else exit 1; fi

# Hanya cek internet jika baru menyala (uptime kurang dari 2 menit)
UPTIME_SEC=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
if [ "$UPTIME_SEC" -lt 120 ]; then
    while ! ping -c 1 8.8.8.8 > /dev/null 2>&1; do sleep 5; done
fi

# Ambil data sistem
WAKTU=$(date '+%d-%m-%Y %H:%M:%S')
HOSTNAME=$(hostname)
SUHU=$(vcgencmd measure_temp | sed "s/temp=//" | sed "s/'/°/")
IP_LAN=$(ip addr show eth0 2>/dev/null | grep "inet " | head -n 1 | awk '{print $2}' | cut -d/ -f1)
IP_WIFI=$(ip addr show wlan0 2>/dev/null | grep "inet " | head -n 1 | awk '{print $2}' | cut -d/ -f1)
UPTIME_P=$(uptime -p | sed 's/up //')
DISK_INFO=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}' )

[ -n "$IP_LAN" ] && LINK_LAN="[$IP_LAN](http://$IP_LAN)" || LINK_LAN="Tidak Terhubung"
[ -n "$IP_WIFI" ] && LINK_WIFI="[$IP_WIFI](http://$IP_WIFI)" || LINK_WIFI="Tidak Terhubung"

PESAN="🚀 *$NAMA Online!*
━━━━━━━━━━━━━━━
📅 *Waktu:* \`$WAKTU\`
🏠 *Hostname:* \`$HOSTNAME\`
🌡️ *Suhu CPU:* \`$SUHU\`
⏱️ *Uptime:* \`$UPTIME_P\`
💾 *Disk Used:* \`$DISK_INFO\`

🌐 *Koneksi IP:*
• LAN: $LINK_LAN
• WiFi: $LINK_WIFI
━━━━━━━━━━━━━━━"

curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}" \
     -d "text=${PESAN}" \
     -d "parse_mode=Markdown" \
     -d "disable_web_page_preview=true"
EOF

# 3. Membuat file speedtest.sh
cat << 'EOF' > speedtest.sh
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"

curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}" \
     -d "text=⏳ *Speedtest dimulai di $NAMA...* Mohon tunggu 30-60 detik." \
     -d "parse_mode=Markdown"

# Jalankan speedtest-cli
HASIL=$(speedtest-cli --simple)

if [ $? -eq 0 ]; then
    PESAN="🚀 *Hasil Speedtest: $NAMA*
━━━━━━━━━━━━━━━
\`$HASIL\`
━━━━━━━━━━━━━━━"
else
    PESAN="❌ Speedtest gagal di *$NAMA*. Pastikan speedtest-cli terinstall."
fi

curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}" \
     -d "text=${PESAN}" \
     -d "parse_mode=Markdown"
EOF

# 4. Menyiapkan Lingkungan (VENV & Dependencies)
echo "--- Menginstall Dependencies Sistem ---"
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip speedtest-cli

echo "--- Menyiapkan Python Bot (venv) ---"
python3 -m venv venv
./venv/bin/pip install python-telegram-bot

# 5. Membuat file main.py (Fast Respond dengan Popen)
cat << 'EOF' > main.py
import subprocess
import os
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler, MessageHandler, filters

def load_config():
    config = {}
    dir_path = os.path.dirname(os.path.realpath(__file__))
    config_file = os.path.join(dir_path, "config.sh")
    if not os.path.exists(config_file): return None
    with open(config_file, "r") as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                key, value = line.replace('"', '').replace("'", "").split('=', 1)
                config[key.strip()] = value.strip()
    return config

conf = load_config()

async def run_script(script_name, update):
    chat_id_user = str(update.effective_chat.id)
    chat_id_config = conf.get("CHAT_ID")
    
    # Izinkan jika ID Chat cocok (Grup/Private)
    if chat_id_user == chat_id_config:
        dir_path = os.path.dirname(os.path.realpath(__file__))
        script_path = os.path.join(dir_path, script_name)
        # Popen agar Fast Respond (tidak menunggu skrip selesai)
        subprocess.Popen(["/bin/bash", script_path])
    else:
        await update.message.reply_text(f"❌ Akses ditolak.\nID Anda: {chat_id_user}")

async def handle_cek(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await run_script("reboot.sh", update)

async def handle_speedtest(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await run_script("speedtest.sh", update)

if __name__ == '__main__':
    if conf:
        app = ApplicationBuilder().token(conf.get("TOKEN")).build()
        # Handlers
        app.add_handler(CommandHandler("cek", handle_cek))
        app.add_handler(MessageHandler(filters.Text(["cek", "Cek", "CEK"]), handle_cek))
        app.add_handler(CommandHandler("speedtest", handle_speedtest))
        
        print("Bot standby...")
        app.run_polling()
EOF

# 6. Membuat file restart.sh
cat << 'EOF' > restart.sh
#!/bin/bash
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkill -f "$P_DIR/main.py"
sleep 2
nohup $P_DIR/venv/bin/python3 $P_DIR/main.py > $P_DIR/bot.log 2>&1 &
/bin/bash "$P_DIR/reboot.sh"
EOF

# 7. Izin Eksekusi & Crontab
chmod +x config.sh reboot.sh main.py speedtest.sh restart.sh
P_DIR=$(pwd)

(crontab -l 2>/dev/null | grep -v "$P_DIR/main.py" | grep -v "$P_DIR/reboot.sh" | grep -v "$P_DIR/restart.sh"; \
 echo "@reboot /bin/bash $P_DIR/reboot.sh"; \
 echo "0 */6 * * * /bin/bash $P_DIR/restart.sh"; \
 echo "@reboot cd $P_DIR && $P_DIR/venv/bin/python3 main.py > $P_DIR/bot.log 2>&1 &") | crontab -

# 8. Jalankan Awal
./reboot.sh
nohup ./venv/bin/python3 main.py > bot.log 2>&1 &

clear
echo "------------------------------------------------"
echo "SETUP BERHASIL!"
echo "------------------------------------------------"
echo "Perintah Telegram:"
echo "1. /cek atau ketik 'cek' - Status Sistem"
echo "2. /speedtest - Cek Kecepatan Internet"
echo "------------------------------------------------"
echo "Bot akan RESTART & LAPORAN tiap 6 jam otomatis."
echo "------------------------------------------------"

rm -- "$0"