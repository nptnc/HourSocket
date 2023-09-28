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

        /// <summary>
        /// reverses vector3 sent by lua which is x_y_z
        /// </summary>
        public static Vector3 GetV3(string receivedData) {
            string[] xyz = receivedData.Split("_");
            float[] end = new float[3];
            for (int i = 0; i < 3; i++) {
                float.TryParse(xyz[i], out end[i]);
            }
            return new Vector3(end[0], end[1], end[2]);
        }
    }
}
