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
    /// <summary>
    /// this is so that clients know when a player gets damaged so they can play the according animation / stun / damage idk
    /// </summary>
    public class PlayerDamaged : Message
    {
        public override int Index() => MessageIds.PlayerDamaged;

        public override void Handle(Player player, string data)
        {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string sourceEntityId = reader.ReadUntilSeperator();
            string 

            Helper.Say((byte)LogTypes.INFO, $"{player.username} got damaged", ConsoleColor.Yellow);

            string contents2 = Networker.PrepareForLua(Index(), player.id.ToString(), index, value);
            Networker.SendToAll(contents2, new Player[] { player });
        }
    }
}
