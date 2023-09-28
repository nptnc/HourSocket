﻿using HourSocketServerCS.Hours;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace HourSocketServerCS.Network.Messages {
    public class PlayerInputMessage : Message {
        public override int Index() => MessageIds.PlayerInput;

        public override void Handle(Player player, string data) {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string input = reader.ReadUntilSeperator();
            string position = reader.ReadUntilSeperator();
            string rotation = reader.ReadUntilSeperator();
            player.cameraPos = Helper.GetV3(position);
            player.cameraRot = Helper.GetV3(rotation);

            Helper.Say((byte)LogTypes.RELEASE, $"{player.username} inputted {input}", ConsoleColor.Yellow);
            string contents2 = Networker.PrepareForLua(Index(), player.id.ToString(), input, position, rotation);
            Networker.SendToAll(contents2, new Player[] { player });
        }
    }
}
