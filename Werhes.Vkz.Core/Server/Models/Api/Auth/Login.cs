using System;
using System.Collections.Generic;
using System.Text;
using Newtonsoft.Json;

namespace Werhes.Vkz.Core.Server.Models.Api.Auth
{
    public class Login
    {
        [JsonProperty("access_token")]
        public string AccessToken { get; set; }
    }
}
