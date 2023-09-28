using HourSocketServerCS.Hours;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Networking {
    public static class Networker {
        public static void SendToClient(Player player, string data) {
            Server.server!.SendAsync(player.clientGuid,Encoding.UTF8.GetBytes(data),WebSocketMessageType.Text);
        }

        public static void SendToAll(string data, Player[]? except = null) {
            except ??= Array.Empty<Player>();

            foreach (Player player in PlayerHandler.players.ToList().Where(p => except.Contains(p) == false)) {
                SendToClient(player, data);
            }
        }

        public static string PrepareForLua(int messageId, params string[] toSend) {
            string endString = $"{messageId}{ServerSettings.Lua.seperator}";
            int index = 0;
            foreach (string argument in toSend) {
                if (index == 0) {
                    endString += $"{argument}";
                }
                else {
                    endString += $"{ServerSettings.Lua.seperator}{argument}";
                }
                index++;
            }
            return endString;
        }
    }
}