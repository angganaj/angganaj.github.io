#!/bin/bash

clear
echo "=== Setup Bot Eksekutor Laporan (1-5) ==="
read -p "Masukkan Nama perangkat  : " INPUT_NAMA
read -p "Masukkan API BOT Telegram: " INPUT_TOKEN
read -p "Masukkan Chat ID Telegram: " INPUT_ID

# 1. Membuat file 0.sh (Pengganti 0.sh)
cat << EOC > 0.sh
#!/bin/bash
# File Konfigurasi Telegram
TOKEN="$INPUT_TOKEN"
CHAT_ID="$INPUT_ID"
DEVICE_NAME="$INPUT_NAMA"
EOC
chmod +x 0.sh

# 2. Menyiapkan Lingkungan Python
echo "--- Menginstall Dependency & VENV ---"
sudo apt-get update && sudo apt-get install -y speedtest-cli python3-venv
python3 -m venv venv
./venv/bin/pip install python-telegram-bot

# 3. Membuat file main.py dengan perintah /1 sampai /5
cat << 'EOC' > main.py
import subprocess
import os
import asyncio
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler, MessageHandler, filters

def load_config():
    config = {}
    dir_path = os.path.dirname(os.path.realpath(__file__))
    config_file = os.path.join(dir_path, "0.sh")
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
        dir_path = os.path.dirname(os.path.realpath(__file__))
        script_path = os.path.join(dir_path, script_name)
        
        if not os.path.exists(script_path):
            await update.message.reply_text(f"❌ File {script_name} tidak ditemukan.")
            return

        status_msg = await update.message.reply_text(f"⏳ Menjalankan {script_name}...")
        
        process = await asyncio.create_subprocess_exec(
            "/bin/bash", script_path,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await process.wait()
        await asyncio.sleep(1) # Jeda sebentar
        await status_msg.delete()
    else:
        await update.message.reply_text(f"❌ Akses ditolak.")

# Handler untuk masing-masing perintah
async def cmd_1(u, c): await run_script(u, "1.sh")
async def cmd_2(u, c): await run_script(u, "2.sh")
async def cmd_3(u, c): await run_script(u, "3.sh")
async def cmd_4(u, c): await run_script(u, "4.sh")
async def cmd_5(u, c): await run_script(u, "5.sh")

if __name__ == '__main__':
    if conf:
        TOKEN = conf.get("TOKEN")
        app = ApplicationBuilder().token(TOKEN).build()
        
        # Mendaftarkan command /1 sampai /5
        app.add_handler(CommandHandler("1", cmd_1))
        app.add_handler(CommandHandler("2", cmd_2))
        app.add_handler(CommandHandler("3", cmd_3))
        app.add_handler(CommandHandler("4", cmd_4))
        app.add_handler(CommandHandler("5", cmd_5))
        
        print("Bot standby (Perintah: /1, /2, /3, /4, /5)")
        app.run_polling()
EOC

# 4. Memberikan izin eksekusi
chmod +x main.py
P_DIR=$(pwd)

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
EOF