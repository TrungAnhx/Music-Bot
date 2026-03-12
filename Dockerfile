# Dùng bản Python 3.10 gốc
FROM python:3.10

WORKDIR /app

# 1. Tải FFmpeg bản "ăn liền" (Bỏ qua apt-get hoàn toàn)
RUN wget -q https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz && \
    tar -xf ffmpeg-release-amd64-static.tar.xz && \
    mv ffmpeg-*-static/ffmpeg /usr/local/bin/ && \
    mv ffmpeg-*-static/ffprobe /usr/local/bin/ && \
    rm -rf ffmpeg-*

# 2. Tải Java 17 JRE bản "ăn liền" (Bỏ qua apt-get)
RUN wget -q https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10%2B7/OpenJDK17U-jre_x64_linux_hotspot_17.0.10_7.tar.gz && \
    tar -xzf OpenJDK17U-jre_x64_linux_hotspot_17.0.10_7.tar.gz && \
    mv jdk-17.0.10+7-jre /opt/java && \
    rm OpenJDK17U-jre_x64_linux_hotspot_17.0.10_7.tar.gz

# Thiết lập đường dẫn cho Java
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"

# 3. Cài đặt thư viện Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 4. Copy Code
COPY . .
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# 5. Tải Lavalink 4.0.8 và Plugin
RUN wget -q https://github.com/lavalink-devs/Lavalink/releases/download/4.0.8/Lavalink.jar
RUN mkdir -p plugins && \
    wget -q https://github.com/lavalink-devs/youtube-source/releases/download/1.17.0/youtube-plugin-1.17.0.jar -P plugins/

EXPOSE 7860
CMD ["./start.sh"]
