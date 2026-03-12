#!/bin/bash

# Khởi chạy Lavalink với giới hạn RAM tối đa 256MB để tránh bị Hugging Face tắt vì tràn RAM
java -Xmx256M -jar Lavalink.jar > lavalink.log 2>&1 &

echo "⏳ Đang chờ Lavalink khởi động (45s)..."
# Hugging Face chạy Java khá chậm nên cần đợi lâu hơn một chút
sleep 45

# Thiết lập biến môi trường
export LAVALINK_URI=${LAVALINK_URI:-"http://127.0.0.1:2333"}
export LAVALINK_PASSWORD=${LAVALINK_PASSWORD:-"youshallnotpass"}

# Khởi chạy Bot Discord
echo "🚀 Đang khởi chạy Discord Bot..."
python3 -u main_hybrid.py
