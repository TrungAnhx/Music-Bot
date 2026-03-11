#!/bin/bash

# Khởi động Lavalink Server trong background
echo "Starting Lavalink Server..."
java -jar Lavalink.jar &

# Đợi một chút để Lavalink khởi động xong
sleep 15

# Khởi động Bot Python
echo "Starting Discord Bot..."
python main_hybrid.py
