#!/bin/bash
# Script setup đơn giản cho Replit

echo "🔧 Setting up Discord Music Bot on Replit..."

# Tải Lavalink 4.1.1
echo "📥 Downloading Lavalink 4.1.1..."
curl -L -o Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/4.1.1/Lavalink.jar"

# Kiểm tra file
if [ -s "Lavalink.jar" ]; then
    echo "✅ Lavalink 4.1.1 downloaded successfully!"
    echo "File size: $(du -h Lavalink.jar | cut -f1)"
else
    echo "❌ Failed to download! Trying alternative..."
    curl -L -o Lavalink.jar "https://cdn.jsdelivr.net/gh/lavalink-devs/Lavalink@4.1.1/Lavalink.jar"
    
    if [ -s "Lavalink.jar" ]; then
        echo "✅ Downloaded from jsDelivr CDN!"
    else
        echo "❌ All download methods failed!"
        exit 1
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
    echo "✅ application.yml created!"
fi

# Tạo thư mục logs
mkdir -p logs

echo ""
echo "🚀 Setup complete! To run the bot:"
echo "   ./run_bot.sh"
echo ""
echo "📝 Make sure to set Environment Variables in Replit Secrets:"
echo "   DISCORD_TOKEN = your_discord_token"
echo "   LAVALINK_URI = http://0.0.0.0:2333"
echo "   LAVALINK_PASSWORD = youshallnotpass"
