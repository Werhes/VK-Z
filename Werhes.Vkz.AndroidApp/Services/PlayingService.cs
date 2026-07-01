using System;
using Android.App;
using Werhes.Vkz.AndroidApp.Models;
using MediaManager;
using MediaManager.Media;
using MediaManager.Playback;
using Android.Widget;

namespace Werhes.Vkz.AndroidApp.Services
{
    public class PlayingService
    {
        private readonly IMediaManager player;
        private AudioPlaylist currentPlaylist;
        private long currentPlaylistId = 0;
        private Track currentTrack;
        public event Delegates.EventHandler<TimeSpan> PositionChanged;
        public event Delegates.EventHandler<Track> CurrentAudioChanged;
        public event Delegates.EventHandler<Exception> ItemFailed; 

        public PlayingService()
        {
            player = CrossMediaManager.Current;
            player.PositionChanged += PlayerOnPositionChanged;
            player.MediaItemFailed += PlayerOnMediaItemFailed;
            player.MediaItemFinished += PlayerOnMediaItemFinished;
        }

        private void PlayerOnMediaItemFinished(object sender, MediaItemEventArgs e)
        {
            currentPlaylist.Next(true);
        }

        private void PlayerOnMediaItemFailed(object sender, MediaItemFailedEventArgs e)
        {
            var exception = e.Exeption;
            ItemFailed?.Invoke(this, exception);
        }

        private void PlayerOnPositionChanged(object sender, PositionChangedEventArgs e)
        {
            var position = e.Position;
            PositionChanged?.Invoke(this, position);
        }


        public bool IsPlay => player.IsPlaying();
        public TimeSpan Duration => player.Duration;
        
        public TimeSpan Position => player.Position;

        public void Play(Models.Album playlist = null, Track audio = null)
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
                    var audioPlaylist = new AudioPlaylist(playlist, audio, StaticContentService.RepeatPlaylist, StaticContentService.RepeatTrack);
                    currentPlaylist = audioPlaylist;
                    currentTrack = audio;
                    currentPlaylist.OnCurrentItemChanged += CurrentPlaylistOnOnCurrentItemChanged;
                    CurrentAudioChanged?.Invoke(this, audio);
                }
                else
                {
                    currentPlaylist.SetCurrentTrack(audio);
                    currentTrack = audio;
                    CurrentAudioChanged?.Invoke(this, audio);
                }
                //var playerNotificationManager = (CrossMediaManager.Android.NotificationManager as MediaManager.Platforms.Android.Notifications.NotificationManager).PlayerNotificationManager;
                

                TaskService.RunOnUI(async () =>
                {
                    Toast.MakeText(Application.Context, "[РћС‚Р»Р°РґРєР°] РќР°С‡РёРЅР°РµРј РІРѕСЃРїСЂРѕРёР·РІРѕРґРёС‚СЊ...", ToastLength.Long).Show();
                    Toast.MakeText(Application.Context, $"[РћС‚Р»Р°РґРєР°] URI: {currentTrack.Url}", ToastLength.Long).Show();
                    var media = await player.Play(currentTrack.Url);
                    media.Title = currentTrack.Title;
                    //media.AlbumArtUri = ""; //Р‘РµР· СЌС‚РѕРіРѕ С‚СЂРµРєРё СЃ Р±РёС‚С‹РјРё СЃСЃС‹Р»РєР°РјРё Р±СѓРґСѓС‚ РІС‹РєРёРґС‹РІР°С‚СЊ РїР»РµРµСЂ РІ С„Р°С‚Р°Р»
                    media.Artist = currentTrack.Artist;
                    media.AlbumArtist = currentTrack.Artist;
                    if (currentTrack.Album?.Cover != "placeholder") media.ImageUri = currentTrack.Album?.Cover;
                    CrossMediaManager.Android.Notification.UpdateNotification();
                });

                
                //player.MediaQueue.Current.Title = audio.Title;
                //player.MediaQueue.Current.Artist = audio.Title;
                //player.MediaQueue.Current.AlbumArtUri = audio.Cover;
                //CrossMediaManager.Android.
                //player.NotificationManager = null;
            }
        }

        private void CurrentPlaylistOnOnCurrentItemChanged(object sender, Track args)
        {
            currentTrack = args;
            CurrentAudioChanged?.Invoke(this, args);
            TaskService.RunOnUI(async () =>
            {
                //TODO: РµСЃР»Рё РЅРёС…СѓСЏ РЅРµ СЂР°Р±РѕС‚Р°РµС‚, СЂР°СЃРєРѕРјРјРµРЅС‚РёСЂРѕРІР°С‚СЊ Рё РїРµСЂРµРґР°С‚СЊ РІ Play;
                //var item = await CrossMediaManager.Current.Extractor.CreateMediaItem(currentTrack.Url.ToString());
                //item.MediaType = MediaType.Hls;

                var media = await player.Play(currentTrack.Url);
                media.MediaUri = currentTrack.Url.ToString();
                media.Title = currentTrack.Title;
                //media.AlbumArtUri = ""; //Р‘РµР· СЌС‚РѕРіРѕ С‚СЂРµРєРё СЃ Р±РёС‚С‹РјРё СЃСЃС‹Р»РєР°РјРё Р±СѓРґСѓС‚ РІС‹РєРёРґС‹РІР°С‚СЊ РїР»РµРµСЂ РІ С„Р°С‚Р°Р»
                media.Artist = currentTrack.Artist;
                media.AlbumArtist = currentTrack.Artist;
                media.ImageUri = null;
 
                if (currentTrack.Album?.Cover != "placeholder") media.ImageUri = currentTrack.Album?.Cover;
                
                CrossMediaManager.Android.Notification.UpdateNotification();
            });
            //Play(audio: args);
            CurrentAudioChanged?.Invoke(this, args);
            //throw new NotImplementedException();
        }


        public void Pause()
        {
            player.Pause();
        }

        public void SeekTo(TimeSpan time)
        {
            player.SeekTo(time);
        }

        public void SeekToStart()
        {
            player.SeekToStart();
        }

        public void NextTrack()
        {
            Pause();
            SeekToStart();
            
            currentPlaylist.Next(true);

        }

        public void BackTrack()
        {
            Pause();
            SeekToStart();
            currentPlaylist.Back();
        }
        
    }
}