using Fleck;
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

        public static Player? GetPlayerFromClientGUID(int connection) {
            foreach (Player player in players) {
                if (player.connection == connection) 
                    return player;
            }
            return null;
        }

        public static void DestroyPlayer(int connection) {
            Player? player = GetPlayerFromClientGUID(connection);
            if (player == null)
                return;

            if (player.entity != null)
                Game.WipeEntity(player.entity.id);

            bool wasHost = player.isHost;

            Helper.Say((byte)LogTypes.INFO, $"Destroyed player {player.username}", ConsoleColor.Yellow);
            players.Remove(player);

            if (players.Count <= 0) {
                Helper.Say((byte)LogTypes.INFO, $"All players have left the game, player global id have now been reset.", ConsoleColor.Cyan);
                Player.globalId = 0;
                return;
            }

            if (wasHost) {
                List<int> ids = new();
                foreach (Player newPlayer in players) {
                    ids.Add(newPlayer.id);
                }
                foreach (Player newPlayer in players.Where(p => p.hasRegistered == true)) {
                    int min = ids.Min();
                    if (newPlayer.id == min) {
                        newPlayer.isHost = true;
                        Helper.Say((byte)LogTypes.INFO, $"Host has been transferred to {newPlayer!.username} id {newPlayer.id}!", ConsoleColor.Cyan);
                    }
                }
            }
        }

        public static Player? GetHost() {
            return players.FirstOrDefault(player => player.isHost == true);
        }
    }
}
