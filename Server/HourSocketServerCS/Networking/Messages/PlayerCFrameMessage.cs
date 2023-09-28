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
    public class PlayerCFrameMessage : Message
    {
        public override int Index() => MessageIds.PlayerInput;

        public override void Handle(Player player, string data) {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string input = reader.ReadUntilSeperator();
            player.entity!.cameraPos = Helper.GetV3();
            player.entity!.rotation = Helper.GetV3(rotation);

            string contents2 = Networker.PrepareForLua(Index(), player.id.ToString(), position, rotation);
            Networker.SendToAll(contents2, new Player[] { player });
        }
    }
}
