using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using VKZ.Models;
using VKZ.Services;

namespace VKZ.Views
{
    public partial class SearchView : UserControl
    {
        public ObservableCollection<VKTrack> SearchResults { get; } = new();

        public SearchView()
        {
            InitializeComponent();
            DataContext = this;
        }

        private async void OnSearchClick(object sender, RoutedEventArgs e)
        {
            await PerformSearch();
        }

        private async void OnSearchKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
            {
                await PerformSearch();
            }
        }

        private async System.Threading.Tasks.Task PerformSearch()
        {
            var query = SearchTextBox.Text?.Trim();
            if (string.IsNullOrEmpty(query)) return;

            try
            {
                var results = await VKApiService.Instance.SearchAudioAsync(query, 50);
                SearchResults.Clear();
                foreach (var track in results)
                {
                    SearchResults.Add(track);
                }
                SearchResultsList.ItemsSource = SearchResults;
            }
            catch (System.Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Search error: {ex.Message}");
            }
        }
    }
}