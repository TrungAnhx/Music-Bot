import discord
from discord.ext import commands
import yt_dlp
import asyncio
import logging

# Cấu hình logging
logging.basicConfig(level=logging.DEBUG)

intents = discord.Intents.default()
intents.message_content = True
intents.voice_states = True

FFMPEG_EXECUTABLE = "C:\\Users\\TrungAnhx\\Documents\\MusicBot\\ffmpeg-2024-08-04-git-eb3cc508d8-essentials_build\\bin\\ffmpeg.exe"
FFMPEG_OPTIONS = {
    'before_options': '-reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 5 -probesize 32 -analyzeduration 0',
    'options': '-vn -b:a 128k -bufsize 512k'
}

# ✅ Dùng Android client để né DRM/SABR + tối ưu tốc độ
YDL_OPTIONS = {
    'format': 'bestaudio/best',
    'quiet': True,
    'no_warnings': True,
    'noplaylist': False,
    'extract_flat': False,
    'force_client': 'android',  # né SABR/DRM
    'extractor_args': {'youtube': {'player_client': ['android']}},
    'socket_timeout': 10,
    'http_chunk_size': 10485760,  # 10MB chunks
    'concurrent_fragment_downloads': 5,
}

ALLOWED_TEXT_CHANNEL_IDS = [1224314688842629201, 1225396300443418644]

