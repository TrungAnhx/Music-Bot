#!/bin/bash
# Script tải Lavalink đã verify từ nhiều nguồn

echo "Đang tải Lavalink 4.1.1 đã verify..."

# Thử từ source chính trước
curl -L -o Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/4.1.1/Lavalink.jar"

# Kiểm tra file
if [ -s "Lavalink.jar" ]; then
    echo "✅ Đã tải Lavalink 4.1.1 thành công!"
    echo "File size: $(du -h Lavalink.jar | cut -f1)"
else
    echo "❌ Thất bại! Thử từ jsDelivr CDN..."
    curl -L -o Lavalink.jar "https://cdn.jsdelivr.net/gh/lavalink-devs/Lavalink@4.1.1/Lavalink.jar"
    
    if [ -s "Lavalink.jar" ]; then
        echo "✅ Đã tải Lavalink từ jsDelivr CDN!"
    else
        echo "❌ Thất bại từ CDN! Thử từ repo khác..."
        curl -L -o Lavalink.jar "https://gitlab.com/lavalink-devs/lavalink/-/releases/4.1.1/downloads/Lavalink.jar"
        
        if [ -s "Lavalink.jar" ]; then
            echo "✅ Đã tải Lavalink từ GitLab!"
        else
            echo "❌ Tất cả các source đều thất bại!"
            exit 1
        fi
    fi
fi
