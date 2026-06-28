using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using VKZ.Models;
using VKZ.Services;

namespace VKZ.Views
{
    public sealed partial class MixPage : Page
    {
        private readonly VKApiService _apiService;
        private readonly AudioPlayerService _playerService;
        private readonly ObservableCollection<VKMix> _mixes = new();

        public MixPage()
        {
            this.InitializeComponent();

            _apiService = App.GetService<VKApiService>();
            _playerService = App.GetService<AudioPlayerService>();

            MixesGridView.ItemsSource = _mixes;
        }

        protected override async void OnNavigatedTo(Microsoft.UI.Xaml.Navigation.NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            await LoadMixes();
        }

        private async Task LoadMixes()
        {
            SetLoading(true);

            try
            {
                var mixes = await _apiService.GetMixes();
                _mixes.Clear();
                foreach (var mix in mixes)
                {
                    _mixes.Add(mix);
                }

                EmptyText.Visibility = _mixes.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to load mixes: {ex.Message}");
                EmptyText.Text = "Ошибка загрузки миксов";
                EmptyText.Visibility = Visibility.Visible;
            }
            finally
            {
                SetLoading(false);
            }
        }

        private async void OnMixClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is VKMix mix)
            {
                try
                {
                    var tracks = await _apiService.GetMixTracks(mix.Id);
                    if (tracks.Count > 0)
                    {
                        _playerService.SetQueue(tracks, 0);
                        await _playerService.Play(0);
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Failed to load mix tracks: {ex.Message}");
                }
            }
        }

        private void SetLoading(bool isLoading)
        {
            LoadingRing.IsActive = isLoading;
            LoadingRing.Visibility = isLoading ? Visibility.Visible : Visibility.Collapsed;
        }
    }
}