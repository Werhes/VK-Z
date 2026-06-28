using Microsoft.UI.Dispatching;
using NAudio.Wave;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using VKZ.Models;

namespace VKZ.Services
{
    /// <summary>
    /// Сервис воспроизведения аудио на основе NAudio MediaFoundationReader.
    /// Адаптирован для WinUI с DispatcherQueue.
    /// </summary>
    public class AudioPlayerService : IDisposable
    {
        private readonly SettingsService _settings;
        private readonly DispatcherQueue _dispatcherQueue;

        private MediaFoundationReader? _reader;
        private WaveOutEvent? _outputDevice;
        private List<VKTrack> _queue = new();
        private int _currentIndex = -1;
        private bool _isDisposed;

        // Текущее состояние
        public PlayerState State { get; private set; } = PlayerState.Stopped;
        public VKTrack? CurrentTrack { get; private set; }
        public double Position => _reader?.CurrentTime.TotalSeconds ?? 0;
        public double Duration => _reader?.TotalTime.TotalSeconds ?? 0;
        public float Volume { get; private set; } = 0.8f;
        public bool IsShuffled { get; set; }
        public PlayerRepeatMode RepeatMode { get; set; } = PlayerRepeatMode.None;
        public IReadOnlyList<VKTrack> Queue => _queue.AsReadOnly();
        public int CurrentIndex => _currentIndex;

        // События
        public event EventHandler<VKTrack?>? TrackChanged;
        public event EventHandler<PlayerState>? StateChanged;
        public event EventHandler<double>? PositionChanged;
        public event EventHandler? QueueChanged;

        public AudioPlayerService(SettingsService settings)
        {
            _settings = settings;
            _dispatcherQueue = DispatcherQueue.GetForCurrentThread();

            // Восстанавливаем настройки
            Volume = _settings.Volume;
            IsShuffled = _settings.IsShuffled;
            RepeatMode = (PlayerRepeatMode)_settings.RepeatMode;
        }

        /// <summary>
        /// Устанавливает очередь воспроизведения.
        /// </summary>
        public void SetQueue(List<VKTrack> tracks, int startIndex = 0)
        {
            _queue = new List<VKTrack>(tracks);
            _currentIndex = startIndex >= 0 && startIndex < _queue.Count ? startIndex : 0;
            QueueChanged?.Invoke(this, EventArgs.Empty);
        }

        /// <summary>
        /// Добавляет треки в очередь.
        /// </summary>
        public void AddToQueue(List<VKTrack> tracks)
        {
            _queue.AddRange(tracks);
            QueueChanged?.Invoke(this, EventArgs.Empty);
        }

        /// <summary>
        /// Очищает очередь.
        /// </summary>
        public void ClearQueue()
        {
            Stop();
            _queue.Clear();
            _currentIndex = -1;
            CurrentTrack = null;
            QueueChanged?.Invoke(this, EventArgs.Empty);
        }

        /// <summary>
        /// Начинает воспроизведение трека по индексу в очереди.
        /// </summary>
        public async Task Play(int index)
        {
            if (index < 0 || index >= _queue.Count)
                return;

            _currentIndex = index;
            await PlayCurrent();
        }

        /// <summary>
        /// Начинает воспроизведение конкретного трека (добавляет в очередь если нужно).
        /// </summary>
        public async Task PlayTrack(VKTrack track, List<VKTrack>? contextQueue = null)
        {
            if (contextQueue != null)
            {
                _queue = new List<VKTrack>(contextQueue);
                _currentIndex = _queue.FindIndex(t => t.Id == track.Id && t.OwnerId == track.OwnerId);
                if (_currentIndex < 0)
                {
                    _queue.Add(track);
                    _currentIndex = _queue.Count - 1;
                }
            }
            else
            {
                if (!_queue.Contains(track))
                {
                    _queue.Add(track);
                    _currentIndex = _queue.Count - 1;
                }
                else
                {
                    _currentIndex = _queue.IndexOf(track);
                }
            }

            QueueChanged?.Invoke(this, EventArgs.Empty);
            await PlayCurrent();
        }

        /// <summary>
        /// Переключает воспроизведение (пауза/продолжить).
        /// </summary>
        public void TogglePlayPause()
        {
            if (_outputDevice == null || _reader == null)
                return;

            switch (State)
            {
                case PlayerState.Playing:
                    _outputDevice.Pause();
                    SetState(PlayerState.Paused);
                    break;
                case PlayerState.Paused:
                    _outputDevice.Play();
                    SetState(PlayerState.Playing);
                    break;
            }
        }

        /// <summary>
        /// Останавливает воспроизведение.
        /// </summary>
        public void Stop()
        {
            CleanupPlayback();
            SetState(PlayerState.Stopped);
            CurrentTrack = null;
            TrackChanged?.Invoke(this, null);
        }

