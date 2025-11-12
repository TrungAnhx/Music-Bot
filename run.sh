#!/bin/bash

# Đợi cài đặt hoàn tất (Replit cần thời gian để cài Python từ nix)
echo "Đợi Replit cài đặt môi trường..."
sleep 10

# Tìm Python command trên Replit
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python3.10 &> /dev/null; then
    PYTHON_CMD="python3.10"
elif command -v python3.9 &> /dev/null; then
    PYTHON_CMD="python3.9"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "Không tìm thấy Python! Tự động cấu hình lại..."
    
    # Thử cài đặt pip cho Python
    if command -v python &> /dev/null; then
        echo "Tìm thấy python, cài đặt pip..."
        python -m ensurepip --upgrade
        PYTHON_CMD="python"
    else
        echo "Python chưa được cài. Replit sẽ tự động cài sau khi rebuild."
        echo "Vui lòng vào Shell và chạy: nix-shell --run 'python --version'"
        echo "Sau đó chạy lại bot."
        exit 1
    fi
fi

echo "Sử dụng Python command: $PYTHON_CMD"

# Kiểm tra pip đã được cài đặt chưa
if ! $PYTHON_CMD -m pip --version &> /dev/null; then
    echo "Pip chưa được cài, đang cài đặt..."
    $PYTHON_CMD -m ensurepip --upgrade
fi

# Kiểm tra Java đã được cài đặt chưa
if ! command -v java &> /dev/null; then
    echo "Java chưa được cài đặt! Đang thử cài đặt..."
    # Replit thường cài Java qua nix, chỉ cần kiểm tra
fi

# Kiểm tra file Lavalink.jar tồn tại
if [ ! -f "Lavalink.jar" ]; then
    echo "Không tìm thấy Lavalink.jar! Vui lòng tải file này lên Replit."
    exit 1
fi

# Tạo thư mục logs nếu chưa có
mkdir -p logs

# Bắt đầu Lavalink server ở nền
echo "Khởi động Lavalink server..."
java -jar Lavalink.jar > logs/lavalink.log 2>&1 &
LAVALINK_PID=$!

echo "Lavalink PID: $LAVALINK_PID"

# Đợi Lavalink khởi động hoàn toàn
echo "Đợi Lavalink khởi động..."
sleep 15

# Kiểm tra Lavalink đã chạy chưa
if ! kill -0 $LAVALINK_PID 2>/dev/null; then
    echo "Lavalink không thể khởi động! Kiểm tra logs/lavalink.log để biết chi tiết."
    cat logs/lavalink.log
    exit 1
fi

echo "Lavalink đã khởi động thành công!"

# Chạy bot Python
echo "Khởi động Discord bot..."
$PYTHON_CMD main_hybrid.py
