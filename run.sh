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

# Kiểm tra và thiết lập Java 11
export JAVA_HOME=/nix/store/*-openjdk-*/lib/openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Kiểm tra Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
echo "Java version: $JAVA_VERSION"

if ! command -v java &> /dev/null; then
    echo "Java chưa được cài đặt! Vui lòng đợi Replit cài đặt từ replit.nix"
    exit 1
fi

# Kiểm tra xem có phải Java 11 không
if [[ "$JAVA_VERSION" != "11" ]]; then
    echo "Cần Java 11 cho Lavalink 3.7.12! Java hiện tại: $JAVA_VERSION"
    echo "Replit sẽ tự động sử dụng Java 11 sau khi rebuild."
else
    echo "✅ Java 11 đã sẵn sàng cho Lavalink 3.7.12!"
fi

# Kiểm tra và tải Lavalink.jar nếu cần
if [ ! -f "Lavalink.jar" ]; then
    echo "Không tìm thấy Lavalink.jar! Đang tải phiên bản tương thích Java 11..."
    curl -L -o Lavalink.jar "https://github.com/freyacodes/Lavalink/releases/download/3.7.12/Lavalink.jar"
    
    if [ $? -eq 0 ]; then
        echo "✅ Đã tải Lavalink 3.7.12 thành công!"
    else
        echo "❌ Không thể tải Lavalink.jar. Vui lòng tải thủ công."
        exit 1
    fi
else
    echo "Tìm thấy Lavalink.jar"
    
    # Kiểm tra file có hợp lệ không
    if file Lavalink.jar | grep -q "Zip archive"; then
        echo "✅ Lavalink.jar là file hợp lệ"
        # Kiểm tra phiên bản Lavalink
        if unzip -p Lavalink.jar META-INF/MANIFEST.MF 2>/dev/null | grep -q "Implementation-Version: 3.7.12"; then
            echo "✅ Lavalink phiên bản 3.7.12 (tương thích Java 11)"
        else
            echo "⚠️ Lavalink có thể không tương thích Java 11. Đang tải phiên bản cũ hơn..."
            mv Lavalink.jar Lavalink_old.jar 2>/dev/null
            curl -L -o Lavalink.jar "https://github.com/freyacodes/Lavalink/releases/download/3.7.12/Lavalink.jar"
        fi
    else
        echo "❌ Lavalink.jar không hợp lệ! Đang tải lại..."
        curl -L -o Lavalink.jar "https://github.com/freyacodes/Lavalink/releases/download/3.7.12/Lavalink.jar"
    fi
fi

# Kiểm tra cuối cùng
if [ ! -s "Lavalink.jar" ]; then
    echo "❌ Lavalink.jar trống hoặc không tồn tại! Không thể tiếp tục."
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
