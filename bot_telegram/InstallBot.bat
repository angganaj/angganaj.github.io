@echo off
title Auto-Setup Bot Reboot Windows
cls

:: Memastikan dijalankan sebagai Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Harap jalankan file ini dengan: Klik Kanan -^> Run as Administrator
    pause
    exit
)

echo =========================================
echo    AUTO-INSTALLER PYTHON ^& BOT REBOOT
echo =========================================

:: 1. CEK DAN INSTAL PYTHON
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Python tidak ditemukan. Memulai proses download...
    powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe -OutFile python_installer.exe"
    echo [!] Menginstall Python (Silakan tunggu sekitar 1 menit)...
    start /wait python_installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    del python_installer.exe
    echo ✔ Python berhasil diinstal.
    
    :: Refresh PATH agar perintah 'python' langsung bisa dipakai
    set "PATH=%PATH%;C:\Program Files\Python311;C:\Program Files\Python311\Scripts"
) else (
    echo ✔ Python sudah terinstall.
)

:: 2. INSTAL LIBRARY
echo [2/4] Menginstall library requests...
pip install requests --quiet

:: 3. INPUT DATA TELEGRAM
echo.
set /p INPUT_NAMA="Masukkan Nama Perangkat (Contoh: Laptop-Gaming): "
set /p INPUT_TOKEN="Masukkan API BOT Telegram: "
set /p INPUT_ID="Masukkan Chat ID Telegram: "

:: 4. BUAT SCRIPT NOTIFIKASI
echo [3/4] Membuat script Python...
set "SCRIPT_PATH=%CD%\reboot_notify.py"
(
echo import requests, time, socket, os
echo TOKEN = "%INPUT_TOKEN%"
echo CHAT_ID = "%INPUT_ID%"
echo DEVICE_NAME = "%INPUT_NAMA%"
echo def cek_internet(^):
echo     try:
echo         socket.create_connection(("8.8.8.8", 53^), timeout=5^)
echo         return True
echo     except: return False
echo while not cek_internet(^): time.sleep(5^)
echo try:
echo     ip = requests.get("https://ifconfig.me", timeout=10^).text
echo except: ip = "Unknown"
echo waktu = time.strftime("%%d %%b %%Y, %%H:%%M:%%S"^)
echo pesan = f"🔔 *SYSTEM {DEVICE_NAME} REBOOTED* 🔔\n\n📅 *Waktu*: `{waktu}`\n🌐 *IP*: `{ip}`\n✅ Windows Online!"
echo requests.post(f"https://api.telegram.org/bot{TOKEN}/sendMessage", data={"chat_id": CHAT_ID, "text": pesan, "parse_mode": "Markdown"}^)
) > "%SCRIPT_PATH%"

:: 5. DAFTARKAN KE STARTUP (Tanpa Jendela Hitam)
echo [4/4] Mendaftarkan ke Startup...
set "VBS_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\RunBot.vbs"
(
echo Set WinScriptHost = CreateObject("WScript.Shell"^)
echo WinScriptHost.Run Chr(34^) ^& "pythonw.exe" ^& Chr(34^) ^& " " ^& Chr(34^) ^& "%SCRIPT_PATH%" ^& Chr(34^), 0
echo Set WinScriptHost = Nothing
) > "%VBS_PATH%"

cls
echo =========================================
echo SETUP SELESAI!
echo =========================================
echo Python, Library, dan Bot sudah terpasang.
echo Bot akan jalan otomatis setiap Windows nyala.
echo.
echo Menjalankan tes notifikasi...
pythonw.exe "%SCRIPT_PATH%"
pause