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

            // send this player to everyone except the player.
            string contents = Networker.PrepareForLua(Index(), player.id.ToString(), username, playerclass, position, rotation, player.isHost.ToString().ToLower(), "true");
            Networker.SendToAll(contents, new Player[] { player });

            foreach (Player otherPlayer in PlayerHandler.players.ToList()) {
                // send every player to this player
                string contents2 = Networker.PrepareForLua(Index(), player.id.ToString(), username, playerclass, position, rotation, player.isHost.ToString().ToLower(), otherPlayer.id == player.id ? "true" : "false");
                Networker.SendToClient(player, contents2);
            }
        }
    }
}
