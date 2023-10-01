using HourSocketServerCS.Extensions;
using HourSocketServerCS.Hours;
using HourSocketServerCS.Network;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace HourSocketServerCS.Networking.Messages
{
    public class PlayerStateMessage : Message
    {
        public override int Index() => MessageIds.PlayerStateUpdate;

        public override void Handle(Player player, string data)
        {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string index = reader.ReadUntilSeperator();
            string value = reader.ReadUntilSeperator();

            if (index == "health")
            {
                player.entity!.health = value.NetInt();
            }

            Helper.Say((byte)LogTypes.RELEASE, $"{player.username} state changed, {index} : {value}", ConsoleColor.Yellow);

            string contents2 = Networker.PrepareForLua(Index(), player.id.ToString(), index, value);
            Networker.SendToAll(contents2, new Player[] { player });
        }
    }
}
