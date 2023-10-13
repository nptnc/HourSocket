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
    public class PlayerRegisterMessage : Message
    {
        public override int Index() => MessageIds.PlayerRegister;

        public override void Handle(Player player, string data)
        {
            Reader reader = new(data);
            string username = reader.ReadUntilSeperator();
            string playerclass = reader.ReadUntilSeperator();
            string position = reader.ReadUntilSeperator();
            string rotation = reader.ReadUntilSeperator();
            player.OnRegister(username, playerclass, position.NetVector3(), rotation.NetVector3());

            // send this player to everyone except the player.
            string contents = Networker.PrepareForLua(Index(), player.id.ToString(), username, playerclass, position, rotation, player.isHost.ToString().ToLower(), "false");
            Networker.SendToAll(contents, new Player[] { player });

            foreach (Player otherPlayer in PlayerHandler.players.ToList().Where(p => p.hasRegistered))
            {
                // send every player to this player
                string contents2 = Networker.PrepareForLua(Index(), player.id.ToString(), username, playerclass, position, rotation, player.isHost.ToNetwork(), (otherPlayer.id == player.id).ToNetwork());
                Networker.SendToClient(player, contents2);
            }
        }
    }
}
