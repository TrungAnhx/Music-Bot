import discord
from discord.ext import commands
import wavelink
import yt_dlp
import asyncio
import logging
from collections import defaultdict, deque
from urllib.parse import parse_qs, urlencode, urlparse

from yt_dlp import utils as ytdl_utils

logging.basicConfig(level=logging.INFO)

intents = discord.Intents.default()
intents.message_content = True
intents.voice_states = True

ALLOWED_TEXT_CHANNEL_IDS = [1224314688842629201, 1225396300443418644]

YDL_OPTIONS = {
    'format': 'bestaudio/best',
    'quiet': True,
    'no_warnings': True,
    'noplaylist': False,
    'extract_flat': False,
    'force_client': 'android',
    'extractor_args': {'youtube': {'player_client': ['android']}},
}

HELP_MESSAGE = (
    "`!play <tên bài>` – phát hoặc thêm bài vào hàng chờ\n"
    "`!skip` – bỏ qua bài hiện tại\n"
    "`!stop` – dừng phát và rời voice\n"
    "`!queue` – xem hàng chờ\n"
    "`!pause` – tạm dừng phát nhạc\n"
    "`!resume` hoặc `!unpause` – tiếp tục phát nhạc\n"
    "`!repeat` – bật/tắt chế độ lặp\n"
    "`!previous` – phát lại bài trước\n"
)

