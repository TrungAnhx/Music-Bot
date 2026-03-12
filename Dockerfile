# Sử dụng bản Python Full (Cực kỳ ổn định, đã có sẵn wget, unzip, sed...)
FROM python:3.10-bullseye

# Thiết lập môi trường
ENV DEBIAN_FRONTEND=noninteractive

# Lệnh cài đặt Java và FFmpeg với cơ chế thử lại (Retry) nếu lỗi mạng của Render
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openjdk-17-jre-headless ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Nâng cấp pip và cài thư viện
RUN pip install --no-cache-dir --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code
COPY . .

# Sửa lỗi xuống dòng và phân quyền
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# Tải Lavalink và Plugin Youtube
RUN wget -q https://github.com/lavalink-devs/Lavalink/releases/download/4.0.8/Lavalink.jar
RUN mkdir -p plugins && \
    wget -q https://github.com/lavalink-devs/youtube-source/releases/download/1.17.0/youtube-plugin-1.17.0.jar -P plugins/

EXPOSE 7860

CMD ["./start.sh"]
