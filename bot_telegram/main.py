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

        # status_msg = await update.message.reply_text(f"⏳ Menjalankan {script_name}...")
        status_msg = await update.message.reply_text(f"⏳ Wait...")
        
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

async def cmd_1(u, c): await run_script(u, "1_.sh")
async def cmd_2(u, c): await run_script(u, "2_.sh")
async def cmd_3(u, c): await run_script(u, "3_.sh")
async def cmd_4(u, c): await run_script(u, "4_.sh")
async def cmd_5(u, c): await run_script(u, "5_.sh")
async def cmd_6(u, c): await run_script(u, "6_restart_bot.sh")
async def cmd_7(u, c): await run_script(u, "7_reboot.sh")

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
        app.add_handler(CommandHandler("6", cmd_6))
        app.add_handler(CommandHandler("7", cmd_7))
        
        print(f"Bot Aktif. Menggunakan folder: {BASE_DIR}")
        # drop_pending_updates agar bot tidak mengerjakan perintah usang saat baru nyala
        app.run_polling(drop_pending_updates=True)