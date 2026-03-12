# Sử dụng Python 3.10 bản Slim
FROM python:3.10-slim

# Cài đặt Java, FFmpeg và các công cụ cần thiết
RUN apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    ffmpeg \
    wget \
    unzip \
    sed \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Nâng cấp pip và cài đặt thư viện
RUN pip install --no-cache-dir --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Sửa lỗi xuống dòng và phân quyền
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# Tải Lavalink 4.0.8 ổn định
RUN wget https://github.com/lavalink-devs/Lavalink/releases/download/4.0.8/Lavalink.jar

# Tải YouTube plugin bản 1.17.0 (Mới hơn để tránh lỗi ko phát được nhạc)
RUN mkdir -p plugins && \
    wget https://github.com/lavalink-devs/youtube-source/releases/download/1.17.0/youtube-plugin-1.17.0.jar -P plugins/

EXPOSE 7860

CMD ["./start.sh"]
