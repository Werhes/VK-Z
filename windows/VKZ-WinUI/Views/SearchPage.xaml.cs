using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using VKZ.Models;
using VKZ.Services;

namespace VKZ.Views
{
    public sealed partial class SearchPage : Page
    {
        private readonly VKApiService _apiService;
        private readonly AudioPlayerService _playerService;
        private readonly ObservableCollection<VKTrack> _searchResults = new();
        private CancellationTokenSource? _searchCts;

        public SearchPage()
        {
            this.InitializeComponent();

            _apiService = App.GetService<VKApiService>();
            _playerService = App.GetService<AudioPlayerService>();

            SearchResultsListView.ItemsSource = _searchResults;
            SearchResultsListView.ItemClick += OnTrackClick;
            SearchResultsListView.IsItemClickEnabled = true;
        }

        private async void OnSearchTextChanged(object sender, TextChangedEventArgs e)
        {
            var query = SearchTextBox.Text?.Trim();
            if (string.IsNullOrEmpty(query) || query.Length < 2)
            {
                _searchResults.Clear();
                EmptyText.Text = "Начните поиск";
                EmptyText.Visibility = Visibility.Visible;
                return;
            }

            // Debounce: отменяем предыдущий поиск
            _searchCts?.Cancel();
            _searchCts = new CancellationTokenSource();
            var token = _searchCts.Token;

            try
            {
                await Task.Delay(300, token); // Debounce 300ms
                await PerformSearch(query, token);
            }
            catch (TaskCanceledException)
            {
                // Поиск был отменён новым вводом
            }
        }

        private void OnSearchKeyDown(object sender, KeyRoutedEventArgs e)
        {
            if (e.Key == Windows.System.VirtualKey.Enter)
            {
                var query = SearchTextBox.Text?.Trim();
                if (!string.IsNullOrEmpty(query))
                {
                    _searchCts?.Cancel();
                    _ = PerformSearch(query);
                }
            }
        }

        private async Task PerformSearch(string query, CancellationToken token = default)
        {
            SetLoading(true);
            EmptyText.Visibility = Visibility.Collapsed;

            try
            {
                var results = await _apiService.SearchAudio(query);
                token.ThrowIfCancellationRequested();

                _searchResults.Clear();
                foreach (var track in results)
                {
                    _searchResults.Add(track);
                }

                if (_searchResults.Count == 0)
                {
                    EmptyText.Text = "Ничего не найдено";
                    EmptyText.Visibility = Visibility.Visible;
                }
            }
            catch (OperationCanceledException) { }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Search failed: {ex.Message}");
                EmptyText.Text = "Ошибка поиска";
                EmptyText.Visibility = Visibility.Visible;
            }
            finally
            {
                SetLoading(false);
            }
        }

        private async void OnTrackClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is VKTrack track)
            {
                var tracks = _searchResults.ToList();
                _playerService.SetQueue(tracks, tracks.IndexOf(track));
                await _playerService.Play(tracks.IndexOf(track));
            }
        }

        private void OnContainerContentChanging(ListViewBase sender, ContainerContentChangingEventArgs args)
        {
            // Оптимизация рендеринга
        }

        private void SetLoading(bool isLoading)
        {
            LoadingRing.IsActive = isLoading;
            LoadingRing.Visibility = isLoading ? Visibility.Visible : Visibility.Collapsed;
        }
    }
}