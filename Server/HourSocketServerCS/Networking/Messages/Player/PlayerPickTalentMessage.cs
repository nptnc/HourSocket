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
    public class PlayerPickTalentMessage : Message
    {
        public override int Index() => MessageIds.PlayerPickTalent;

        public override void Handle(Player player, string data)
        {
            if (!player.hasRegistered)
                return;
            if (player.pickedTalent == true)
                return;

            Reader reader = new(data);
            string talentIndex = reader.ReadUntilSeperator();
            player.pickedTalent = true;
            player.pickedTalentIndex = talentIndex.NetInt();

            Helper.Say((byte)LogTypes.INFO, $"{player.username} chose talent {talentIndex}", ConsoleColor.Yellow);
            foreach (Player otherPlayer in PlayerHandler.players.ToList().Where(p => p.hasRegistered == true))
            {
                if (otherPlayer.pickedTalent != true)
                    return;
            }

            Helper.Say((byte)LogTypes.INFO, $"everyone chose their talents, sending every player their talent.", ConsoleColor.Yellow);
            foreach (Player otherPlayer in PlayerHandler.players.Where(p => p.hasRegistered == true))
            {
                otherPlayer.pickedTalent = false;
                string contents2 = Networker.PrepareForLua(Index(), otherPlayer.pickedTalentIndex.ToString());
                Networker.SendToClient(otherPlayer, contents2);
            }
        }
    }
}
