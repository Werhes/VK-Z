using Werhes.Vkz.Core.VKontakte.Users;
using System;
using System.Collections.Generic;
using System.Text;
using VkNet;

namespace Werhes.Vkz.Core.VKontakte
{
    public class UsersApi
    {
        public UsersApi(VkApi api)
        {
            Info = new Info(api);
        }
        public Info Info { get; set; }
    }
}
