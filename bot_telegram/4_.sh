#!/bin/bash

# Memanggil file konfigurasi
P_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $P_DIR/0.sh

PESAN="$DEVICE_NAME file 4"

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
