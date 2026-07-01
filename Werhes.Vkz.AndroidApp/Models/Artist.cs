using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using Android.App;
using Android.Content;
using Android.OS;
using Android.Runtime;
using Android.Views;
using Android.Widget;

namespace Werhes.Vkz.AndroidApp.Models
{
    public class Artist: Werhes.Vkz.Core.Models.Artist
    {
        public bool IsFavorite { get; set; }
    }
}