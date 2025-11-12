#!/bin/bash
# Script chạy bot đơn giản và ổn định

echo "🎵 Starting Discord Music Bot..."

# Kiểm tra Lavalink
if [ ! -f "Lavalink.jar" ]; then
    echo "❌ Lavalink.jar not found! Run ./setup_replit.sh first"
    exit 1
fi

echo "✅ Lavalink.jar found - Starting server..."

# Khởi động Lavalink
java -jar Lavalink.jar > logs/lavalink.log 2>&1 &
LAVALINK_PID=$!
echo "Lavalink PID: $LAVALINK_PID"

# Đợi Lavalink khởi động
echo "⏳ Waiting for Lavalink to start..."
sleep 20

# Kiểm tra Lavalink
if ! kill -0 $LAVALINK_PID 2>/dev/null; then
    echo "❌ Lavalink failed to start!"
    echo "📋 Checking logs..."
    cat logs/lavalink.log
    exit 1
fi

echo "✅ Lavalink started successfully!"

# Tìm và chạy Python
PYTHON_CMD=""
for cmd in python3 python3.10 python3.9 python; do
    if command -v $cmd &> /dev/null; then
        PYTHON_CMD=$cmd
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Python not found!"
    exit 1
fi

echo "🐍 Using Python: $PYTHON_CMD"
echo "🤖 Starting Discord Bot..."

# Chạy bot
$PYTHON_CMD main_hybrid.py
