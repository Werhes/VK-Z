using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UIKit;
using Werhes.Vkz.iOS.Models;
using Werhes.Vkz.iOS.Services;
using Werhes.Vkz.iOS.Views;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class PlaylistsViewController : UIViewController
    {
        private UITableView _tableView;
        private List<Album> _playlists;
        private UIActivityIndicatorView _loader;

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            Title = "Плейлисты";
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _loader = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            View.AddSubview(_loader);

            _tableView = new UITableView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                BackgroundColor = UIColor.Clear,
                SeparatorColor = UIColor.FromRGB(0x3D, 0x3D, 0x3D),
                TableFooterView = new UIView(),
                RowHeight = 75
            };
            _tableView.RegisterClass(typeof(PlaylistCell), PlaylistCell.CellId);
            _tableView.DataSource = new PlaylistsDataSource(this);
            _tableView.Delegate = new PlaylistsDelegate(this);
            View.AddSubview(_tableView);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _tableView.TopAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.TopAnchor),
                _tableView.BottomAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.BottomAnchor),
                _tableView.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                _tableView.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor),

                _loader.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _loader.CenterYAnchor.ConstraintEqualTo(View.CenterYAnchor)
            });

            LoadPlaylists();
        }

        private async void LoadPlaylists()
        {
            _loader.StartAnimating();
            try
            {
                _playlists = await PlaylistsService.GetPlaylistsAsync();
                _tableView.ReloadData();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Load playlists error: {ex.Message}");
            }
            _loader.StopAnimating();
        }

        private class PlaylistsDataSource : UITableViewDataSource
        {
            private readonly PlaylistsViewController _vc;
            public PlaylistsDataSource(PlaylistsViewController vc) => _vc = vc;

            public override nint RowsInSection(UITableView tableView, nint section) =>
                _vc._playlists?.Count ?? 0;

            public override UITableViewCell GetCell(UITableView tableView, NSIndexPath indexPath)
            {
                var cell = (PlaylistCell)tableView.DequeueReusableCell(PlaylistCell.CellId, indexPath);
                var playlist = _vc._playlists[indexPath.Row];
                cell.Update(playlist.Title, playlist.Tracks?.Count ?? 0, null);
                return cell;
            }
        }

        private class PlaylistsDelegate : UITableViewDelegate
        {
            private readonly PlaylistsViewController _vc;
            public PlaylistsDelegate(PlaylistsViewController vc) => _vc = vc;

            public override void RowSelected(UITableView tableView, NSIndexPath indexPath)
            {
                tableView.DeselectRow(indexPath, true);
                var playlist = _vc._playlists[indexPath.Row];
                var tracksVC = new TracksViewController(playlist);
                _vc.NavigationController.PushViewController(tracksVC, true);
            }
        }
    }
}