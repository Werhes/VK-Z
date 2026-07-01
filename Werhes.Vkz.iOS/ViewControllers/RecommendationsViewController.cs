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
    public class RecommendationsViewController : UIViewController
    {
        private UICollectionView _collectionView;
        private List<Block> _blocks;
        private UIActivityIndicatorView _loader;

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            Title = "Рекомендации";
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _loader = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            View.AddSubview(_loader);

            var layout = new UICollectionViewFlowLayout
            {
                ItemSize = new CoreGraphics.CGSize(160, 180),
                MinimumInteritemSpacing = 8,
                MinimumLineSpacing = 12,
                SectionInset = new UIEdgeInsets(12, 12, 12, 12),
                ScrollDirection = UICollectionViewScrollDirection.Vertical
            };

            _collectionView = new UICollectionView(View.Bounds, layout)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                BackgroundColor = UIColor.Clear,
                AlwaysBounceVertical = true
            };
            _collectionView.RegisterClass(typeof(RecommendationCell), RecommendationCell.CellId);
            _collectionView.DataSource = new RecommendationDataSource(this);
            _collectionView.Delegate = new RecommendationDelegate(this);
            View.AddSubview(_collectionView);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _collectionView.TopAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.TopAnchor),
                _collectionView.BottomAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.BottomAnchor),
                _collectionView.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                _collectionView.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor),
                _loader.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _loader.CenterYAnchor.ConstraintEqualTo(View.CenterYAnchor)
            });

            LoadData();
        }

        private async void LoadData()
        {
            _loader.StartAnimating();
            try
            {
                var blocks = await Task.Run(() =>
                    Core.VKontakte.Music.Recommendations.GetBlocksSync());
                _blocks = blocks.ConvertToBlocks();
                _collectionView.ReloadData();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Load recommendations error: {ex.Message}");
            }
            _loader.StopAnimating();
        }

        private class RecommendationDataSource : UICollectionViewDataSource
        {
            private readonly RecommendationsViewController _vc;
            public RecommendationDataSource(RecommendationsViewController vc) => _vc = vc;

            public override nint GetItemsCount(UICollectionView collectionView, nint section) => 10;

            public override UICollectionViewCell GetCell(UICollectionView collectionView, NSIndexPath indexPath)
            {
                var cell = (RecommendationCell)collectionView.DequeueReusableCell(RecommendationCell.CellId, indexPath);
                cell.Update($"Рекомендация {indexPath.Row + 1}", null);
                return cell;
            }
        }

        private class RecommendationDelegate : UICollectionViewDelegateFlowLayout
        {
            private readonly RecommendationsViewController _vc;
            public RecommendationDelegate(RecommendationsViewController vc) => _vc = vc;
        }
    }
}