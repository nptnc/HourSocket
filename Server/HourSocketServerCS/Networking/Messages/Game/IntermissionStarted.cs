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
    public class IntermissionStartedMessage : Message {
        public override int Index() => MessageIds.IntermissionStarted;

        public override void Handle(Player player, string data) {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string arena = reader.ReadUntilSeperator();

            Helper.Say((byte)LogTypes.RELEASE, $"host went into intermission [arena {arena}], sending to other players.", ConsoleColor.Yellow);
            string contents = Networker.PrepareForLua(Index(), arena);
            Networker.SendToAll(contents, new Player[] { player });
        }
    }
}
