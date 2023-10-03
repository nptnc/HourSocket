using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Util {
    public static class Helper {
        public static void Say(byte logType, string toLog, ConsoleColor color = ConsoleColor.White, bool end = true, bool timeStamp = true) {
            if (logType < (byte)Main.logType)
                return;

            LogTypes logType2 = (LogTypes)logType;
            string toDebug = toLog;
            if (timeStamp) {
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write($"{DateTime.Now.ToString()}");
                Console.ForegroundColor = ConsoleColor.Green;
                Console.Write($" [{logType2.ToString()}] ");
            }
            Console.ForegroundColor = color;
            if (end)
                Console.WriteLine(toDebug);
            else
                Console.Write(toDebug);
            Console.ResetColor();
        }

        public static void SayMulti(byte logType, params KeyValuePair<string,ConsoleColor>[] pairs) {
            int index = 0;
            foreach (KeyValuePair<string,ConsoleColor> pair in pairs) {
                index++;
                if (index == pairs.Length)
                    Say(logType, pair.Key, pair.Value, true, false);
                else
                    if (index == 1)
                        Say(logType, pair.Key, pair.Value, false, true);
                    else
                        Say(logType, pair.Key, pair.Value, false, false);
            }
        }

        public static string RepeatChar(char text, int n) {
            return new string(text, n);
        }
    }
}
