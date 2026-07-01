using Foundation;

namespace Werhes.Vkz.iOS.Services
{
    public static class AuthService
    {
        private const string TokenKey = "VKToken";
        private const string DefaultsSuite = "Vkz";

        public static bool IsLoggedIn()
        {
            var defaults = new NSUserDefaults(DefaultsSuite);
            return !string.IsNullOrEmpty(defaults.StringForKey(TokenKey));
        }

        public static string GetToken()
        {
            var defaults = new NSUserDefaults(DefaultsSuite);
            return defaults.StringForKey(TokenKey);
        }

        public static void SaveToken(string token)
        {
            var defaults = new NSUserDefaults(DefaultsSuite);
            defaults.SetString(token, TokenKey);
            defaults.Synchronize();
        }

        public static void ClearToken()
        {
            var defaults = new NSUserDefaults(DefaultsSuite);
            defaults.RemoveObject(TokenKey);
            defaults.Synchronize();
        }

        public static void Logout()
        {
            ClearToken();
        }
    }
}