# Hướng dẫn deploy MusicBot lên Replit

## 1. Chuẩn bị trên Replit

1. Tạo Repl mới với template "Python"
2. Upload tất cả file từ repository này vào Repl
3. Upload file `Lavalink.jar` (quan trọng!)

## 2. Cấu hình Environment Variables

Vào mục "Secrets" (biểu tượng khóa ở bên trái) và thêm:

```
DISCORD_TOKEN=your_discord_bot_token_here
LAVALINK_URI=http://0.0.0.0:2333
LAVALINK_PASSWORD=youshallnotpass
```

## 3. Giữ bot online 24/7 (Free plan)

Với gói miễn phí của Replit, bot sẽ sleep sau 1 phút không hoạt động:

**Cách 1: Dùng Uptime Robot (khuyên dùng)**
1. Đăng ký tài khoản tại [uptimerobot.com](https://uptimerobot.com)
2. Tạo monitor mới
3. URL: `https://your-repl-name.username.repl.co/`
4. Kiểm tra mỗi 5 phút

**Cách 2: Dùng UptimeChecker.com**
1. Đăng ký tại [uptimechecker.com](https://uptimechecker.com)
2. Tạo monitor với URL của Repl

## 4. Lưu ý

- `Lavalink.jar` cần được upload thủ công lên Replit
- Nếu Lavalink không khởi động, kiểm tra tab Console
- Nếu bot không kết nối Lavalink, đảm bảo LAVALINK_URI đúng
- Giữ file `.env.local` ở local, không bao giờ upload lên GitHub

## 5. Khắc phục lỗi thường gặp

### Lỗi: "Lavalink không thể khởi động"
- Kiểm tra file `Lavalink.jar` đã upload chưa
- Xem tab Console để biết lỗi chi tiết

### Lỗi: "DISCORD_TOKEN không được tìm thấy"
- Kiểm tra lại Environment Variables trong Secrets
- Đảm bảo không có khoảng trắng thừa

### Lỗi: Bot không vào voice
- Kiểm tra quyền của bot trên Discord
- Đảm bảo bot có quyền Voice Connect, Speak
