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
