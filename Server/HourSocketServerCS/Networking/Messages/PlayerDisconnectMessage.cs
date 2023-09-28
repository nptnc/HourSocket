using HourSocketServerCS.Hours;
using HourSocketServerCS.Networking;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Network.Messages
{
    public class PlayerDisconnectMessage : Message
    {
        public override int Index() => MessageIds.PlayerDisconnect;

        public Writer Create(Player player) {
            Writer writer = new();
            return writer;
        }

        public override void Handle(Player player, string data) { }
    }
}
