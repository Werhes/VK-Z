using System;
using System.Collections.Generic;
using System.Text;
using Werhes.Vkz.Core.Interfaces;

namespace Werhes.Vkz.Core.Models
{
    public class UserInfo : IUserInfo
    {
        public long Id { get; set; }
        public string LastName { get; set; }
        public string FirstName { get; set; }
        public string PhotoUser { get; set; }
    }
}
