#!/bin/bash

wget https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/1.sh && chmod +x 1.sh
wget https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/2.sh && chmod +x 2.sh
wget https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/3.sh && chmod +x 3.sh
wget https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/4.sh && chmod +x 4.sh
wget https://raw.githubusercontent.com/angganaj/angganaj.github.io/refs/heads/main/bot_telegram/5.sh && chmod +x 5.sh

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
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler

# Fungsi untuk mendapatkan path absolut folder tempat main.py berada
BASE_DIR = os.path.dirname(os.path.realpath(__file__))

def load_config():
    config = {}
    config_file = os.path.join(BASE_DIR, "0.sh")
    if not os.path.exists(config_file):
        print(f"ERROR: File konfigurasi tidak ditemukan di: {config_file}")
        return None
    with open(config_file, "r") as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                # Membersihkan tanda kutip dan spasi
                key, value = line.replace('"', '').replace("'", "").split('=', 1)
                config[key.strip()] = value.strip()
    return config

conf = load_config()

async def run_script(update: Update, script_name: str):
    chat_id_user = str(update.effective_chat.id)
    chat_id_config = conf.get("CHAT_ID")
    
    # Validasi Chat ID agar aman
    if chat_id_user == chat_id_config:
        # MENGGUNAKAN PATH ABSOLUT agar file .sh pasti ditemukan
        script_path = os.path.join(BASE_DIR, script_name)
        
        if not os.path.exists(script_path):
            await update.message.reply_text(f"❌ Error: File tidak ditemukan di:\n`{script_path}`", parse_mode="Markdown")
            return

        status_msg = await update.message.reply_text(f"⏳ Menjalankan {script_name}...")
        
        try:
            # Eksekusi dengan path absolut
            process = await asyncio.create_subprocess_exec(
                "/bin/bash", script_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await process.communicate()
            
            # Jika ingin melihat error dari file .sh di log terminal:
            if stderr:
                print(f"Error saat menjalankan {script_name}: {stderr.decode()}")

        except Exception as e:
            await update.message.reply_text(f"❌ Terjadi kesalahan teknis: {str(e)}")
        
        await asyncio.sleep(1) 
        await status_msg.delete()
    else:
        await update.message.reply_text(f"❌ Akses ditolak. ID Anda ({chat_id_user}) tidak terdaftar.")

# Handler perintah
async def cmd_1(u, c): await run_script(u, "1.sh")
async def cmd_2(u, c): await run_script(u, "2.sh")
async def cmd_3(u, c): await run_script(u, "3.sh")
async def cmd_4(u, c): await run_script(u, "4.sh")
async def cmd_5(u, c): await run_script(u, "5.sh")

if __name__ == '__main__':
    if conf:
        TOKEN = conf.get("TOKEN")
        if not TOKEN:
            print("ERROR: TOKEN tidak ditemukan di 0.sh")
        else:
            app = ApplicationBuilder().token(TOKEN).build()
            
            app.add_handler(CommandHandler("1", cmd_1))
            app.add_handler(CommandHandler("2", cmd_2))
            app.add_handler(CommandHandler("3", cmd_3))
            app.add_handler(CommandHandler("4", cmd_4))
            app.add_handler(CommandHandler("5", cmd_5))
            
            print(f"Bot standby di folder: {BASE_DIR}")
            print("Perintah aktif: /1, /2, /3, /4, /5")
            app.run_polling()
    else:
        print("Bot gagal dijalankan karena konfigurasi (0.sh) bermasalah.")
EOC

# 4. Membuat file restart.sh untuk restart bot
cat << 'EOF' > restart.sh && chmod +x restart.sh
#!/bin/bash

# Mendapatkan lokasi direktori tempat skrip ini berada
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "--- Memulai Proses Restart Bot ---"

# 1. Memberikan izin eksekusi ulang pada semua file .sh
chmod +x $P_DIR/*.sh
chmod +x $P_DIR/main.py

# 2. Memperbaiki referensi konfigurasi (jika masih 0config.sh diubah ke 0.sh)
sed -i 's/0config.sh/0.sh/g' $P_DIR/*.sh

# 3. Mematikan bot yang sedang berjalan (jika ada)
echo "Menghentikan bot lama..."
pkill -f "$P_DIR/main.py"
sleep 2

# 4. Menjalankan kembali bot di latar belakang (background)
echo "Menjalankan bot baru..."
nohup $P_DIR/venv/bin/python3 $P_DIR/main.py > $P_DIR/bot.log 2>&1 &

echo "------------------------------------------------"
echo "BOT BERHASIL DIRESTART!"
echo "Log dapat dilihat di: tail -f bot.log"
echo "------------------------------------------------"
EOF

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

sleep 5
./restart.sh
sleep 2
./5.sh

rm -- "$0"