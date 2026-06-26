"""
VK API Client — чистый, без костылей.
Использует прямые HTTP-запросы к VK API v5.131.
Авторизация через Kate Mobile (bypass audio).

Запуск теста:
    pip install aiohttp
    python vk_client.py

Импорт в другом скрипте:
    from vk_client import VkClient
    client = VkClient()
    user = await client.auth_by_token("vk1.a...")
    tracks = await client.get_audio()
"""

import asyncio
import hashlib
import json
import re
from dataclasses import dataclass, field
from typing import Optional
from urllib.parse import urlencode


# ──────────────────────────────────────────────────────────────
# Модели данных
# ──────────────────────────────────────────────────────────────

@dataclass
class VkTrack:
    id: int
    owner_id: int
    artist: str
    title: str
    duration: int          # секунды
    url: str               # прямая mp3-ссылка (может быть пустой)
    thumb_url: str = ""    # обложка (маленькая, для списков)
    thumb_url_big: str = ""  # обложка (большая, для плеера/мини-бара)
    album_id: int = 0
    is_explicit: bool = False
    genre_id: int = 0
    access_key: str = ""   # нужен для add/delete/reorder некоторых треков

    @property
    def full_id(self) -> str:
        return f"{self.owner_id}_{self.id}"

    @property
    def full_id_with_key(self) -> str:
        if self.access_key:
            return f"{self.owner_id}_{self.id}_{self.access_key}"
        return self.full_id

    @property
    def duration_str(self) -> str:
        m, s = divmod(self.duration, 60)
        return f"{m}:{s:02d}"

    @classmethod
    def from_dict(cls, d: dict) -> "VkTrack":
        album = d.get("album", {})
        thumb_small = ""
        thumb_big = ""
        if album:
            thumbs = album.get("thumb", {}).get("photo", [])
            if thumbs:
                sorted_thumbs = sorted(thumbs, key=lambda x: x.get("width", 0))
                thumb_small = sorted_thumbs[0].get("url", "")
                thumb_big = sorted_thumbs[-1].get("url", "")
        return cls(
            id=d["id"],
            owner_id=d["owner_id"],
            artist=d.get("artist", "Unknown"),
            title=d.get("title", "Unknown"),
            duration=d.get("duration", 0),
            url=d.get("url", ""),
            thumb_url=thumb_small or thumb_big,
            thumb_url_big=thumb_big or thumb_small,
            album_id=album.get("id", 0),
            is_explicit=bool(d.get("is_explicit", False)),
            genre_id=d.get("genre_id", 0),
            access_key=d.get("access_key", ""),
        )


@dataclass
class VkPlaylist:
    id: int
    owner_id: int
    title: str
    count: int
    thumb_url: str = ""
    description: str = ""
    access_key: str = ""
    is_mix: bool = False     # VK Mix (бесконечная подборка по жанрам/контексту)
    plays: int = 0

    @property
    def full_id_with_key(self) -> str:
        if self.access_key:
            return f"{self.owner_id}_{self.id}_{self.access_key}"
        return f"{self.owner_id}_{self.id}"

    @classmethod
    def from_dict(cls, d: dict) -> "VkPlaylist":
        thumb = ""
        for ph in d.get("photo", {}).get("photo", []):
            thumb = ph.get("url", thumb)
        return cls(
            id=d["id"],
            owner_id=d["owner_id"],
            title=d.get("title", "Без названия"),
            count=d.get("count", 0),
            thumb_url=thumb,
            description=d.get("description", ""),
            access_key=d.get("access_key", ""),
            is_mix=bool(d.get("type") == 2 or d.get("is_following") and d.get("original_owner_id", 0) < 0 and d.get("title", "").lower().startswith("mix")),
            plays=d.get("plays", 0),
        )


@dataclass
class VkUser:
    id: int
    first_name: str
    last_name: str
    photo_url: str = ""
    token: str = ""

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"


# ──────────────────────────────────────────────────────────────
# Авторизация (Kate Mobile bypass — открытый метод)
# ──────────────────────────────────────────────────────────────

KATE_CLIENT_ID = "2685278"
KATE_CLIENT_SECRET = "lxhD8OD7dMsqtXIm5IUY"
VK_API_VERSION = "5.131"

