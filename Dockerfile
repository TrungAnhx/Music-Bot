# Sử dụng Python 3.10 làm base image
FROM python:3.10-slim-bullseye

# Cài đặt các phụ thuộc hệ thống: Java 17, FFmpeg, unzip và các công cụ cần thiết
RUN apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    ffmpeg \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Thiết lập thư mục làm việc
WORKDIR /app

# Copy requirements và cài đặt python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ code vào container
COPY . .

# Giải nén yt-cipher nếu bạn upload file zip để tránh lỗi 504
RUN if [ -f "yt-cipher.zip" ]; then unzip yt-cipher.zip && rm yt-cipher.zip; fi

# Tạo thư mục log cho Lavalink
RUN mkdir -p logs

# Hugging Face Spaces chạy trên cổng 7860
ENV PORT=7860
EXPOSE 7860

# Cấp quyền thực thi cho file chạy
RUN chmod +x start.sh

# Chạy script khởi động
CMD ["./start.sh"]
