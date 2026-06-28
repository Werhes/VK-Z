using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;
using VKZ.Models;

namespace VKZ.Converters
{
    public class BoolToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            bool boolValue = value is bool b && b;
            bool invert = parameter is string s && s == "invert";
            return invert ? (boolValue ? Visibility.Collapsed : Visibility.Visible)
                          : (boolValue ? Visibility.Visible : Visibility.Collapsed);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
            => throw new NotImplementedException();
    }

    public class SecondsToTimeConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is double seconds)
            {
                var ts = TimeSpan.FromSeconds(seconds);
                return ts.Hours > 0
                    ? $"{ts.Hours}:{ts.Minutes:D2}:{ts.Seconds:D2}"
                    : $"{ts.Minutes}:{ts.Seconds:D2}";
            }
            return "0:00";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
            => throw new NotImplementedException();
    }

    public class PlayerStateToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is PlayerState state)
            {
                string target = parameter as string ?? "Playing";
                return target switch
                {
                    "Playing" => state == PlayerState.Playing ? Visibility.Visible : Visibility.Collapsed,
                    "Paused" => state == PlayerState.Paused ? Visibility.Visible : Visibility.Collapsed,
                    "Loading" => state == PlayerState.Loading ? Visibility.Visible : Visibility.Collapsed,
                    "Idle" => state == PlayerState.Idle ? Visibility.Visible : Visibility.Collapsed,
                    "Active" => state == PlayerState.Playing || state == PlayerState.Paused ? Visibility.Visible : Visibility.Collapsed,
                    _ => Visibility.Collapsed
                };
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
            => throw new NotImplementedException();
    }

    public class StringNotEmptyToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            bool invert = parameter is string s && s == "invert";
            bool hasValue = !string.IsNullOrEmpty(value as string);
            return invert ? (hasValue ? Visibility.Collapsed : Visibility.Visible)
                          : (hasValue ? Visibility.Visible : Visibility.Collapsed);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
            => throw new NotImplementedException();
    }

    public class NullToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            bool invert = parameter is string s && s == "invert";
            bool notNull = value != null;
            return invert ? (notNull ? Visibility.Collapsed : Visibility.Visible)
                          : (notNull ? Visibility.Visible : Visibility.Collapsed);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
            => throw new NotImplementedException();
    }

    public class TrackCountToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is int count)
                return count > 0 ? Visibility.Visible : Visibility.Collapsed;
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
            => throw new NotImplementedException();
    }

    public class StringToImageSourceConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is string url && !string.IsNullOrEmpty(url))
            {
                try
                {
                    return new ImageSourceConverter().ConvertFrom(url);
                }
                catch
                {
                    return null!;
                }
            }
            return null!;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
            => throw new NotImplementedException();
    }
}