AUTH_URL = "https://oauth.vk.ru/token"
API_URL = "https://api.vk.ru/method/"


def _kate_sig(params: dict, secret: str) -> str:
    """HMAC-подпись для Kate Mobile."""
    sorted_params = "&".join(f"{k}={v}" for k, v in sorted(params.items()))
    return hashlib.md5(f"{sorted_params}{secret}".encode()).hexdigest()


# ──────────────────────────────────────────────────────────────
# Главный клиент
# ──────────────────────────────────────────────────────────────

class VkClient:
    """
    Чистый асинхронный клиент к VK API.
    Одна сессия, один токен, никаких глобальных состояний.
    """

    def __init__(self):
        self._token: Optional[str] = None
        self._user_id: Optional[int] = None
        self._session: Optional[aiohttp.ClientSession] = None
        self._semaphore: Optional[asyncio.Semaphore] = None
        self._bound_loop: Optional[asyncio.AbstractEventLoop] = None

    def _ensure_loop_bound(self):
        """
        Каждый AsyncWorker создаёт свой event loop. aiohttp.ClientSession
        и asyncio.Semaphore привязываются к loop, в котором были созданы —
        использование их из другого loop даёт 'Event loop is closed'.
        Поэтому при смене loop пересоздаём оба объекта.
        """
        current_loop = asyncio.get_event_loop()
        if self._bound_loop is not current_loop:
            self._session = None
            self._semaphore = asyncio.Semaphore(3)
            self._bound_loop = current_loop

    async def _get_session(self) -> aiohttp.ClientSession:
        self._ensure_loop_bound()
        if self._session is None or self._session.closed:
            headers = {
                "User-Agent": "KateMobileAndroid/56 lite-460 (Android 4.4.2; SDK 19; x86; unknown Android SDK built for x86; en)",
                "Accept-Language": "ru",
            }
            self._session = aiohttp.ClientSession(headers=headers)
        return self._session

    async def close(self):
        if self._session and not self._session.closed:
            await self._session.close()
            self._session = None

    # ── Auth ────────────────────────────────────────────────

    async def auth_by_token(self, token: str) -> VkUser:
        """Войти по готовому токену."""
        self._token = token
        user = await self._get_current_user()
        self._user_id = user.id
        user.token = token
        return user

    async def auth_by_password(self, login: str, password: str) -> VkUser:
        """
        Авторизация через Kate Mobile (login + password).
        Возвращает VkUser с заполненным .token.
        ВНИМАНИЕ: работает только при отсутствии 2FA.
        При наличии 2FA — вызовет VkAuthError с redirect_uri.
        """
        session = await self._get_session()
        params = {
            "grant_type": "password",
            "client_id": KATE_CLIENT_ID,
            "client_secret": KATE_CLIENT_SECRET,
            "username": login,
            "password": password,
            "scope": "audio,offline",
            "v": VK_API_VERSION,
            "2fa_supported": "1",
            "lang": "ru",
        }
        async with self._semaphore:
            async with session.post(AUTH_URL, data=params) as r:
                data = await r.json(content_type=None)

        if "access_token" in data:
            self._token = data["access_token"]
            user = await self._get_current_user()
            self._user_id = user.id
            user.token = self._token
            return user
        elif "redirect_uri" in data:
            raise VkAuthError("2FA required", redirect_uri=data.get("redirect_uri"))
        else:
            err = data.get("error_description", data.get("error", "Unknown error"))
            raise VkAuthError(err)

    async def confirm_2fa(self, redirect_uri: str, code: str) -> VkUser:
        """Подтверждение 2FA кода."""
        session = await self._get_session()
        # Достаём sid из redirect_uri
        sid_match = re.search(r"sid=([^&]+)", redirect_uri)
        if not sid_match:
            raise VkAuthError("Cannot extract sid from redirect_uri")
        sid = sid_match.group(1)

        params = {
            "grant_type": "password",
            "client_id": KATE_CLIENT_ID,
            "client_secret": KATE_CLIENT_SECRET,
            "scope": "audio,offline",
            "v": VK_API_VERSION,
            "2fa_supported": "1",
            "sid": sid,
            "code": code.strip(),
            "lang": "ru",
        }
        async with self._semaphore:
            async with session.post(AUTH_URL, data=params) as r:
                data = await r.json(content_type=None)

        if "access_token" not in data:
            raise VkAuthError(data.get("error_description", "2FA failed"))

        self._token = data["access_token"]
        user = await self._get_current_user()
        self._user_id = user.id
        user.token = self._token
        return user

    # ── Внутренние запросы ──────────────────────────────────

    async def _call(self, method: str, **params) -> dict:
        """Единая точка вызова API."""
        if not self._token:
            raise VkApiError("Not authorized")

        session = await self._get_session()
        params.update({
            "access_token": self._token,
            "v": VK_API_VERSION,
            "lang": "ru",
        })

        async with self._semaphore:
            async with session.get(f"{API_URL}{method}", params=params) as r:
                data = await r.json(content_type=None)

        if "error" in data:
            err = data["error"]
            raise VkApiError(f"[{err.get('error_code')}] {err.get('error_msg')}")

        return data.get("response", data)

    async def _get_current_user(self) -> VkUser:
        data = await self._call("users.get", fields="photo_100")
        u = data[0]
        return VkUser(
            id=u["id"],
            first_name=u.get("first_name", ""),
            last_name=u.get("last_name", ""),
            photo_url=u.get("photo_100", ""),
        )

    # ── Audio API ───────────────────────────────────────────

    async def get_audio(self, owner_id: Optional[int] = None, offset: int = 0, count: int = 100) -> list[VkTrack]:
        """Получить аудиозаписи пользователя/группы."""
        owner_id = owner_id or self._user_id
        data = await self._call(
            "audio.get",
            owner_id=owner_id,
            offset=offset,
            count=count,
        )
        return [VkTrack.from_dict(a) for a in data.get("items", [])]

    async def get_audio_all(self, owner_id: Optional[int] = None) -> list[VkTrack]:
        """Получить ВСЕ аудиозаписи (постраничная загрузка)."""
        owner_id = owner_id or self._user_id
        first = await self._call("audio.get", owner_id=owner_id, count=1)
        total = first.get("count", 0)
        if total == 0:
            return []

        tasks = [
            self._call("audio.get", owner_id=owner_id, offset=off, count=100)
            for off in range(0, total, 100)
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        tracks = []
        for r in results:
            if isinstance(r, dict):
                tracks.extend(VkTrack.from_dict(a) for a in r.get("items", []))
        return tracks

    async def search(self, query: str, count: int = 50, offset: int = 0) -> list[VkTrack]:
        """Поиск аудио."""
        data = await self._call(
            "audio.search",
            q=query,
            count=count,
            offset=offset,
            auto_complete=1,
            sort=2,  # по популярности
        )
        return [VkTrack.from_dict(a) for a in data.get("items", [])]

    async def get_playlists(self, owner_id: Optional[int] = None) -> list[VkPlaylist]:
        """Получить плейлисты пользователя (включая подборки VK Mix, если есть)."""
        owner_id = owner_id or self._user_id
        data = await self._call("audio.getPlaylists", owner_id=owner_id, count=200)
        return [VkPlaylist.from_dict(p) for p in data.get("items", [])]

    async def get_playlist_tracks(self, playlist_id: int, owner_id: int, access_key: str = "") -> list[VkTrack]:
        """Треки конкретного плейлиста."""
        params = dict(owner_id=owner_id, playlist_id=playlist_id, count=2000)
        if access_key:
            params["access_key"] = access_key
        data = await self._call("audio.get", **params)
        return [VkTrack.from_dict(a) for a in data.get("items", [])]

    async def get_recommendations(self, target_audio: Optional[str] = None, count: int = 50) -> list[VkTrack]:
        """
        Рекомендации VK — основа для генерации плейлиста.
        target_audio — 'owner_id_audio_id' для рекомендаций по конкретному треку.
        """
        params: dict = {"count": count, "shuffle": 1}
        if target_audio:
            params["target_audio"] = target_audio
        else:
            params["user_id"] = self._user_id
        data = await self._call("audio.getRecommendations", **params)
        return [VkTrack.from_dict(a) for a in data.get("items", [])]

    async def get_vk_mixes(self) -> list[VkPlaylist]:
        """
        VK Mix — динамические подборки (Bach Mix / контекстные миксы).
        В VK API это catalog-блоки, доступные через catalog.getAudio.
        Возвращает список "виртуальных" плейлистов с type=2 (mix).
        """
        try:
            data = await self._call("catalog.getAudio", need_blocks=1)
        except VkApiError:
            return []

        mixes: list[VkPlaylist] = []
        for block in data.get("catalog", {}).get("blocks", []):
            if block.get("layout", {}).get("name") not in ("mix", "vertical_mixes"):
                continue
            for pl_id in block.get("playlists_ids", []):
                pl_data = next(
                    (p for p in data.get("playlists", []) if f"{p['owner_id']}_{p['id']}" == pl_id),
                    None,
                )
                if pl_data:
                    pl = VkPlaylist.from_dict(pl_data)
                    pl.is_mix = True
                    mixes.append(pl)
        return mixes

    async def play_mix(self, mix: VkPlaylist, count: int = 50) -> list[VkTrack]:
        """
        Получить треки для VK Mix. Миксы — "бесконечные", поэтому
        запрашиваем стартовый набор через audio.getStreamMixAudios,
        либо как fallback — обычные треки плейлиста.
        """
        try:
            data = await self._call(
                "audio.getStreamMixAudios",
                count=count,
                mix_id=f"{mix.owner_id}_{mix.id}",
            )
            tracks = [VkTrack.from_dict(a) for a in data.get("items", data if isinstance(data, list) else [])]
            if tracks:
                return tracks
        except VkApiError:
            pass
        return await self.get_playlist_tracks(mix.id, mix.owner_id, mix.access_key)

    async def add_audio(self, audio_id: int, owner_id: int) -> int:
        """Добавить трек в библиотеку."""
        return await self._call("audio.add", audio_id=audio_id, owner_id=owner_id)

    async def delete_audio(self, audio_id: int, owner_id: int) -> bool:
        """Удалить трек из библиотеки."""
        result = await self._call("audio.delete", audio_id=audio_id, owner_id=owner_id)
        return bool(result)

    # ── Редактирование плейлистов ────────────────────────────

    async def create_playlist(self, title: str, description: str = "") -> VkPlaylist:
        """Создать новый плейлист в своей библиотеке."""
        data = await self._call(
            "audio.createPlaylist",
            owner_id=self._user_id,
            title=title,
            description=description,
        )
        return VkPlaylist.from_dict(data)

    async def edit_playlist(self, playlist_id: int, title: str, description: str = "") -> bool:
        """Переименовать / изменить описание плейлиста."""
        result = await self._call(
            "audio.editPlaylist",
            owner_id=self._user_id,
            playlist_id=playlist_id,
            title=title,
            description=description,
        )
        return bool(result)

    async def delete_playlist(self, playlist_id: int, owner_id: Optional[int] = None) -> bool:
        owner_id = owner_id or self._user_id
        result = await self._call("audio.deletePlaylist", owner_id=owner_id, playlist_id=playlist_id)
        return bool(result)

    async def add_to_playlist(self, playlist_id: int, tracks: list[VkTrack], owner_id: Optional[int] = None) -> bool:
        """Добавить треки в плейлист (audio_ids в формате owner_id_id[_access_key])."""
        owner_id = owner_id or self._user_id
        audio_ids = ",".join(t.full_id_with_key for t in tracks)
        result = await self._call(
            "audio.addToPlaylist",
            owner_id=owner_id,
            playlist_id=playlist_id,
            audio_ids=audio_ids,
        )
        return bool(result)

    async def remove_from_playlist(self, playlist_id: int, tracks: list[VkTrack], owner_id: Optional[int] = None) -> bool:
        """
        Удалить треки из плейлиста.
        VK API принимает по одному audio_id за вызов в audio.removeFromPlaylist
        (в новых версиях — list), поэтому идём параллельно с ограничением семафора.
        """
        owner_id = owner_id or self._user_id
        tasks = [
            self._call(
                "audio.removeFromPlaylist",
                owner_id=owner_id,
                playlist_id=playlist_id,
                audio_ids=t.full_id_with_key,
            )
            for t in tracks
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return all(not isinstance(r, Exception) for r in results)

    async def reorder_playlist_track(self, playlist_id: int, track: VkTrack,
                                       after_track: Optional[VkTrack] = None,
                                       owner_id: Optional[int] = None) -> bool:
        """Переместить трек в плейлисте (после after_track, либо в начало)."""
        owner_id = owner_id or self._user_id
        params = dict(
            owner_id=owner_id,
            playlist_id=playlist_id,
            audio_id=track.id,
            audio_owner_id=track.owner_id,
        )
        if after_track:
            params["after_audio_id"] = after_track.id
            params["after_audio_owner_id"] = after_track.owner_id
        result = await self._call("audio.reorder", **params)
        return bool(result)

    # ── Генерация плейлистов ──────────────────────────────────

    async def generate_playlist(self, seed_tracks: list[VkTrack], count: int = 30) -> list[VkTrack]:
        """
        Генерация плейлиста на основе нескольких seed-треков (например,
        случайной выборки из библиотеки). Собирает рекомендации по каждому
        seed, дедублицирует, перемешивает.
        """
        import random
        if not seed_tracks:
            return await self.get_recommendations(count=count)

        sample = random.sample(seed_tracks, min(5, len(seed_tracks)))
        tasks = [
            self.get_recommendations(target_audio=t.full_id, count=count // len(sample) + 5)
            for t in sample
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        seen: set[str] = {t.full_id for t in seed_tracks}
        playlist: list[VkTrack] = []
        for r in results:
            if isinstance(r, list):
                for track in r:
                    if track.full_id not in seen and track.url:
                        seen.add(track.full_id)
                        playlist.append(track)

        random.shuffle(playlist)
        return playlist[:count]

    async def generate_from_playlist(self, playlist: VkPlaylist, count: int = 30) -> list[VkTrack]:
        """
        Генерация нового плейлиста на основе треков существующего плейлиста.
        Берёт треки плейлиста как seed-набор для generate_playlist —
        результат похож по духу, но не повторяет исходный плейлист.
        """
        seeds = await self.get_playlist_tracks(playlist.id, playlist.owner_id, playlist.access_key)
        if not seeds:
            return await self.get_recommendations(count=count)
        return await self.generate_playlist(seeds, count=count)


# ──────────────────────────────────────────────────────────────
# Исключения
# ──────────────────────────────────────────────────────────────

class VkApiError(Exception):
    pass


class VkAuthError(VkApiError):
    def __init__(self, message: str, redirect_uri: str = ""):
        super().__init__(message)
        self.redirect_uri = redirect_uri


# ──────────────────────────────────────────────────────────────
# Пример использования (при запуске файла напрямую)
# ──────────────────────────────────────────────────────────────

async def main():
    import sys

    if len(sys.argv) < 2:
        print("Usage: python vk_client.py <token>")
        print("       python vk_client.py <login> <password>")
        return

    client = VkClient()

    if len(sys.argv) == 2:
        # По токену
        token = sys.argv[1]
        user = await client.auth_by_token(token)
        print(f"✓ Authorized as {user.full_name} (id={user.id})")
    else:
        # По логину/паролю
        login, password = sys.argv[1], sys.argv[2]
        try:
            user = await client.auth_by_password(login, password)
            print(f"✓ Authorized as {user.full_name} (id={user.id})")
            print(f"  Token: {user.token}")
        except VkAuthError as e:
            if e.redirect_uri:
                print(f"2FA required! redirect_uri: {e.redirect_uri}")
                code = input("Enter 2FA code: ")
                user = await client.confirm_2fa(e.redirect_uri, code)
                print(f"✓ Authorized as {user.full_name} (id={user.id})")
                print(f"  Token: {user.token}")
            else:
                print(f"✗ Auth error: {e}")
                return

    # Тест: получаем треки
    tracks = await client.get_audio(count=5)
    print(f"\nLast 5 tracks:")
    for t in tracks:
        print(f"  {t.artist} — {t.title} ({t.duration_str})")

    # Тест: получаем плейлисты
    playlists = await client.get_playlists()
    print(f"\nPlaylists ({len(playlists)}):")
    for p in playlists[:5]:
        print(f"  {p.title} — {p.count} tracks")

    # Тест: рекомендации
    recs = await client.get_recommendations(count=5)
    print(f"\nRecommendations (5):")
    for t in recs:
        print(f"  {t.artist} — {t.title}")

    await client.close()


if __name__ == "__main__":
    asyncio.run(main())