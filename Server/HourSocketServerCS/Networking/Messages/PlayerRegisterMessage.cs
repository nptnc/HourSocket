using HourSocketServerCS.Hours;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace HourSocketServerCS.Network.Messages
{
    public class PlayerRegisterMessage : Message
    {
        public override int Index() => MessageIds.PlayerUpdate;

        public override void Handle(Player player, string data) {
            Reader reader = new(data);
            string username = reader.ReadUntilSeperator();
            string playerclass = reader.ReadUntilSeperator();
            string position = reader.ReadUntilSeperator();
            string rotation = reader.ReadUntilSeperator();
            player.OnRegister(username, playerclass, Helper.GetV3(position), Helper.GetV3(rotation));

            string contents = Networker.PrepareForLua(Index(), player.id.ToString(), username, playerclass, position, rotation, player.isHost.ToString().ToLower());
            Networker.SendToClient(player, contents);
        }
    }
}