class MusicBot(commands.Cog):
    def __init__(self, client):
        self.client = client
        self.queue = []
        self.played_queue = []
        self.current = None
        self.repeat = False
        self.stopped = False
        self.cache = {}  # Cache: search -> (url, title) để phát ngay

    @commands.command()
    async def play(self, ctx, *, search):
        if ctx.channel.id not in ALLOWED_TEXT_CHANNEL_IDS:
            return await ctx.send("❌ Bot chỉ được dùng trong kênh văn bản cho phép.")

        voice_channel = ctx.author.voice.channel if ctx.author.voice else None
        if not voice_channel:
            return await ctx.send("⚠️ Bạn cần vào voice channel trước.")

        voice_client = ctx.voice_client
        if not voice_client or not voice_client.is_connected():
            try:
                voice_client = await voice_channel.connect(timeout=10.0, reconnect=True)
                await asyncio.sleep(0.5)

            except Exception as e:
                logging.error(f"Error connecting to voice channel: {e}", exc_info=True)
                return await ctx.send(f"❌ Không thể kết nối vào voice. Thử kick bot và gọi lại.")

        async with ctx.typing():
            self.queue.append(search)
            await ctx.send(f'✅ Đã thêm bài: **{search}** vào hàng chờ.')

        if not ctx.voice_client.is_playing():
            await self.play_next(ctx)

    async def play_next(self, ctx):
        if not ctx.voice_client or not ctx.voice_client.is_connected():
            await ctx.send("❌ Bot không được kết nối với kênh thoại. Vui lòng thử lại.")
            self.queue.clear()
            return

        if self.repeat and self.current:
            self.played_queue.append(self.current)

        if not self.queue:
            if self.repeat and self.played_queue:
                self.queue = self.played_queue.copy()
                self.played_queue.clear()
                await ctx.send("🔁 Đang phát lại danh sách nhạc...")
                return await self.play_next(ctx)

            self.current = None
            if not self.stopped:
                await ctx.send("📭 Hàng chờ rỗng. Thêm bài mới?")
            await asyncio.sleep(180)
            if not self.queue and ctx.voice_client and ctx.voice_client.is_connected() and not ctx.voice_client.is_playing():
                if not self.stopped:
                    await ctx.send("👋 Không có nhạc sau 3 phút. Bot rời khỏi voice.")
                self.repeat = False
                self.stopped = False
                await ctx.voice_client.disconnect()
            return

        search = self.queue.pop(0)

        try:
            # Use 'default_search' to handle both URLs and search queries gracefully.
            ydl_opts = YDL_OPTIONS.copy()
            ydl_opts['default_search'] = 'ytsearch1'

            # Extract info in executor to avoid blocking
            loop = asyncio.get_event_loop()
            info = await loop.run_in_executor(None, lambda: yt_dlp.YoutubeDL(ydl_opts).extract_info(search, download=False))

            # If the result is a playlist, handle it.
            if 'entries' in info and info.get('_type') == 'playlist':
                # It's a playlist from a search or URL
                entry = info['entries'][0]
            elif 'entries' in info:
                # It's a search result that is a list of videos
                entry = info['entries'][0]
            else:
                # It's a single video result.
                entry = info

            if not entry:
                await ctx.send(f"❌ Không tìm thấy kết quả cho: `{search}`")
                return await self.play_next(ctx)

            url = entry.get("url")
            title = entry.get("title", "Không rõ tiêu đề")

        except Exception as e:
            logging.error(f"Lỗi khi lấy thông tin video cho '{search}': {e}", exc_info=True)
            if not self.stopped:
                await ctx.send(f"❌ Lỗi khi tải bài hát: {str(e)}")
            return await self.play_next(ctx)

        self.current = (url, title)

        try:
            source = discord.PCMVolumeTransformer(
                discord.FFmpegPCMAudio(url, executable=FFMPEG_EXECUTABLE, **FFMPEG_OPTIONS)
            )
            ctx.voice_client.play(source, after=lambda e: self.client.loop.create_task(self.play_next(ctx)))
            await ctx.send(f'🎶 Đang phát: **{title}**')
        except Exception as e:
            logging.error(f"Lỗi khi phát audio: {e}", exc_info=True)
            if not self.stopped:
                await ctx.send("❌ Lỗi khi phát nhạc.")
            await self.play_next(ctx)


    @commands.command()
    async def skip(self, ctx):
        if ctx.voice_client and ctx.voice_client.is_playing():
            ctx.voice_client.stop()
            await ctx.send("⏭️ Đã bỏ qua bài hát hiện tại.")

    @commands.command()
    async def stop(self, ctx):
        if ctx.voice_client and ctx.voice_client.is_connected():
            self.stopped = True
            self.repeat = False
            await ctx.voice_client.disconnect()
            self.queue.clear()
            self.played_queue.clear()
            self.current = None
            await ctx.send("⏹️ Bot đã rời khỏi voice và dừng nhạc.")

    @commands.command(name="repeat")
    async def toggle_repeat(self, ctx):
        self.repeat = not self.repeat
        await ctx.send(f'🔁 Chế độ lặp đã {"bật ✅" if self.repeat else "tắt ❌"}.')

    @commands.command()
    async def queue(self, ctx):
        if self.queue:
            message = ""
            for i, item in enumerate(self.queue):
                if isinstance(item, tuple):
                    url, title = item
                    message += f"{i+1}. {title}\n"
                else:
                    message += f"{i+1}. {item} (đang chờ xử lý...)\n"
            await ctx.send(f"📜 Danh sách hàng chờ:\n{message}")
        else:
            await ctx.send("📭 Hàng chờ hiện đang trống.")

client = commands.Bot(command_prefix="!", intents=intents)

@client.event
async def on_ready():
    print(f"✅ Bot đã sẵn sàng với tên: {client.user}")

async def main():
    await client.add_cog(MusicBot(client))
    await client.start('MTI3MDc3NTc2Mzc4Nzk3MjYwOA.GOpS-r.DGc8gWsBcQfdLAOaUmIOb8ZfUVzRzSUPw4FANM')  # 👉 Thay bằng token bot thật của bạn

asyncio.run(main())

# MTI3MDc3NTc2Mzc4Nzk3MjYwOA.GOpS-r.DGc8gWsBcQfdLAOaUmIOb8ZfUVzRzSUPw4FANM
# 1224314688842629201