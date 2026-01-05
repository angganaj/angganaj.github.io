import requests
import time
import socket
import os

# ==========================================
# MASUKKAN DATA ANDA DI SINI (MANUAL)
# ==========================================
TOKEN = "8259697579:AAFvywfwW607wpc4jJLjAGT544yhNKI0kx8"
CHAT_ID = "810719690"
DEVICE_NAME = "WINDOWS_PC_SAYA"
# ==========================================

def cek_internet():
    try:
        # Mencoba koneksi ke DNS Google (8.8.8.8)
        socket.create_connection(("8.8.8.8", 53), timeout=5)
        return True
    except:
        return False

def dapatkan_ip_publik():
    try:
        return requests.get("https://ifconfig.me", timeout=10).text.strip()
    except:
        return "Tidak Terdeteksi"

def kirim_notif():
    # Tunggu sampai internet tersedia (logika dari 7_.sh)
    while not cek_internet():
        time.sleep(5)
    
    ip = dapatkan_ip_publik()
    waktu = time.strftime("%d %b %Y, %H:%M:%S")
    
    pesan = (
        f"🔔 *SYSTEM {DEVICE_NAME} REBOOTED* 🔔\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📅 *Waktu Nyala* : `{waktu}`\n"
        f"🌐 *IP Publik* : `{ip}`\n"
        f"✅ *Status* : `Sistem Online`"
    )
    
    url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    payload = {"chat_id": CHAT_ID, "text": pesan, "parse_mode": "Markdown"}
    
    try:
        requests.post(url, data=payload)
    except Exception as e:
        print(f"Gagal mengirim: {e}")

if __name__ == "__main__":
    kirim_notif()