#!/bin/bash
# Script setup Replit - dùng Lavalink 3.x cho Java 11

echo "🔧 Setting up Discord Music Bot for Replit (Java 11 + Lavalink 3.x)..."

# Tải Lavalink 3.7.12 (tương thích Java 11)
echo "📥 Downloading Lavalink 3.7.12 (compatible with Java 11)..."
curl -L -o Lavalink.jar "https://github.com/freyacodes/Lavalink/releases/download/3.7.12/Lavalink.jar"

# Kiểm tra file
if [ -s "Lavalink.jar" ]; then
    echo "✅ Lavalink 3.7.12 downloaded successfully!"
    echo "File size: $(du -h Lavalink.jar | cut -f1)"
else
    echo "❌ Download failed! Trying alternative..."
    curl -L -o Lavalink.jar "https://cdn.jsdelivr.net/gh/freyacodes/Lavalink@3.7.12/Lavalink.jar"
    
    if [ -s "Lavalink.jar" ]; then
        echo "✅ Downloaded from jsDelivr CDN!"
    else
        echo "❌ All downloads failed!"
        exit 1
    fi
fi

# Tạo application.yml cho Lavalink 3.x
echo "📝 Creating application.yml for Lavalink 3.x..."
cat > application.yml << 'EOF'
server:
  port: 2333
  address: 0.0.0.0

plugins:
  youtube:
    enabled: true
    remoteCipher:
      url: "http://127.0.0.1:8001/"
      userAgent: "musicbot"

lavalink:
  server:
    password: "youshallnotpass"
    sources:
      youtube: true
      bandcamp: true
      soundcloud: true
      twitch: true
      vimeo: true
      http: true
      local: false
    bufferDurationMs: 400
    frameBufferDurationMs: 5000
    youtubePlaylistLoadLimit: 6
    playerUpdateInterval: 5
    youtubeSearchEnabled: true
    soundcloudSearchEnabled: true
    gc-warnings: true

metrics:
  prometheus:
    enabled: false
    endpoint: /metrics

logging:
  file:
    max-history: 30
    max-size: 1GB
  path: ./logs/

  level:
    root: INFO
    lavalink: INFO

  request:
    enabled: true
    includeClientInfo: true
    includeHeaders: false
    includeQueryString: true
    includePayload: true
    maxPayloadLength: 10000
EOF

echo "✅ application.yml created for Lavalink 3.7.12!"

# Tạo thư mục logs
mkdir -p logs

echo ""
echo "🚀 Setup complete! Now run:"
echo "   ./run_replit.sh"
echo ""
echo "📝 Lavalink 3.7.12 + Java 11 = Stable combination for Replit!"
