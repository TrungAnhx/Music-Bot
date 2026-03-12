#!/bin/bash

echo "🌐 Đang kiểm tra kết nối mạng..."
# Thử DNS một lần để "mồi" mạng
nslookup discord.com || echo "⚠️ DNS không phân giải được ngay lập tức."

# Khởi chạy Lavalink với giới hạn RAM tối đa 256MB để tránh bị Render tắt vì tràn RAM
# -Xmx256M: Giới hạn bộ nhớ đệm tối đa 256MB
java -Xmx256M -jar Lavalink.jar > lavalink.log 2>&1 &

echo "⏳ Đang chờ Lavalink khởi động (45s)..."
# Render chạy khá chậm nên cần đợi lâu hơn để Lavalink và Plugin Youtube nạp xong
sleep 45

# Thiết lập biến môi trường
export LAVALINK_URI=${LAVALINK_URI:-"http://127.0.0.1:2333"}
export LAVALINK_PASSWORD=${LAVALINK_PASSWORD:-"youshallnotpass"}

# Khởi chạy Bot Discord với chế độ unbuffered
echo "🚀 Đang khởi chạy Discord Bot..."
python3 -u main_hybrid.py
