﻿using HourSocketServerCS.Hours;
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
    public class SubjectPotionAddMessage : Message
    {
        public override int Index() => MessageIds.SubjectPotionAdd;

        public override void Handle(Player player, string data)
        {
            Reader reader = new(data);
            string section = reader.ReadUntilSeperator();
            string index = reader.ReadUntilSeperator();

            Helper.Say((byte)LogTypes.DEV, $"potion {section} {index} added to {player.username}");

            // send this player to everyone except the player.
            string contents = Networker.PrepareForLua(Index(), player.id.ToString(), section, index);
            Networker.SendToAll(contents, new Player[] { player });
        }
    }
}
