﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS {
    public static class ServerSettings {
        public static string ipaddress = "0.0.0.0"; // ip 👍
        public static int port = 6969; // port to port forward 👍
        
        public static class Lua {
            public static string seperator = ":::"; // lua doesnt handle messages like we do, they dont have instructions on how to decode each message
        }
    }
}
