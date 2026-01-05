import subprocess
import os
import asyncio
import logging
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler

# Logging
logging.basicConfig(level=logging.INFO)
BASE_DIR = os.path.dirname(os.path.realpath(__file__))

def load_config():
    config = {}
    try:
        config_file = os.path.join(BASE_DIR, "0.sh")
        with open(config_file, "r") as f:
            for line in f:
                if '=' in line and not line.startswith('#'):
                    key, value = line.replace('"', '').replace("'", "").split('=', 1)
                    config[key.strip()] = value.strip()
        return config
    except: return None

conf = load_config()

async def run_script(update: Update, script_name: str):
    user_chat_id = str(update.effective_chat.id)
    allowed_ids = [conf.get("CHAT_ID"), conf.get("GROUP_ID")]
    
    if user_chat_id in allowed_ids:
        script_path = os.path.join(BASE_DIR, script_name)
        dev_name = conf.get("DEVICE_NAME", "Unknown")
        
        if not os.path.exists(script_path):
            await update.message.reply_text(f"❌ [{dev_name}] File `{script_name}` missing.")
            return

        # 1. Kirim pesan "Wait..."
        status_msg = await update.message.reply_text(f"⏳ [{dev_name}] Wait...")
        
        try:
            # 2. Jalankan skrip bash
            process = await asyncio.create_subprocess_exec(
                "/bin/bash", script_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            # Menunggu proses selesai
            await asyncio.wait_for(process.communicate(), timeout=300)
            
        except Exception as e:
            logging.error(f"Error pada {dev_name}: {e}")
        
        finally:
            # 3. Hapus pesan "Wait..." (Apapun hasilnya, sukses atau error)
            try:
                await status_msg.delete()
            except:
                pass
    else:
        pass

# Mapping Command# --- Bagian Mapping Script ---
# Anda bisa bebas mengubah nama perintah di sebelah kiri
# Contoh: "status": "1_.sh" artinya perintah /status akan menjalankan 1_.sh
COMMAND_MAP = {
    "1":  "1_.sh",
    "2":  "2_.sh",
    "3":  "3_.sh",
    "4":  "4_.sh",
    "5":  "5_.sh",
    "6":  "6_.sh",
    "7":  "7_.sh"
}

async def handle_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_chat_id = str(update.effective_chat.id)
    allowed_ids = [conf.get("CHAT_ID"), conf.get("GROUP_ID")]
    
    if user_chat_id in allowed_ids:
        # Mengambil nama perintah yang diketik (misal: 'status')
        cmd_name = update.message.text.split()[0].replace("/", "")
        script_name = COMMAND_MAP.get(cmd_name)
        
        if not script_name:
            return

        script_path = os.path.join(BASE_DIR, script_name)
        dev_name = conf.get("DEVICE_NAME", "Unknown")
        
        if not os.path.exists(script_path):
            await update.message.reply_text(f"❌ [{dev_name}] File `{script_name}` missing.")
            return

        # 1. Pesan Wait
        status_msg = await update.message.reply_text(f"⏳ [{dev_name}] Wait...")
        
        try:
            # 2. Eksekusi
            process = await asyncio.create_subprocess_exec(
                "/bin/bash", script_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            await asyncio.wait_for(process.communicate(), timeout=300)
        except Exception as e:
            logging.error(f"Error pada {dev_name}: {e}")
        finally:
            # 3. Hapus pesan Wait
            try:
                await status_msg.delete()
            except:
                pass

if __name__ == '__main__':
    if conf:
        app = ApplicationBuilder().token(conf.get("TOKEN")).build()
        
        # Mendaftarkan semua perintah yang ada di COMMAND_MAP secara otomatis
        for cmd in COMMAND_MAP.keys():
            app.add_handler(CommandHandler(cmd, handle_command))
            
        print(f"✅ Node {conf.get('DEVICE_NAME')} Aktif dengan {len(COMMAND_MAP)} perintah.")
        app.run_polling(drop_pending_updates=True)