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

# Đường dẫn tới ffmpeg nếu không có trong PATH
FFMPEG_EXECUTABLE = "ffmpeg-2024-08-04-git-eb3cc508d8-essentials_build/bin/ffmpeg.exe"
FFMPEG_OPTIONS = {
    'before_options': '-reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 5',
    'options': '-vn'
}
YDL_OPTIONS = {'format': 'bestaudio', 'noplaylist': True}

# Kênh văn bản được phép sử dụng bot
ALLOWED_TEXT_CHANNEL_IDS = [1224314688842629201, 1225396300443418644]


class MusicBot(commands.Cog):
    def __init__(self, client):
        self.client = client
        self.queue = []  # Mỗi phần tử: (search_term, title hoặc None)
        self.current = None
        self.repeat = False

    @commands.command()
    async def play(self, ctx, *, search):
        if ctx.channel.id not in ALLOWED_TEXT_CHANNEL_IDS:
            return await ctx.send("Bot này chỉ được sử dụng trong các kênh văn bản được chỉ định.")

        voice_channel = ctx.author.voice.channel if ctx.author.voice else None
        if not voice_channel:
            return await ctx.send("Bạn đang không ở trong voice!")

        if not ctx.voice_client:
            try:
                await voice_channel.connect()
            except Exception as e:
                logging.error(f"Error connecting to voice channel: {e}")
                return await ctx.send(f"Không thể kết nối vào voice channel: {str(e)}")

        # Chỉ lưu từ khóa vào hàng chờ, chưa tải
        async with ctx.typing():
            self.queue.append((search, None))
            await ctx.send(f'✅ Đã thêm từ khóa bài hát: **{search}** vào hàng chờ.')

        if not ctx.voice_client.is_playing():
            await self.play_next(ctx)

    async def play_next(self, ctx):
        if self.repeat and self.current:
            self.queue.insert(0, self.current)

        if not self.queue:
            self.current = None
            await ctx.send("📭 Hàng chờ trống. Thêm nhạc mới?")

            # Chờ 3 phút
            await asyncio.sleep(180)

            # Nếu sau 3 phút vẫn không có nhạc mới
            if not self.queue and not ctx.voice_client.is_playing():
                await ctx.send("👋 Không có nhạc trong 3 phút. Bot sẽ rời khỏi voice.")
                await ctx.voice_client.disconnect()
            return

        search, title = self.queue.pop(0)

        # Nếu chưa có URL, tìm bài hát
        try:
            with yt_dlp.YoutubeDL(YDL_OPTIONS) as ydl:
                info = ydl.extract_info(f"ytsearch:{search}", download=False)
                if 'entries' in info:
                    entry = info['entries'][0]
                    url = entry['url']
                    title = entry['title']
                else:
                    await ctx.send("❌ Không tìm thấy bài hát để phát.")
                    return await self.play_next(ctx)
        except Exception as e:
            logging.error(f"Error extracting info during playback: {e}")
            await ctx.send("❌ Lỗi khi tải bài hát.")
            return await self.play_next(ctx)

        self.current = (search, title)

        try:
            source = discord.PCMVolumeTransformer(
                discord.FFmpegPCMAudio(url, executable=FFMPEG_EXECUTABLE, **FFMPEG_OPTIONS))
            ctx.voice_client.play(source, after=lambda e: self.client.loop.create_task(self.play_next(ctx)))
            await ctx.send(f'🎶 Đang phát: **{title}**')
        except Exception as e:
            logging.error(f"Error playing audio: {e}")
            await ctx.send("❌ Lỗi khi phát nhạc.")
            await self.play_next(ctx)

        else:
            self.current = None
            await ctx.send("📭 Hàng chờ trống. Sẽ rời khỏi voice sau 3 phút nếu không có bài mới...")

            # ⏱️ Chờ 3 phút
            await asyncio.sleep(180)

            # Nếu sau 3 phút vẫn không có nhạc mới
            if not self.queue and not ctx.voice_client.is_playing():
                await ctx.send("👋 Không có nhạc trong 3 phút. Bot sẽ rời khỏi voice.")
                await ctx.voice_client.disconnect()

    @commands.command()
    async def skip(self, ctx):
        if ctx.voice_client and ctx.voice_client.is_playing():
            ctx.voice_client.stop()
            await ctx.send("⏭️ Đã bỏ qua bài hát.")

    @commands.command()
    async def stop(self, ctx):
        if ctx.voice_client and ctx.voice_client.is_connected():
            await ctx.voice_client.disconnect()
            self.queue.clear()
            self.current = None
            await ctx.send("⏹️ Đã dừng phát nhạc và rời khỏi voice.")

    @commands.command(name="repeat")
    async def toggle_repeat(self, ctx):
        self.repeat = not self.repeat
        await ctx.send(f'🔁 Chế độ phát lại đã {"bật ✅" if self.repeat else "tắt ❌"}.')

    @commands.command()
    async def queue(self, ctx):
        if self.queue:
            message = "\n".join([f"{i+1}. {title if title else search}" for i, (search, title) in enumerate(self.queue)])
            await ctx.send(f"📜 Danh sách hàng chờ:\n{message}")
        else:
            await ctx.send("📭 Hàng chờ hiện đang trống.")


client = commands.Bot(command_prefix="!", intents=intents)


@client.event
async def on_ready():
    print(f"✅ Bot đã sẵn sàng với tên: {client.user}")


async def main():
    await client.add_cog(MusicBot(client))
    await client.start('MTI3MDc3NTc2Mzc4Nzk3MjYwOA.GOpS-r.DGc8gWsBcQfdLAOaUmIOb8ZfUVzRzSUPw4FANM')


asyncio.run(main())


# MTI3MDc3NTc2Mzc4Nzk3MjYwOA.GOpS-r.DGc8gWsBcQfdLAOaUmIOb8ZfUVzRzSUPw4FANM
# 1224314688842629201