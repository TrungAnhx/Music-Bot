from flask import Flask
from threading import Thread
import os

app = Flask('')

@app.route('/')
def home():
    return "Bot is alive!"

def run():
    app.run(host='0.0.0.0', port=8080)

def keep_alive():
    t = Thread(target=run)
    t.start()

if __name__ == "__main__":
    # Chỉ chạy keep_alive khi được import từ main script
    # hoặc khi chạy trực tiếp với parameter
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--keep-alive":
        keep_alive()
