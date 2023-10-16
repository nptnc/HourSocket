using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Numerics;
using System.Threading.Tasks;

namespace HourSocketServerCS.Extensions {
    public static class StringExtension {
        public static Vector3 NetVector3(this string text) {
            string[] xyz = text.Split("_");
            float[] end = new float[3];
            for (int i = 0; i < 3; i++) {
                float.TryParse(xyz[i], out end[i]);
            }
            return new Vector3(end[0], end[1], end[2]);
        }

        public static bool NetBool(this string text) {
            if (text == "true")
                return true;
            else if (text == "false")
                return false;
            Console.WriteLine("thats probably bad?");
            return false; // hopefully this never happens...
        }

        public static int NetInt(this string text) {
            int toReturn;
            int.TryParse(text, out toReturn);
            return toReturn;
        }
    }
}
