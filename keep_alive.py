from flask import Flask
from threading import Thread
import os

app = Flask('')

@app.route('/')
def home():
    return "Bot is alive! Running on Hugging Face Spaces."

def run():
    # Hugging Face yêu cầu port 7860
    port = int(os.environ.get("PORT", 7860))
    app.run(host='0.0.0.0', port=port)

def keep_alive():
    t = Thread(target=run)
    t.daemon = True
    t.start()

if __name__ == "__main__":
    keep_alive()
