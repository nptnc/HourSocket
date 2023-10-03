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
    public class GameStateChangedMessage : Message {
        public override int Index() => MessageIds.GameStateChanged;

        public override void Handle(Player player, string data) {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string state = reader.ReadUntilSeperator()!;
            string arena = reader.ReadUntilSeperator()!;
            Game.currentState = state;

            Helper.Say((byte)LogTypes.INFO, $"game state changed to {state} {arena}, sending to other players.", ConsoleColor.Yellow);
            string contents = Networker.PrepareForLua(Index(), state, arena);
            Networker.SendToAll(contents, new Player[] { player });
        }
    }
}
