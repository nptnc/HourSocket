using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS {
    public static class ServerSettings {
        public static string ipaddress = "0.0.0.0"; // ip 👍
        public static int port = 6969; // port to port forward 👍
        
        /// <summary>
        /// When receiving information from fleck its usually something along the lines of this if the message was for player cframe.
        /// 2:::3_0_6:::0_180_0
        /// (messageId:::position:::rotation)
        /// we need to extract everything other than the data seperator
        /// </summary>
        public static string seperator = ":::";
    }
}
