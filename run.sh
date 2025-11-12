#!/bin/bash
# Script chạy bot cho Replit (đơn giản và ổn định)

echo "🎵 Discord Music Bot - Starting with Java 17..."

# Đợi Replit cài đặt Java 17 từ nix
echo "⏳ Waiting for Replit to install Java 17..."
sleep 15

# Tìm Java sau khi cài đặt
JAVA_CMD=""
for cmd in java java17; do
    if command -v $cmd &> /dev/null; then
        JAVA_CMD=$cmd
        break
    fi
done

if [ -z "$JAVA_CMD" ]; then
    echo "❌ Java 17 not found! Replit is still installing..."
    echo "📝 Please wait 2-3 minutes, then run again."
    echo "🔧 Or close and reopen this Repl to force rebuild."
    exit 1
fi

echo "✅ Found Java: $JAVA_CMD"
echo "🐍 Java version: $($JAVA_CMD -version 2>&1 | head -n 1)"

# Tải Lavalink 4.1.1 nếu chưa có
if [ ! -f "Lavalink.jar" ]; then
    echo "📥 Downloading Lavalink 4.1.1 (requires Java 17)..."
    curl -L -o Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/4.1.1/Lavalink.jar"
    
    if [ $? -eq 0 ] && [ -s "Lavalink.jar" ]; then
        echo "✅ Lavalink 4.1.1 downloaded successfully!"
        echo "📝 File size: $(du -h Lavalink.jar | cut -f1)"
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
$JAVA_CMD -jar Lavalink.jar > logs/lavalink.log 2>&1 &
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

# Kiểm tra phiên bản Java
JAVA_VERSION=$($JAVA_CMD -version 2>&1 | head -n 1 | cut -d'"' -f2)
echo "Java version: $JAVA_VERSION"

if [[ "$JAVA_VERSION" == *"17"* ]]; then
    echo "✅ Java 17 detected - Perfect for Lavalink 4.1.1!"
else
    echo "⚠️ Warning: Java $JAVA_VERSION detected (Lavalink 4.1.1 recommends Java 17)"
fi

# Tìm Python và chạy bot
echo "🐍 Starting Discord Bot..."
if command -v python3 &> /dev/null; then
    PYTHON_CMD=python3
elif command -v python &> /dev/null; then
    PYTHON_CMD=python
else
    echo "❌ Python not found!"
    exit 1
fi

echo "🐍 Using Python: $PYTHON_CMD"
$PYTHON_CMD main_hybrid.py
