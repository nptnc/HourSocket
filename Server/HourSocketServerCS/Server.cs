using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using HourSocketServerCS.Hours;
using System.Collections;
using System.IO;
using HourSocketServerCS.Util;
using HourSocketServerCS.Network;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Extensions;
using Fleck;

namespace HourSocketServerCS
{
    public class Server
    {
        public static WebSocketServer? server;

        public void Start()
        {
            server = new WebSocketServer($"ws://{ServerSettings.ipaddress}:{ServerSettings.port}");
            server.Start(socket => {
                socket.OnOpen = () => {
                    Console.WriteLine($"A client connected, their ID is {socket.GetHashCode()}");
                    new Player(socket.GetHashCode(),socket);
                };
                socket.OnClose = () => {
                    PlayerHandler.DestroyPlayer(socket.GetHashCode());
                };
                socket.OnMessage = message => {
                    Reader reader = new(message);
                    int messageType = reader.ReadUntilSeperator().NetInt(); // will read until the first seperator
                    string data = reader.ReadAll(); // reads the rest of it

                    Player? player = PlayerHandler.GetPlayerFromClientGUID(socket.GetHashCode());
                    if (player == null)
                        return;

                    string debugPrint = $"a message was received\nplayer: {player.connection}\nmessageid: {messageType}\ncontents: {data}";

                    // this is just for debug
                    //Console.WriteLine(Helper.RepeatChar(char.Parse("-"),30));
                    //Console.WriteLine(debugPrint);
                    //Console.WriteLine(Helper.RepeatChar(char.Parse("-"),30));

                    if (!MessageHandler.messages.ContainsKey(messageType)) {
                        Helper.Say((byte)LogTypes.INFO, $"Message type {messageType} does not exist!", ConsoleColor.DarkYellow);
                        return;
                    }
                    MessageHandler.HandleMessage(player, messageType, data);
                };
            });

            Helper.SayMulti((byte)LogTypes.INFO, new KeyValuePair<string, ConsoleColor>[] {
                new ($"Server started at",ConsoleColor.Magenta),
                new ($" {ServerSettings.ipaddress}:{ServerSettings.port}",ConsoleColor.Red),
            });
        }

        public void Update() {
            Game.Update();
        }
    }
}
