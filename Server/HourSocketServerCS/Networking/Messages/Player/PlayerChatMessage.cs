using HourSocketServerCS.Extensions;
using HourSocketServerCS.Hours;
using HourSocketServerCS.Network;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace HourSocketServerCS.Networking.Messages
{
    public class PlayerChatMessage : Message
    {
        public override int Index() => MessageIds.PlayerChat;

        public override void Handle(Player player, string data)
        {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string message = reader.ReadUntilSeperator();

            Helper.Say((byte)LogTypes.INFO, $"{player.username}: {message}", ConsoleColor.Yellow);

            string contents = Networker.PrepareForLua(Index(), player.userId, message);
            Networker.SendToAll(contents, new Player[] { player });
        }
    }
}
