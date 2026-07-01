using Android.Views;

namespace Werhes.Vkz.AndroidApp.Interfaces
{
    public interface IItemClickListener
    {
        void OnClick(View itemView, int position, bool isLongClick);
    }
}