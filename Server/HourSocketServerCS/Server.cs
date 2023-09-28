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
using WatsonWebsocket;
using HourSocketServerCS.Network;

namespace HourSocketServerCS
{
    public class Server
    {
        public static WatsonWsServer? server;

        // websockets are very awkward in c# bruh
        public void Start()
        {
            server = new(ServerSettings.ipaddress,ServerSettings.port,false);
            server.ClientConnected += (object? sender, ConnectionEventArgs? args) => {
                new Player(args.Client.Guid);
                Console.WriteLine("Client connected: " + args!.Client.ToString());
            };
            server.ClientDisconnected += (object? sender, DisconnectionEventArgs? args) => {
                PlayerHandler.DestroyPlayer(args.Client.Guid);
            };
            server.MessageReceived += (object? sender, MessageReceivedEventArgs? args) => {
                string decodedMessage = Encoding.UTF8.GetString(args!.Data);

                int messageType;
                int.TryParse($"{decodedMessage[0]}", out messageType);

                string data = "";
                for (int i = 0; i < decodedMessage.Length-(1 + ServerSettings.Lua.seperator.Length); i++) {
                    data += decodedMessage[i+(1 + ServerSettings.Lua.seperator.Length)];
                }

                Player? player = PlayerHandler.GetPlayerFromClientGUID(args.Client.Guid);
                if (player == null)
                    return;

                string debugPrint = $"a message was received\nplayer: {player.clientGuid}\nmessageid: {messageType}\ncontents: {data}";

                // this is just for debug
                //Console.WriteLine(Helper.RepeatChar(char.Parse("-"),30));
                //Console.WriteLine(debugPrint);
                //Console.WriteLine(Helper.RepeatChar(char.Parse("-"),30));
                if (!MessageHandler.messages.ContainsKey(messageType)) {
                    Helper.Say((byte)LogTypes.RELEASE, $"Message type {messageType} does not exist!", ConsoleColor.DarkYellow);
                    return;
                }
                MessageHandler.HandleMessage(player, messageType, data);
            };
            server.Start();
            Helper.Say((byte)LogTypes.RELEASE, $"Server started at {ServerSettings.ipaddress}:{ServerSettings.port}", ConsoleColor.Magenta);
        }

        public void Update() {
            Game.Update();
        }
    }
}
