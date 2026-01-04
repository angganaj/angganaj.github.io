#!/bin/bash

wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/1.sh && chmod +x 1.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/2.sh && chmod +x 2.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/3.sh && chmod +x 3.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/4.sh && chmod +x 4.sh
wget -q --show-progress https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/5.sh && chmod +x 5.sh
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

# 3. Membuat file main.py dengan perintah /1 sampai /5
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
        
        print(f"Bot Aktif. Menggunakan folder: {BASE_DIR}")
        # drop_pending_updates agar bot tidak mengerjakan perintah usang saat baru nyala
        app.run_polling(drop_pending_updates=True)
EOC

# 4. Membuat file restart.sh untuk restart bot
cat << 'EOF' > restart.sh && chmod +x restart.sh
#!/bin/bash
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $P_DIR

# Matikan bot lama
pkill -f "main.py"
sleep 2

# Pastikan izin file benar
chmod +x *.sh
chmod +x main.py

# Jalankan bot dengan Path Absolut
nohup $P_DIR/venv/bin/python3 $P_DIR/main.py > $P_DIR/bot.log 2>&1 &

echo "Bot telah direstart di folder $P_DIR"
EOF

sleep 5
./restart.sh
sleep 2
./5.sh
clear

# 5. Mengatur Crontab agar bot jalan otomatis
(crontab -l 2>/dev/null | grep -v "$P_DIR/main.py"; \
 echo "@reboot cd $P_DIR && $P_DIR/venv/bin/python3 main.py > $P_DIR/bot.log 2>&1 &") | crontab -

echo "------------------------------------------------"
echo "SETUP SELESAI!"
echo "------------------------------------------------"
echo "Cara Penggunaan:"
echo "1. Pastikan file 1.sh sampai 5.sh ada di folder ini."
echo "2. Jalankan bot sekarang: ./venv/bin/python3 main.py"
echo "3. Di Telegram, ketik /1 untuk eksekusi 1.sh, dst."
echo "------------------------------------------------"



rm -- "$0"