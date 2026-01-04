#!/bin/bash

# Mendapatkan lokasi direktori saat ini
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo "=== Setup Bot Eksekutor Laporan (1-5) ==="

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

    # 1. Membuat file 0.sh
    cat << EOC > "$P_DIR/0.sh"
#!/bin/bash
# File Konfigurasi Telegram
TOKEN="$INPUT_TOKEN"
CHAT_ID="$INPUT_ID"
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

# 1.sh - 1.sh - 1.sh - 1.sh - 1.sh - 1.sh - 1.sh - 1.sh - 1.sh - 1.sh - 1.sh - 1.sh
cat << 'EOC' > 1.sh && chmod +x 1.sh
#!/bin/bash

# Memanggil file konfigurasi
source ./0.sh

# 1. Mengambil Data Sistem
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
📅 *Waktu* : \`$WAKTU\`
📈 *CPU Load* : \`$CPU_LOAD%\`
🌡️ *Suhu CPU* : \`$SUHU\`
⏱️ *Uptime* : \`$UPTIME\`
💾 *RAM Usage* : \`$RAM\`
💽 *Disk* : \`$DISK_INFO\`
===========================
🌐 *KONEKSI JARINGAN*
🔌 *LAN (eth0)* : $LINK_LAN
📶 *WiFi (wlan)* : $LINK_WIFI
===========================
🤖 *Status*: System Normal ✅"

# 5. Mengirim ke Telegram (Gunakan variabel $CHAT_ID sesuai 0.sh)
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" \
    -d disable_web_page_preview="true" > /dev/null

echo "Laporan dikirim ke ID: $CHAT_ID"
EOC

# 2.sh - 2.sh - 2.sh - 2.sh - 2.sh - 2.sh - 2.sh - 2.sh - 2.sh - 2.sh - 2.sh - 2.sh
cat << 'EOC' > 2.sh && chmod +x 2.sh
#!/bin/bash

# Memanggil file konfigurasi
source ./0.sh

# 1. Kirim Notifikasi Awal (Status Sedang Berjalan)
START_MSG="⏳ *SPEEDTEST STARTED*
Sedang melakukan pengujian jaringan pada:
💻 Device: \`$DEVICE_NAME\`
Mohon tunggu sebentar..."

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$START_MSG" \
    -d parse_mode="Markdown" > /dev/null

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

    # Menyusun Pesan dengan Format Markdown
    # ```text ... ``` digunakan agar angka terlihat seperti kode (monospace)
    PESAN="🚀 *NETWORK REPORT* 🚀
=========================
📅 *$WAKTU*
💻 Host: *$DEVICE_NAME*
📡 ISP: *$ISP*
=========================
📊 *Statistics:*
\`Ping      : $PING\`
\`Download  : $DOWNLOAD\`
\`Upload    : $UPLOAD\`
========================="
fi

# 3. Kirim Hasil
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null

echo "Selesai!"
EOC

# 3.sh - 3.sh - 3.sh - 3.sh - 3.sh - 3.sh - 3.sh - 3.sh - 3.sh - 3.sh - 3.sh - 3.sh
cat << 'EOC' > 3.sh && chmod +x 3.sh
#!/bin/bash

# Memanggil file konfigurasi
# Gunakan path absolut jika dijalankan via Crontab, contoh: source /home/pi/config.sh
source ./0.sh

PESAN="$DEVICE_NAME file 3"

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" > /dev/null

echo "Laporan $DEVICE_NAME telah dikirim!"
EOC

# 4.sh - 4.sh - 4.sh - 4.sh - 4.sh - 4.sh - 4.sh - 4.sh - 4.sh - 4.sh - 4.sh - 4.sh
cat << 'EOC' > 4.sh && chmod +x 4.sh
#!/bin/bash

# Memanggil file konfigurasi
# Gunakan path absolut jika dijalankan via Crontab, contoh: source /home/pi/config.sh
source ./0.sh

PESAN="$DEVICE_NAME file 4"

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" > /dev/null

echo "Laporan $DEVICE_NAME telah dikirim!"
EOC

# 5.sh - 5.sh - 5.sh - 5.sh - 5.sh - 5.sh - 5.sh - 5.sh - 5.sh - 5.sh - 5.sh - 5.sh
cat << 'EOC' > 5.sh && chmod +x 5.sh
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
"

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PESAN" > /dev/null

echo "Laporan $DEVICE_NAME telah dikirim!"
EOC

# restart_bot.sh - restart_bot.sh - restart_bot.sh - restart_bot.sh - restart_bot.sh
cat << 'EOF' > restart_bot.sh && chmod +x restart_bot.sh
#!/bin/bash
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $P_DIR

# Matikan bot lama
pkill -f "main.py"
sleep 2

# Pastikan izin file benar
sudo chmod +x *.sh
sudo chmod +x main.py

# Jalankan bot dengan Path Absolut
nohup $P_DIR/venv/bin/python3 $P_DIR/main.py > $P_DIR/bot.log 2>&1 &

echo "Bot telah direstart di folder $P_DIR"
EOF

# main.py - main.py - main.py - main.py - main.py - main.py - main.py - main.py
cat << 'EOC' > main.py && chmod +x main.py
import subprocess
import os
import asyncio
import logging
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler, Defaults

# 1. Logging untuk memantau error di bot.log
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

# 2. Kunci Path Absolut
BASE_DIR = os.path.dirname(os.path.realpath(__file__))
os.chdir(BASE_DIR)

def load_config():
    config = {}
    config_file = os.path.join(BASE_DIR, "0.sh")
    if not os.path.exists(config_file):
        return None
    with open(config_file, "r") as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                key, value = line.replace('"', '').replace("'", "").split('=', 1)
                config[key.strip()] = value.strip()
    return config

conf = load_config()

async def run_script(update: Update, script_name: str):
    chat_id_user = str(update.effective_chat.id)
    chat_id_config = conf.get("CHAT_ID")
    
    if chat_id_user == chat_id_config:
        # Gunakan Path Absolut agar tidak pernah "File Not Found"
        script_path = os.path.join(BASE_DIR, script_name)
        
        if not os.path.exists(script_path):
            await update.message.reply_text(f"❌ File tidak ditemukan di:\n`{script_path}`", parse_mode="Markdown")
            return

        status_msg = await update.message.reply_text(f"⏳ Menjalankan {script_name}...")
        
        try:
            process = await asyncio.create_subprocess_exec(
                "/bin/bash", script_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            # Menunggu maksimal 5 menit
            await asyncio.wait_for(process.communicate(), timeout=300)
        except Exception as e:
            logging.error(f"Error executing {script_name}: {e}")
            
        try:
            await status_msg.delete()
        except:
            pass
    else:
        await update.message.reply_text(f"❌ Akses ditolak.")

async def cmd_1(u, c): await run_script(u, "1.sh")
async def cmd_2(u, c): await run_script(u, "2.sh")
async def cmd_3(u, c): await run_script(u, "3.sh")
async def cmd_4(u, c): await run_script(u, "4.sh")
async def cmd_5(u, c): await run_script(u, "5.sh")
async def cmd_6(u, c): await run_script(u, "restart_bot.sh")

if __name__ == '__main__':
    if conf:
        TOKEN = conf.get("TOKEN")
        # Pengaturan koneksi yang lebih longgar untuk internet tidak stabil
        app = ApplicationBuilder().token(TOKEN).connect_timeout(60).read_timeout(60).write_timeout(60).build()
        
        app.add_handler(CommandHandler("1", cmd_1))
        app.add_handler(CommandHandler("2", cmd_2))
        app.add_handler(CommandHandler("3", cmd_3))
        app.add_handler(CommandHandler("4", cmd_4))
        app.add_handler(CommandHandler("5", cmd_5))
        app.add_handler(CommandHandler("6", cmd_6))
        
        print(f"Bot Aktif. Menggunakan folder: {BASE_DIR}")
        # drop_pending_updates agar bot tidak mengerjakan perintah usang saat baru nyala
        app.run_polling(drop_pending_updates=True)
EOC

# crontab - crontab - crontab - crontab - crontab - crontab - crontab - crontab
(crontab -l 2>/dev/null | grep -v "$P_DIR/main.py"; \
 echo "@reboot cd $P_DIR && $P_DIR/venv/bin/python3 main.py > $P_DIR/bot.log 2>&1 &") | crontab -

echo "------------------------------------------------"
echo "SETUP SELESAI!"
echo "------------------------------------------------"



rm -- "$0"