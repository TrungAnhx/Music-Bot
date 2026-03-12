# Sử dụng Python 3.10 bản Slim
FROM python:3.10-slim

# Thiết lập môi trường để apt không hỏi xác nhận (non-interactive)
ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt các công cụ: Java, FFmpeg, wget, unzip, sed, ca-certificates
# Thêm --fix-missing để bỏ qua các gói lỗi mạng tạm thời và dọn dẹp kỹ hơn
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    ffmpeg \
    wget \
    unzip \
    sed \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Nâng cấp pip và cài đặt thư viện Python
RUN pip install --no-cache-dir --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ code vào
COPY . .

# Sửa lỗi xuống dòng Windows và phân quyền khởi động
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# Tải Lavalink 4.0.8 ổn định
RUN wget --quiet https://github.com/lavalink-devs/Lavalink/releases/download/4.0.8/Lavalink.jar

# Tải YouTube plugin bản 1.17.0
RUN mkdir -p plugins && \
    wget --quiet https://github.com/lavalink-devs/youtube-source/releases/download/1.17.0/youtube-plugin-1.17.0.jar -P plugins/

EXPOSE 7860

CMD ["./start.sh"]
