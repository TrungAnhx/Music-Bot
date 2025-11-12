#!/bin/bash
# Bắt đầu Lavalink server ở nền
java -jar Lavalink.jar > lavalink.log 2>&1 &

# Đợi Lavalink khởi động
sleep 10

# Chạy bot Python
python3 main_hybrid.py
