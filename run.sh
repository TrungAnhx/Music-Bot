#!/bin/bash
# Script chạy bot cho Replit (đơn giản và ổn định)

echo "🎵 Discord Music Bot - Starting..."

# Tải Lavalink 4.1.1 nếu chưa có
if [ ! -f "Lavalink.jar" ]; then
    echo "📥 Downloading Lavalink 4.1.1..."
    curl -L -o Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/4.1.1/Lavalink.jar"
    
    if [ $? -eq 0 ] && [ -s "Lavalink.jar" ]; then
        echo "✅ Lavalink 4.1.1 downloaded successfully!"
    else
        echo "❌ Download failed! Trying CDN..."
        curl -L -o Lavalink.jar "https://cdn.jsdelivr.net/gh/lavalink-devs/Lavalink@4.1.1/Lavalink.jar"
        
        if [ $? -eq 0 ] && [ -s "Lavalink.jar" ]; then
            echo "✅ Downloaded from CDN!"
        else
            echo "❌ All downloads failed! Bot cannot start."
            exit 1
        fi
    fi
fi

# Tạo application.yml nếu chưa có
if [ ! -f "application.yml" ]; then
    echo "📝 Creating application.yml..."
    cat > application.yml << 'EOF'
server:
  port: 2333
  address: 0.0.0.0

lavalink:
  server:
    password: "youshallnotpass"
    sources:
      youtube: false
      bandcamp: true
      soundcloud: true
      twitch: true
      vimeo: true
      http: true
      local: false

plugins:
  youtube:
    enabled: false

logging:
  level:
    root: INFO
  file:
    max-size: 1GB
    path: ./logs/
EOF
fi

# Tạo thư mục logs
mkdir -p logs

echo "🚀 Starting Lavalink server..."
java -jar Lavalink.jar > logs/lavalink.log 2>&1 &
LAVALINK_PID=$!

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

# Tìm Python và chạy bot
echo "🐍 Starting Discord Bot..."
if command -v python3 &> /dev/null; then
    python3 main_hybrid.py
elif command -v python &> /dev/null; then
    python main_hybrid.py
else
    echo "❌ Python not found!"
    exit 1
fi
