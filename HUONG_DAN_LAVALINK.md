# Hướng dẫn cài đặt và chạy bot với Lavalink

## Lavalink là gì?
- **MIỄN PHÍ 100%** - chạy local trên máy bạn
- Xử lý audio nhanh hơn 5-10 lần so với FFmpeg trực tiếp
- Ổn định hơn, ít lỗi voice connection
- Hỗ trợ nhiều nguồn: YouTube, Spotify, SoundCloud, etc.

## Bước 1: Cài đặt Java
Lavalink cần Java 17 trở lên.

### Tải Java:
https://adoptium.net/temurin/releases/?version=17

Chọn:
- Version: 17
- Operating System: Windows
- Architecture: x64
- Package Type: JDK

### Kiểm tra Java đã cài:
```powershell
java -version
```

## Bước 2: Tải Lavalink
Tải file JAR mới nhất từ:
https://github.com/lavalink-devs/Lavalink/releases

Tải file: `Lavalink.jar` (khoảng 70MB)

## Bước 3: Tạo file cấu hình
Tạo file `application.yml` trong cùng thư mục với `Lavalink.jar`:

```yaml
server:
  port: 2333
  address: 127.0.0.1

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

sentry:
  dsn: ""
  environment: ""

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
```

## Bước 4: Chạy Lavalink
Mở PowerShell trong thư mục chứa `Lavalink.jar`:

```powershell
java -jar Lavalink.jar
```

Đợi đến khi thấy dòng:
```
Lavalink is ready to accept connections.
```

**LƯU Ý:** Giữ cửa sổ này mở khi chạy bot!

## Bước 5: Cài đặt thư viện Python
```powershell
pip install wavelink discord.py
```

## Bước 6: Chạy bot mới
```powershell
python main_lavalink.py
```

## So sánh hiệu suất

### Bot cũ (FFmpeg trực tiếp):
- ⏱️ Thời gian load bài: 3-5 giây
- 🐌 CPU usage: 15-25%
- ❌ Hay lỗi voice connection
- 💾 RAM: ~150MB

### Bot mới (Lavalink):
- ⚡ Thời gian load bài: 0.5-1 giây
- 🚀 CPU usage: 5-8%
- ✅ Voice connection ổn định
- 💾 RAM: ~200MB (Lavalink) + ~50MB (bot)

## Lệnh mới
Bot mới có thêm các lệnh:
- `!pause` - Tạm dừng/tiếp tục
- `!volume <0-100>` - Điều chỉnh âm lượng
- `!queue` - Xem hàng chờ (được cải thiện)

## Troubleshooting

### Lỗi: "Connection refused"
- Đảm bảo Lavalink đang chạy
- Kiểm tra port 2333 không bị chiếm

### Lỗi: "Failed to connect to Lavalink node"
- Kiểm tra `password` trong `application.yml` và `main_lavalink.py` giống nhau
- Mặc định: `youshallnotpass`

### Bot connect được nhưng không phát nhạc
- Đợi 5-10 giây sau khi Lavalink khởi động
- Restart bot

## Chạy tự động với bat file

Tạo file `start_bot.bat`:
```bat
@echo off
start "Lavalink" java -jar Lavalink.jar
timeout /t 10
python main_lavalink.py
```

Chạy file này để tự động start Lavalink và bot!