class MusicBot(commands.Cog):
    def __init__(self, client):
        self.client = client
        self.queue = defaultdict(deque)
        self.repeat = defaultdict(bool)
        self.history = defaultdict(lambda: deque(maxlen=25))
        self.current = {}
        self.disconnect_tasks = {}
        self.ytdl_options = {**YDL_OPTIONS, 'default_search': 'ytsearch1'}
        self.text_channels = {}
        self.track_sources = {}

    def _cancel_disconnect(self, guild_id):
        task = self.disconnect_tasks.pop(guild_id, None)
        if task:
            task.cancel()

    def _cleanup_guild(self, guild_id: int, *, clear_queue: bool = True):
        if clear_queue:
            for track in list(self.queue[guild_id]):
                self.track_sources.pop(id(track), None)
            self.queue[guild_id].clear()
        self.history[guild_id].clear()
        current = self.current.pop(guild_id, None)
        if current:
            self.track_sources.pop(id(current), None)
        self.repeat[guild_id] = False
        self.text_channels.pop(guild_id, None)

    @staticmethod
    def _is_finished(reason) -> bool:
        if reason is None:
            return False

        name = getattr(reason, 'name', None)
        if name:
            return name.upper() == 'FINISHED'

        if isinstance(reason, str):
            return reason.upper() == 'FINISHED'

        return False

    async def _delayed_disconnect(self, player: wavelink.Player, guild_id: int):
        try:
            await asyncio.sleep(180)
            if player.connected and not player.playing:
                await player.disconnect()
                self._cleanup_guild(guild_id)
        except asyncio.CancelledError:
            pass
        finally:
            self.disconnect_tasks.pop(guild_id, None)

    async def _resolve_track(self, query: str):
        try:
            result = await wavelink.Playable.search(query)
        except Exception as exc:
            logging.warning(f"Primary search failed for '{query}': {exc}")
            return None

        track = None

        if hasattr(result, 'tracks'):
            tracks = result.tracks
            track = tracks[0] if tracks else None
        elif isinstance(result, (list, tuple)):
            track = result[0] if result else None
        else:
            track = result

        return track

    async def _fallback_track(self, query: str):
        try:
            info = await asyncio.to_thread(
                lambda: yt_dlp.YoutubeDL({**self.ytdl_options}).extract_info(query, download=False)
            )
        except Exception as exc:
            logging.error(f"Fallback extraction failed for '{query}': {exc}", exc_info=True)
            return None, None

        if not info:
            return None, None

        entries = info.get('entries')
        entry = entries[0] if entries else info

        if not entry:
            return None, None

        url = entry.get('url')
        title = entry.get('title', 'Unknown')
        uploader = entry.get('uploader') or entry.get('artist') or entry.get('channel')

        if url:
            normalized = self._normalize_youtube_url(url)
            track = await self._resolve_track(normalized)
            if track:
                return track, title

        search_terms = title
        if uploader:
            search_terms = f"{title} {uploader}"

        for prefix in ("ytmsearch:", "ytsearch:"):
            candidate = f"{prefix}{search_terms}"
            track = await self._resolve_track(candidate)
            if track:
                return track, title

        stream_url = entry.get('webpage_url') or url
        if stream_url:
            track = await self._resolve_track(stream_url)
            if track:
                return track, title

        return None, title

    @staticmethod
    def _normalize_youtube_url(search: str) -> str:
        try:
            parsed = ytdl_utils.url_or_none(search)
            if not parsed:
                return search

            url = ytdl_utils.sanitize_url(search)
            if 'youtube.com/watch' not in url and 'youtu.be/' not in url:
                return search

            parsed_url = urlparse(url)
            if not parsed_url.query:
                return url

            query = parse_qs(parsed_url.query)
            v = query.get('v', [None])[0]
            if not v:
                return url

            clean_query = {'v': v}
            if 't' in query:
                clean_query['t'] = query['t'][0]

            return f"https://www.youtube.com/watch?{urlencode(clean_query)}"
        except Exception:
            return search

    @commands.Cog.listener()
    async def on_wavelink_node_ready(self, payload: wavelink.NodeReadyEventPayload):
        logging.info(f"Lavalink node {payload.node.identifier} is ready!")

    @commands.Cog.listener()
    async def on_wavelink_track_end(self, payload: wavelink.TrackEndEventPayload):
        player = payload.player
        if not player:
            return

        guild_id = player.guild.id
        track = payload.track
        finished = self._is_finished(getattr(payload, 'reason', None))
        original_source = self.track_sources.get(id(track)) if track else None

        if track and finished:
            history = self.history[guild_id]
            if not history or history[0] != track:
                history.appendleft(track)

        self._cancel_disconnect(guild_id)
        if track:
            self.track_sources.pop(id(track), None)
            if track in self.queue[guild_id]:
                self.track_sources[id(track)] = original_source or getattr(track, 'info', {}).get('uri') or getattr(track, 'title', None)

        if self.repeat[guild_id] and finished and track:
            self.queue[guild_id].append(track)
            self.track_sources[id(track)] = original_source or getattr(track, 'info', {}).get('uri') or getattr(track, 'title', None)

        # Play next track in queue
        if self.queue[guild_id]:
            next_track = self.queue[guild_id].popleft()
            await player.play(next_track)
        else:
            task = asyncio.create_task(self._delayed_disconnect(player, guild_id))
            self.disconnect_tasks[guild_id] = task

    @commands.Cog.listener()
    async def on_wavelink_track_start(self, payload: wavelink.TrackStartEventPayload):
        player = payload.player
        if not player:
            return

        guild_id = player.guild.id
        previous = self.current.get(guild_id)

        if previous and previous != payload.track:
            history = self.history[guild_id]
            if not history or history[0] != previous:
                history.appendleft(previous)

        self.current[guild_id] = payload.track

    @commands.command()
    async def play(self, ctx, *, search: str):
        if ctx.channel.id not in ALLOWED_TEXT_CHANNEL_IDS:
            return await ctx.send("❌ Bot chỉ được dùng trong kênh văn bản cho phép.")

        if not ctx.author.voice:
            return await ctx.send("⚠️ Bạn cần vào voice channel trước.")

        # Connect to voice if not already
        if not ctx.voice_client:
            try:
                player: wavelink.Player = await ctx.author.voice.channel.connect(cls=wavelink.Player)
            except Exception as e:
                logging.error(f"Error connecting: {e}")
                return await ctx.send(f"❌ Không thể kết nối vào voice: {str(e)}")
        else:
            player: wavelink.Player = ctx.voice_client

        guild_id = ctx.guild.id
        self._cancel_disconnect(guild_id)
        self.text_channels[guild_id] = ctx.channel

        try:
            search = self._normalize_youtube_url(search)
            track = await self._resolve_track(search)
            title = getattr(track, 'title', None) if track else None

            if not track:
                track, title = await self._fallback_track(search)

            if not track:
                return await ctx.send(f"❌ Không thể tìm thấy bài: **{search}**")

            title = title or getattr(track, 'title', 'Unknown')

            if player.playing:
                self.queue[guild_id].append(track)
                self.track_sources[id(track)] = search
                return await ctx.send(f'✅ Đã thêm vào hàng chờ: **{title}**')

            self.track_sources[id(track)] = search
            await player.play(track)
            await ctx.send(f'🎶 Đang phát: **{title}**')

        except Exception as e:
            logging.error(f"Error in play command: {e}", exc_info=True)
            await ctx.send(f"❌ Lỗi khi phát nhạc: {str(e)}")

    @commands.command()
    async def skip(self, ctx):
        player: wavelink.Player = ctx.voice_client
        if player:
            self.text_channels[ctx.guild.id] = ctx.channel
        
        if not player or not player.playing:
            return await ctx.send("❌ Không có bài nào đang phát.")

        await player.skip()
        await ctx.send("⏭️ Đã bỏ qua bài hát hiện tại.")

    @commands.command()
    async def stop(self, ctx):
        player: wavelink.Player = ctx.voice_client
        if player:
            self.text_channels[ctx.guild.id] = ctx.channel
        
        if not player:
            return await ctx.send("❌ Bot không ở trong voice channel.")

        # Clear queue and disconnect
        guild_id = ctx.guild.id
        self._cleanup_guild(guild_id)
        self._cancel_disconnect(guild_id)
            
        await player.disconnect()
        await ctx.send("⏹️ Bot đã rời khỏi voice và dừng nhạc.")

    @commands.command(name="repeat")
    async def toggle_repeat(self, ctx):
        guild_id = ctx.guild.id
        self.text_channels[guild_id] = ctx.channel
        self.repeat[guild_id] = not self.repeat[guild_id]
        await ctx.send(f'🔁 Chế độ lặp đã {"bật ✅" if self.repeat[guild_id] else "tắt ❌"}.')

    @commands.command(name="previous")
    async def play_previous(self, ctx):
        guild_id = ctx.guild.id
        player: wavelink.Player = ctx.voice_client
        self.text_channels[guild_id] = ctx.channel

        if not player:
            return await ctx.send("❌ Bot không ở trong voice channel.")

        history = self.history[guild_id]

        if not history:
            return await ctx.send("ℹ️ Không có bài hát trước đó.")

        previous_track = history.popleft()
        current_track = self.current.get(guild_id)

        if current_track:
            self.queue[guild_id].appendleft(current_track)

        self._cancel_disconnect(guild_id)

        await player.play(previous_track)
        self.track_sources[id(previous_track)] = getattr(previous_track, 'info', {}).get('uri') or getattr(previous_track, 'title', None)
        title = getattr(previous_track, 'title', 'Unknown')
        await ctx.send(f'⏮️ Đang phát lại: **{title}**')

    @commands.command()
    async def queue(self, ctx):
        player: wavelink.Player = ctx.voice_client
        if player:
            self.text_channels[ctx.guild.id] = ctx.channel
        
        if not player:
            return await ctx.send("❌ Bot không ở trong voice channel.")

        queue = list(self.queue.get(ctx.guild.id, []))
        
        if not queue and not player.playing:
            return await ctx.send("📭 Hàng chờ hiện đang trống.")

        message = ""
        if player.playing:
            message += f"▶️ **Đang phát:** {player.current.title}\n\n"
        
        if queue:
            message += "**Hàng chờ:**\n"
            for i, track in enumerate(queue[:10]):
                title = getattr(track, 'title', 'Unknown')
                message += f"{i+1}. {title}\n"
            if len(queue) > 10:
                message += f"... và {len(queue) - 10} bài nữa"
        
        await ctx.send(message if message else "📭 Hàng chờ trống.")

    @commands.command()
    async def pause(self, ctx):
        player: wavelink.Player = ctx.voice_client
        if player:
            self.text_channels[ctx.guild.id] = ctx.channel
        
        if not player or not player.playing:
            return await ctx.send("❌ Không có bài nào đang phát.")

        if player.paused:
            return await ctx.send("ℹ️ Nhạc đã tạm dừng sẵn rồi.")

        await player.pause(True)
        await ctx.send("⏸️ Đã tạm dừng phát nhạc.")

    @commands.command(name="resume", aliases=["unpause"])
    async def resume(self, ctx):
        player: wavelink.Player = ctx.voice_client
        if player:
            self.text_channels[ctx.guild.id] = ctx.channel

        if not player:
            return await ctx.send("❌ Bot không ở trong voice channel.")

        if not player.paused:
            return await ctx.send("ℹ️ Nhạc đang phát rồi.")

        await player.pause(False)
        await ctx.send("▶️ Đã tiếp tục phát nhạc.")

    @commands.command(name="help")
    async def help_command(self, ctx):
        await ctx.send("📋 **Lệnh của bot:**\n" + HELP_MESSAGE)

    @commands.Cog.listener()
    async def on_wavelink_track_exception(self, payload: wavelink.TrackExceptionEventPayload):
        player = payload.player
        if not player:
            return

        guild_id = player.guild.id
        channel = self.text_channels.get(guild_id)
        track = payload.track
        error_text = str(getattr(payload, 'exception', '')).lower()

        original_search = self.track_sources.pop(id(track), None)
        fallback_query = original_search or getattr(track, 'info', {}).get('uri') or getattr(track, 'title', None)

        if 'please sign in' in error_text and fallback_query:
            fallback_track, title = await self._fallback_track(fallback_query)
            if fallback_track:
                self.track_sources[id(fallback_track)] = fallback_query
                await player.play(fallback_track)
                if channel:
                    await channel.send(f"🔁 Đã phát lại **{title or fallback_track.title}** bằng nguồn thay thế.")
                return

        if channel:
            await channel.send(f"⚠️ Không thể phát bài: {getattr(track, 'title', 'Unknown')} ({error_text or 'lỗi không xác định'}).")

        if self.queue[guild_id]:
            next_track = self.queue[guild_id].popleft()
            await player.play(next_track)
        else:
            self._cancel_disconnect(guild_id)


