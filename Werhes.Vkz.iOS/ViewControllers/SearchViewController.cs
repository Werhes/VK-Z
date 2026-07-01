using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UIKit;
using Werhes.Vkz.iOS.Converters;
using Werhes.Vkz.iOS.Models;
using Werhes.Vkz.iOS.Services;
using Werhes.Vkz.iOS.Views;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class SearchViewController : UIViewController
    {
        private UISearchBar _searchBar;
        private UITableView _tableView;
        private List<Track> _searchResults;
        private UIActivityIndicatorView _loader;

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            Title = "Поиск";
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _searchBar = new UISearchBar
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                Placeholder = "Например, Werhes",
                BarTintColor = UIColor.FromRGB(0x2D, 0x2D, 0x2D),
                SearchBarStyle = UISearchBarStyle.Minimal,
                TintColor = UIColor.White
            };
            _searchBar.SearchTextField.TextColor = UIColor.White;
            _searchBar.SearchTextField.BackgroundColor = UIColor.FromRGB(0x2D, 0x2D, 0x2D);
            _searchBar.SearchTextField.AttributedPlaceholder = new Foundation.NSAttributedString(
                "Например, Werhes",
                foregroundColor: UIColor.FromRGB(0xAA, 0xAA, 0xAA));
            _searchBar.SearchButtonClicked += OnSearch;
            View.AddSubview(_searchBar);

            _tableView = new UITableView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                BackgroundColor = UIColor.Clear,
                SeparatorColor = UIColor.FromRGB(0x3D, 0x3D, 0x3D),
                TableFooterView = new UIView()
            };
            _tableView.RegisterClass(typeof(TrackCell), TrackCell.CellId);
            _tableView.DataSource = new SearchTableDataSource(this);
            _tableView.Delegate = new SearchTableDelegate(this);
            View.AddSubview(_tableView);

            _loader = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            View.AddSubview(_loader);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _searchBar.TopAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.TopAnchor),
                _searchBar.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                _searchBar.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor),

                _tableView.TopAnchor.ConstraintEqualTo(_searchBar.BottomAnchor),
                _tableView.BottomAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.BottomAnchor),
                _tableView.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                _tableView.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor),

                _loader.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _loader.CenterYAnchor.ConstraintEqualTo(View.CenterYAnchor)
            });
        }

        private async void OnSearch(object sender, EventArgs e)
        {
            var query = _searchBar.Text;
            if (string.IsNullOrWhiteSpace(query)) return;

            _searchBar.ResignFirstResponder();
            _loader.StartAnimating();

            try
            {
                var tracks = await Task.Run(() =>
                    Core.VKontakte.Music.Search.TracksSync(query, 30));
                _searchResults = tracks.ConvertToAudioFile();
                _tableView.ReloadData();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Search error: {ex.Message}");
            }

            _loader.StopAnimating();
        }

        private class SearchTableDataSource : UITableViewDataSource
        {
            private readonly SearchViewController _vc;
            public SearchTableDataSource(SearchViewController vc) => _vc = vc;

            public override nint RowsInSection(UITableView tableView, nint section) =>
                _vc._searchResults?.Count ?? 0;

            public override UITableViewCell GetCell(UITableView tableView, NSIndexPath indexPath)
            {
                var cell = (TrackCell)tableView.DequeueReusableCell(TrackCell.CellId, indexPath);
                var track = _vc._searchResults[indexPath.Row];
                cell.Update(track.Title, track.Artist, null);
                return cell;
            }
        }

        private class SearchTableDelegate : UITableViewDelegate
        {
            private readonly SearchViewController _vc;
            public SearchTableDelegate(SearchViewController vc) => _vc = vc;

            public override void RowSelected(UITableView tableView, NSIndexPath indexPath)
            {
                tableView.DeselectRow(indexPath, true);
                var track = _vc._searchResults[indexPath.Row];
                var album = new Album
                {
                    Id = 0,
                    Title = track.Title,
                    Cover = track.Album?.Cover,
                    Tracks = _vc._searchResults
                };
                PlayerService.Instance.Play(album, track);
            }
        }
    }
}