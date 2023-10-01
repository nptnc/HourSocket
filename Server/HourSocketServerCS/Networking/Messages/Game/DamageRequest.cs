using HourSocketServerCS.Extensions;
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

namespace HourSocketServerCS.Network {
    public class DamageRequestMessage : Message {
        public override int Index() => MessageIds.DamageRequest;

        public override void Handle(Player player, string data) {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string entityNetworkid = reader.ReadUntilSeperator();
            string damage = reader.ReadUntilSeperator();
            string partName = reader.ReadUntilSeperator();
            string attackName = reader.ReadUntilSeperator();
            string screenshake = reader.ReadUntilSeperator();

            Helper.Say((byte)LogTypes.RELEASE, $"{player.username} dealt {damage} to {entityNetworkid}", ConsoleColor.Yellow);
            string contents = Networker.PrepareForLua(Index(), entityNetworkid, damage, partName, attackName, screenshake);
            Networker.SendToClient(PlayerHandler.GetHost()!, contents);
        }
    }
}
