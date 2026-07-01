using System;
using System.Collections.Generic;
using System.Text;
using Lpfm.LastFmScrobbler;

namespace Werhes.Vkz.Core.LastFM
{
    public class LastFmScrobblerApi
    {
        private Scrobbler _scrobbler;
        public LastFmScrobblerApi()
        {
            Auth = new AuthApi(this);
            Scrobble = new ScrobblerApi(_scrobbler);
        }

        public AuthApi Auth { get; set; }
        public ScrobblerApi Scrobble { get; set; }

        public void SetScrobbler(Scrobbler scrobbler)
        {
            this._scrobbler = scrobbler;
        }

        public bool IsAuth => _scrobbler != null;
    }
}
