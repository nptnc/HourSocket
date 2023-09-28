using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS {
    public static class Main {
        public static LogTypes logType;

        public static void Start() {
            logType = LogTypes.OHSHITSOMETHINGHASGONECATASTROPHICALLYWRONG;
        }

        public async static void LoadSettings() {
            string path = AppDomain.CurrentDomain.BaseDirectory;
            string settingsPath = $"{path}/settings.cfg";
            if (!File.Exists(settingsPath)) {
                Helper.Say((byte)LogTypes.RELEASE, "Config file does not exist, creating one.", ConsoleColor.Yellow);

                JObject config = new JObject(
                    new JProperty("ip", ServerSettings.ipaddress),
                    new JProperty("port", ServerSettings.port)
                );

                using (StreamWriter file = File.CreateText(settingsPath))
                using (JsonTextWriter writer = new JsonTextWriter(file)) {
                    writer.Formatting = Formatting.Indented;
                    config.WriteTo(writer);
                }

                return;
            }

            using (StreamReader file = File.OpenText(settingsPath))
            using (JsonTextReader reader = new JsonTextReader(file)) {
                JObject o2 = (JObject)JToken.ReadFrom(reader);
                ServerSettings.ipaddress = (string)o2.Property("ip")!;
                ServerSettings.port = (int)o2.Property("port")!;

                Helper.Say((byte)LogTypes.RELEASE, "Loading from config file.", ConsoleColor.Yellow);
            }
        }
    }
}
