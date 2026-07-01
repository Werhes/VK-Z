using System;
using MediaManager;
using MediaManager.Playback;
using Werhes.Vkz.iOS.Delegates;
using Werhes.Vkz.iOS.Models;

namespace Werhes.Vkz.iOS.Services
{
    public class PlayingService
    {
        private readonly IMediaManager player;
        private AudioPlaylist currentPlaylist;
        private long currentPlaylistId;
        private Track currentTrack;

        public event EventHandler<Track> CurrentAudioChanged;
        public event EventHandler<TimeSpan> PositionChanged;
        public event EventHandler<Exception> ItemFailed;

        public PlayingService()
        {
            player = CrossMediaManager.Current;
            player.PositionChanged += (s, e) => PositionChanged?.Invoke(this, e.Position);
            player.MediaItemFailed += (s, e) => ItemFailed?.Invoke(this, e.Exeption);
            player.MediaItemFinished += (s, e) => currentPlaylist?.Next(true);
        }

        public bool IsPlaying => player.IsPlaying();
        public TimeSpan Duration => player.Duration;
        public TimeSpan Position => player.Position;

        public void Play(Album playlist = null, Track audio = null)
        {
            if (playlist == null)
            {
                if (currentPlaylist == null && currentTrack == null) return;
                player.Play();
            }
            else
            {
                if (playlist.Id != currentPlaylistId)
                {
                    var audioPlaylist = new AudioPlaylist(playlist, audio,
                        StaticContentService.RepeatPlaylist, StaticContentService.RepeatTrack);
                    currentPlaylist = audioPlaylist;
                    currentTrack = audio;
                    currentPlaylist.OnCurrentItemChanged += (s, args) =>
                    {
                        currentTrack = args;
                        CurrentAudioChanged?.Invoke(this, args);
                        PlayTrack(args);
                    };
                    CurrentAudioChanged?.Invoke(this, audio);
                }
                else
                {
                    currentPlaylist.SetCurrentTrack(audio);
                    currentTrack = audio;
                    CurrentAudioChanged?.Invoke(this, audio);
                }

                PlayTrack(audio);
            }
        }

        private async void PlayTrack(Track track)
        {
            try
            {
                var media = await player.Play(track.Url);
                media.Title = track.Title;
                media.Artist = track.Artist;
                media.AlbumArtist = track.Artist;
                if (track.Album?.Cover != "placeholder")
                    media.ImageUri = track.Album?.Cover;
            }
            catch (Exception ex)
            {
                ItemFailed?.Invoke(this, ex);
            }
        }

        public void Pause() => player.Pause();

        public void SeekTo(TimeSpan time) => player.SeekTo(time);

        public void SeekToStart() => player.SeekToStart();

        public void NextTrack()
        {
            Pause();
            SeekToStart();
            currentPlaylist?.Next(true);
        }

        public void BackTrack()
        {
            Pause();
            SeekToStart();
            currentPlaylist?.Back();
        }
    }
}