client = commands.Bot(command_prefix="!", intents=intents, case_insensitive=True, help_command=None)

@client.event
async def on_ready():
    print(f"✅ Bot đã sẵn sàng với tên: {client.user}")

async def setup_hook():
    # Kiểm tra môi trường để chọn Lavalink URI
    import os
    
    # Nếu là Replit hoặc môi trường cloud, sử dụng 0.0.0.0
    # Nếu là localhost, sử dụng 127.0.0.1
    lavalink_uri = os.environ.get("LAVALINK_URI", "http://127.0.0.1:2333")
    
    node = wavelink.Node(uri=lavalink_uri, password=os.environ.get("LAVALINK_PASSWORD", "youshallnotpass"))
    await wavelink.Pool.connect(nodes=[node], client=client, cache_capacity=100)
    await client.tree.sync()

client.setup_hook = setup_hook


@client.tree.command(name="musichelp", description="Xem hướng dẫn lệnh ! của MusicBot")
async def musichelp(interaction: discord.Interaction):
    await interaction.response.send_message(
        "📋 **Lệnh của bot:**\n" + HELP_MESSAGE,
        ephemeral=True,
    )

async def main():
    import os
    # Lấy token từ environment variables để bảo mật
    token = os.environ.get("DISCORD_TOKEN")
    if not token:
        raise ValueError("DISCORD_TOKEN không được tìm thấy trong environment variables!")
    
    await client.add_cog(MusicBot(client))
    await client.start(token)

asyncio.run(main())
