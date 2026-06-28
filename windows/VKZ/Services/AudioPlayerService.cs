using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using NAudio.Wave;
using VKZ.Models;

namespace VKZ.Services
{
    public sealed class AudioPlayerService : IDisposable
    {
        private static readonly Lazy<AudioPlayerService> _instance = new(() => new AudioPlayerService());
        public static AudioPlayerService Instance => _instance.Value;

        private readonly HttpClient _httpClient;
        private IWavePlayer? _outputDevice;
        private WaveStream? _audioStream;
        private readonly List<VKTrack> _queue = new();
        private int _currentIndex = -1;
        private bool _isDisposed;

        public event Action<VKTrack?>? TrackChanged;
        public event Action<PlayerState>? StateChanged;
        public event Action<double>? ProgressChanged;
        public event Action<double>? DurationChanged;

        public PlayerState State { get; private set; } = PlayerState.Idle;
        public PlayerRepeatMode RepeatMode { get; set; } = PlayerRepeatMode.All;
        public bool IsShuffled { get; set; }
        public double Volume { get; set; } = 0.8;
        public VKTrack? CurrentTrack { get; private set; }
        public IReadOnlyList<VKTrack> Queue => _queue.AsReadOnly();
        public int CurrentIndex => _currentIndex;

        private AudioPlayerService()
        {
            _httpClient = new HttpClient();
        }

        public void PlayTrack(VKTrack track)
        {
            _queue.Clear();
            _queue.Add(track);
            _currentIndex = 0;
            PlayInternal(track);
        }

        public void PlayTrackList(List<VKTrack> tracks, int startIndex = 0)
        {
            _queue.Clear();
            _queue.AddRange(tracks);
            _currentIndex = startIndex;
            if (_queue.Count > 0)
                PlayInternal(_queue[_currentIndex]);
        }

        public void PlayPause()
        {
            if (_outputDevice == null || _audioStream == null) return;

            switch (State)
            {
                case PlayerState.Playing:
                    _outputDevice.Pause();
                    State = PlayerState.Paused;
                    StateChanged?.Invoke(State);
                    break;
                case PlayerState.Paused:
                    _outputDevice.Play();
                    State = PlayerState.Playing;
                    StateChanged?.Invoke(State);
                    break;
            }
        }

        public void Stop()
        {
            CleanupAudio();
            State = PlayerState.Idle;
            CurrentTrack = null;
            _currentIndex = -1;
            StateChanged?.Invoke(State);
            TrackChanged?.Invoke(null);
        }

        public void Next()
        {
            if (_queue.Count == 0) return;

            if (RepeatMode == PlayerRepeatMode.One && CurrentTrack != null)
            {
                PlayInternal(CurrentTrack);
                return;
            }

            int nextIndex = _currentIndex + 1;
            if (nextIndex >= _queue.Count)
            {
                if (RepeatMode == PlayerRepeatMode.All)
                    nextIndex = 0;
                else
                    return;
            }

            _currentIndex = nextIndex;
            PlayInternal(_queue[_currentIndex]);
        }

        public void Previous()
        {
            if (_queue.Count == 0) return;

            int prevIndex = _currentIndex - 1;
            if (prevIndex < 0)
            {
                if (RepeatMode == PlayerRepeatMode.All)
                    prevIndex = _queue.Count - 1;
                else
                    return;
            }

            _currentIndex = prevIndex;
            PlayInternal(_queue[_currentIndex]);
        }

        public void Seek(double position)
        {
            if (_audioStream != null)
            {
                _audioStream.CurrentTime = TimeSpan.FromSeconds(position);
            }
        }

        public void SetVolume(double volume)
        {
            Volume = Math.Clamp(volume, 0, 1);
            if (_outputDevice != null)
            {
                _outputDevice.Volume = (float)Volume;
            }
        }

        public void AddToQueue(VKTrack track)
        {
            _queue.Add(track);
        }

        public void RemoveFromQueue(int index)
        {
            if (index >= 0 && index < _queue.Count)
            {
                _queue.RemoveAt(index);
                if (index <= _currentIndex && _currentIndex > 0)
                    _currentIndex--;
            }
        }

        public void ClearQueue()
        {
            _queue.Clear();
            _currentIndex = -1;
        }

        private async void PlayInternal(VKTrack track)
        {
            try
            {
                State = PlayerState.Loading;
                StateChanged?.Invoke(State);
                CurrentTrack = track;
                TrackChanged?.Invoke(track);

                CleanupAudio();

                if (string.IsNullOrEmpty(track.Url))
                {
                    State = PlayerState.Idle;
                    StateChanged?.Invoke(State);
                    return;
                }

                var response = await _httpClient.GetAsync(track.Url);
                response.EnsureSuccessStatusCode();
                var stream = await response.Content.ReadAsStreamAsync();

                var tempFile = Path.GetTempFileName();
                using (var fileStream = File.Create(tempFile))
                {
                    await stream.CopyToAsync(fileStream);
                }

                // MediaFoundationReader supports MP3, OGG, WAV, etc.
                _audioStream = new MediaFoundationReader(tempFile);
                _outputDevice = new WaveOutEvent();
                _outputDevice.Init(_audioStream);
                _outputDevice.PlaybackStopped += OnPlaybackStopped;
                _outputDevice.Volume = (float)Volume;
                _outputDevice.Play();

                State = PlayerState.Playing;
                StateChanged?.Invoke(State);
                DurationChanged?.Invoke(_audioStream.TotalTime.TotalSeconds);

                // Start progress timer
                _ = TrackProgressAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Playback error: {ex.Message}");
                State = PlayerState.Idle;
                StateChanged?.Invoke(State);
            }
        }

        private async Task TrackProgressAsync()
        {
            while (State == PlayerState.Playing || State == PlayerState.Paused)
            {
                if (_audioStream != null)
                {
                    var position = _audioStream.CurrentTime.TotalSeconds;
                    ProgressChanged?.Invoke(position);
                }
                await Task.Delay(250);
            }
        }

        private void OnPlaybackStopped(object? sender, StoppedEventArgs e)
        {
            if (e.Exception != null)
            {
                System.Diagnostics.Debug.WriteLine($"Playback error: {e.Exception.Message}");
            }

            if (State == PlayerState.Playing)
            {
                Next();
            }
        }

        private void CleanupAudio()
        {
            if (_outputDevice != null)
            {
                _outputDevice.PlaybackStopped -= OnPlaybackStopped;
                _outputDevice.Stop();
                _outputDevice.Dispose();
                _outputDevice = null;
            }
            if (_audioStream != null)
            {
                _audioStream.Dispose();
                _audioStream = null;
            }
        }

        public void Dispose()
        {
            if (_isDisposed) return;
            _isDisposed = true;
            CleanupAudio();
            _httpClient.Dispose();
        }
    }
}