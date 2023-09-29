using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Util {
    public static class Helper {
        public static void Say(byte logType, string toLog, ConsoleColor color = ConsoleColor.White) {
            if (logType < (byte)Main.logType)
                return;
            Console.ForegroundColor = color;
            Console.WriteLine(toLog);
            Console.ResetColor();
        }

        public static string RepeatChar(char text, int n) {
            return new string(text, n);
        }
    }
}