        /// <summary>
        /// Переключает на следующий трек.
        /// </summary>
        public async Task Next()
        {
            if (_queue.Count == 0)
                return;

            if (RepeatMode == PlayerRepeatMode.One)
            {
                // Повтор текущего трека — просто перезапускаем
                await PlayCurrent();
                return;
            }

            int nextIndex;
            if (IsShuffled)
            {
                var random = new Random();
                nextIndex = random.Next(0, _queue.Count);
            }
            else
            {
                nextIndex = _currentIndex + 1;
            }

            if (nextIndex >= _queue.Count)
            {
                if (RepeatMode == PlayerRepeatMode.All)
                {
                    nextIndex = 0;
                }
                else
                {
                    Stop();
                    return;
                }
            }

            await Play(nextIndex);
        }

        /// <summary>
        /// Переключает на предыдущий трек.
        /// </summary>
        public async Task Previous()
        {
            if (_queue.Count == 0)
                return;

            // Если прошло больше 3 секунд, перезапускаем текущий
            if (Position > 3)
            {
                await PlayCurrent();
                return;
            }

            int prevIndex = _currentIndex - 1;
            if (prevIndex < 0)
            {
                if (RepeatMode == PlayerRepeatMode.All)
                {
                    prevIndex = _queue.Count - 1;
                }
                else
                {
                    await Play(0);
                    return;
                }
            }

            await Play(prevIndex);
        }

        /// <summary>
        /// Устанавливает позицию воспроизведения.
        /// </summary>
        public void Seek(double seconds)
        {
            if (_reader == null)
                return;

            var time = TimeSpan.FromSeconds(Math.Clamp(seconds, 0, Duration));
            _reader.CurrentTime = time;
        }

        /// <summary>
        /// Устанавливает громкость.
        /// </summary>
        public void SetVolume(float volume)
        {
            Volume = Math.Clamp(volume, 0f, 1f);
            if (_outputDevice != null)
            {
                _outputDevice.Volume = Volume;
            }
            _settings.Volume = Volume;
        }

        /// <summary>
        /// Перемешивает очередь.
        /// </summary>
        public void Shuffle()
        {
            IsShuffled = !IsShuffled;
            _settings.IsShuffled = IsShuffled;
        }

        /// <summary>
        /// Переключает режим повтора.
        /// </summary>
        public void ToggleRepeatMode()
        {
            RepeatMode = (PlayerRepeatMode)(((int)RepeatMode + 1) % 3);
            _settings.RepeatMode = (int)RepeatMode;
        }

        private async Task PlayCurrent()
        {
            if (_currentIndex < 0 || _currentIndex >= _queue.Count)
                return;

            var track = _queue[_currentIndex];
            if (track.AudioUrl == null)
            {
                await Next();
                return;
            }

            CleanupPlayback();
            SetState(PlayerState.Loading);

            try
            {
                _reader = new MediaFoundationReader(track.AudioUrl.AbsoluteUri);
                _outputDevice = new WaveOutEvent();
                _outputDevice.Init(_reader);
                _outputDevice.Volume = Volume;
                _outputDevice.PlaybackStopped += OnPlaybackStopped;

                CurrentTrack = track;
                _outputDevice.Play();
                SetState(PlayerState.Playing);
                TrackChanged?.Invoke(this, track);

                // Запускаем обновление позиции
                StartPositionUpdates();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to play track: {ex.Message}");
                SetState(PlayerState.Stopped);
                await Next();
            }
        }

        private void OnPlaybackStopped(object? sender, StoppedEventArgs e)
        {
            _ = _dispatcherQueue.TryEnqueue(async () =>
            {
                if (e.Exception != null)
                {
                    System.Diagnostics.Debug.WriteLine($"Playback error: {e.Exception.Message}");
                }

                if (State == PlayerState.Playing || State == PlayerState.Paused)
                {
                    await Next();
                }
            });
        }

        private void CleanupPlayback()
        {
            if (_outputDevice != null)
            {
                _outputDevice.PlaybackStopped -= OnPlaybackStopped;
                _outputDevice.Stop();
                _outputDevice.Dispose();
                _outputDevice = null;
            }

            if (_reader != null)
            {
                _reader.Dispose();
                _reader = null;
            }
        }

        private void SetState(PlayerState state)
        {
            State = state;
            StateChanged?.Invoke(this, state);
        }

        private async void StartPositionUpdates()
        {
            while (State == PlayerState.Playing || State == PlayerState.Paused)
            {
                await Task.Delay(250);
                if (_reader != null)
                {
                    PositionChanged?.Invoke(this, _reader.CurrentTime.TotalSeconds);
                }
            }
        }

        public void Dispose()
        {
            if (_isDisposed)
                return;

            _isDisposed = true;
            CleanupPlayback();
        }
    }
}