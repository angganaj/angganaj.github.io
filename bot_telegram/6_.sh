#!/bin/bash
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $P_DIR

# Matikan bot lama
pkill -f "main.py"
sleep 2

# Jalankan bot dengan Path Absolut
nohup $P_DIR/venv/bin/python3 $P_DIR/main.py > $P_DIR/bot.log 2>&1 &

source $P_DIR/0.sh

PESAN="✅ Restarted Bot Successfully. ✅"

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
