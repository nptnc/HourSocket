using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Hours {
    public static class PlayerHandler {
        public static List<Player> players = new();

        public static void RegisterPlayer(Player player) {
            players.Add(player);
        }

        public static Player? GetPlayerFromClientGUID(Guid client) {
            foreach (Player player in players) {
                if (player.clientGuid == client) 
                    return player;
            }
            return null;
        }

        public static void DestroyPlayer(Guid client) {
            Player? player = GetPlayerFromClientGUID(client);
            if (player == null)
                return;

            if (player.entity != null)
                Game.WipeEntity(player.entity.id);

            Helper.Say((byte)LogTypes.RELEASE, $"Destroyed player {player.username}", ConsoleColor.Yellow);
            players.Remove(player);

            if (players.Count <= 0) {
                Helper.Say((byte)LogTypes.RELEASE, $"All players have left the game, player global id have now been reset.", ConsoleColor.Yellow);
                Player.globalId = 0;
            }
        }
    }
}
