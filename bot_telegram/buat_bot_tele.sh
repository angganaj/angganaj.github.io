#!/bin/bash

echo "=== Setup Notifikasi & Bot Raspberry Pi ==="
# # Meminta input dari user
# clear
# read -p "Masukkan Nama perangkat  : " INPUT_NAMA
# read -p "Masukkan API BOT Telegram: " INPUT_TOKEN
# read -p "Masukkan Chat ID Telegram: " INPUT_ID

# # 1. Membuat file config.sh berdasarkan input
# #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# cat << EOF > config.sh && chmod +x config.sh
# #!/bin/bash
# NAMA="$INPUT_NAMA"
# TOKEN="$INPUT_TOKEN"
# CHAT_ID="$INPUT_ID"
# EOF
# #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# 2. Membuat file code.sh (Versi Speedtest)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
cat << 'EOF' > code.sh && chmod +x code.sh
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$DIR/config.sh" ]; then source "$DIR/config.sh"; else exit 1; fi

# Tunggu internet aktif
while ! ping -c 1 8.8.8.8 > /dev/null 2>&1; do sleep 5; done

# Ambil data sistem
WAKTU=$(date '+%d-%m-%Y %H:%M:%S')
HOSTNAME=$(hostname)
SUHU=$(vcgencmd measure_temp | sed "s/temp=//" | sed "s/'/°/")
UPTIME=$(uptime -p | sed 's/up //')
DISK_INFO=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}' )

# --- PROSES SPEEDTEST ---
# Menjalankan speedtest secara ringkas
echo "Sedang menjalankan Speedtest..."
ST_RESULT=$(speedtest-cli --simple)
ST_DOWNLOAD=$(echo "$ST_RESULT" | grep "Download" | awk '{print $2 " " $3}')
ST_UPLOAD=$(echo "$ST_RESULT" | grep "Upload" | awk '{print $2 " " $3}')
ST_PING=$(echo "$ST_RESULT" | grep "Ping" | awk '{print $2 " " $3}')

# --- PERBAIKAN BARIS IP (MULTI-IP) ---
IPS=$(hostname -I)
IP_LIST=""
if [ -z "$IPS" ]; then
    IP_LIST="Tidak Terhubung"
else
    for IP in $IPS; do
        IP_LIST+="- [$IP](http://$IP) "
    done
fi

