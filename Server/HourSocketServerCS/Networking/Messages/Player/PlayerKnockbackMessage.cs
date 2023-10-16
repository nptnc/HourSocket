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
    public class PlayerKnockbackMessage : Message
    {
        public override int Index() => MessageIds.PlayerKnockback;

        public override void Handle(Player player, string data)
        {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string knockbackIndex = reader.ReadUntilSeperator();
            string knockbackValue = reader.ReadUntilSeperator();

            Vector3 knockbackV3Value = knockbackValue.NetVector3();

            Helper.Say((byte)LogTypes.INFO, $"{player.username} knockback {knockbackV3Value.X}, {knockbackV3Value.Y}, {knockbackV3Value.Z}", ConsoleColor.Yellow);

            string contents = Networker.PrepareForLua(Index(), player.id.ToString(), knockbackIndex, knockbackValue);
            Networker.SendToAll(contents, new Player[] { player });
        }
    }
}
