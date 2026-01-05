#!/bin/bash
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $P_DIR

# Matikan bot lama
pkill -f "main.py"
sleep 2

# Jalankan bot dengan Path Absolut
nohup $P_DIR/venv/bin/python3 $P_DIR/main.py > $P_DIR/bot.log 2>&1 &

source ./0.sh

PESAN="✅ Restarted Bot Successfully. ✅"

# 4. Mengirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$GROUP_ID" \
    -d text="$PESAN" \
    -d parse_mode="Markdown" > /dev/null
