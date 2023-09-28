using HourSocketServerCS.Hours;
using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Network
{
    public static class MessageHandler
    {
        public static Dictionary<int, Message> messages = new();

        public static void RegisterMessages()
        {
            Assembly ass = Assembly.GetExecutingAssembly();
            foreach (Type type in ass.GetTypes())
            {
                if (type.BaseType != typeof(Message))
                    continue;

                Message ms = (Message)Activator.CreateInstance(type)!;
                Helper.Say((byte)LogTypes.OHSHITSOMETHINGHASGONECATASTROPHICALLYWRONG, $"Registered message {type.Name} as {ms.Index()}", ConsoleColor.Cyan);
                messages.Add(ms.Index(), ms);
            }
        }

        public static void HandleMessage(Player player, int messageId, string data) {
            if (!messages.ContainsKey(messageId))
                return;
            messages.FirstOrDefault(pair => pair.Key == messageId).Value.Handle(player,data);
        }
    }
}