PESAN="🚀 *$NAMA Online!*
==============================
📅 *Waktu:* \`$WAKTU\`
🏠 *Hostname:* \`$HOSTNAME\`
🌡️ *Suhu CPU:* \`$SUHU\`
⏱️ *Uptime:* \`$UPTIME\`
💾 *Disk Used:* \`$DISK_INFO\`
==============================
🌐 *Koneksi IP:*
$IP_LIST
==============================
🚀 *Internet Speed:*
• Ping: \`$ST_PING\`
• Download: \`$ST_DOWNLOAD\`
• Upload: \`$ST_UPLOAD\`
=============================="

curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}" \
     -d "text=${PESAN}" \
     -d "parse_mode=Markdown" \
     -d "disable_web_page_preview=true"
EOF
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# 3. Menyiapkan VENV dan Python Bot
echo "--- Menyiapkan Python Bot (venv) ---"
# Pastikan paket venv terinstall di sistem
sudo apt-get update && sudo apt-get install -y speedtest-cli
sudo apt-get update && sudo apt-get install -y python3-venv
python3 -m venv venv
./venv/bin/pip install python-telegram-bot



# 4. Membuat file main.py (Versi Perbaikan)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
cat << 'EOF' > main.py && chmod +x main.py
import subprocess
import os
import asyncio
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler, MessageHandler, filters

def load_config():
    config = {}
    dir_path = os.path.dirname(os.path.realpath(__file__))
    config_file = os.path.join(dir_path, "config.sh")
    if not os.path.exists(config_file):
        return None
    with open(config_file, "r") as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                key, value = line.replace('"', '').replace("'", "").split('=', 1)
                config[key.strip()] = value.strip()
    return config

conf = load_config()

async def handle_cek(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id_user = str(update.effective_chat.id)
    chat_id_config = conf.get("CHAT_ID")
    
    if chat_id_user == chat_id_config:
        # Beri respon awal agar user tahu bot sedang bekerja
        status_msg = await update.message.reply_text("⏳ Sedang mengecek sistem & Speedtest... Mohon tunggu.")
        
        dir_path = os.path.dirname(os.path.realpath(__file__))
        script_path = os.path.join(dir_path, "code.sh")
        
        # Menjalankan script secara async agar bot tidak hang
        process = await asyncio.create_subprocess_exec(
            "/bin/bash", script_path,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await process.wait()
        
        # Hapus pesan "Mohon tunggu" setelah selesai
        await context.bot.delete_message(chat_id=chat_id_user, message_id=status_msg.message_id)
    else:
        await update.message.reply_text(f"❌ Akses ditolak. ID Anda ({chat_id_user}) tidak terdaftar.")

if __name__ == '__main__':
    if conf:
        TOKEN = conf.get("TOKEN")
        app = ApplicationBuilder().token(TOKEN).build()
        
        # Mendukung Command /cek dan Text "cek"
        app.add_handler(CommandHandler("cek", handle_cek))
        app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_cek))
        
        print("Bot standby...")
        app.run_polling()
EOF
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



# 5. Izin eksekusi
# Info folder untuk memudahkan testing
P_DIR=$(pwd)

echo "------------------------------------------------"
echo "BERHASIL! Skrip & Bot telah siap di folder: $P_DIR"
echo "------------------------------------------------"
echo "Cara Mengetes Bot:"
echo "1. Jalankan bot: ./venv/bin/python3 main.py"
echo "2. Ketik /cek di Telegram Anda."
echo "------------------------------------------------"
echo "Tambahkan ini ke 'crontab -e' agar otomatis:"
echo "@reboot /bin/bash $P_DIR/code.sh"
echo "@reboot cd $P_DIR && $P_DIR/venv/bin/python3 main.py"
echo "------------------------------------------------"

# Mengambil path folder saat ini
P_DIR=$(pwd)

# Menghapus entri lama agar tidak duplikat, lalu menambah entri baru
# Perhatikan: Sekarang 0 */6 menjalankan restart.sh, bukan code.sh langsung
(crontab -l 2>/dev/null | grep -v "$P_DIR/main.py" | grep -v "$P_DIR/code.sh" | grep -v "$P_DIR/restart.sh"; \
 echo "@reboot /bin/bash $P_DIR/code.sh"; \
 echo "0 */6 * * * /bin/bash $P_DIR/restart.sh"; \
 echo "@reboot cd $P_DIR && $P_DIR/venv/bin/python3 main.py > $P_DIR/bot.log 2>&1 &") | crontab -

echo "------------------------------------------------"
echo "OTOMATISASI CRONTAB BERHASIL!"
echo "1. Bot jalan otomatis saat Startup."
echo "2. Bot akan RESTART & KIRIM LAPORAN setiap 6 jam."
echo "------------------------------------------------"


# 6. Membuat file restart.sh
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
cat << 'EOF' > restart.sh && chmod +x restart.sh
#!/bin/bash
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mematikan bot yang sedang berjalan
pkill -f "$P_DIR/main.py"
sleep 2

# Menjalankan bot kembali di background
nohup $P_DIR/venv/bin/python3 $P_DIR/main.py > $P_DIR/bot.log 2>&1 &

echo "Bot telah direstart!"

# Mengirim laporan status ke Telegram
/bin/bash "$P_DIR/code.sh"
EOF
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# Jalankan notifikasi pertama sebagai tes
./code.sh

echo "--- Menjalankan Bot di Latar Belakang ---"
# Menjalankan bot tanpa mengunci terminal
nohup ./venv/bin/python3 main.py > bot.log 2>&1 &
clear
echo "------------------------------------------------"
echo "BOT SUDAH AKTIF!"
echo "Anda bisa menutup terminal ini sekarang."
echo "Silakan coba ketik /cek di Telegram."
echo "------------------------------------------------"

rm -- "$0"