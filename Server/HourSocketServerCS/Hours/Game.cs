using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Hours {
    public static class Game {
        public static List<Entity> entities = new();
        public static string currentMap = "SandyBlue"; // this is the default map for hours.
        private static string previousMap = "SandyBlue";

        public static void Wipe() {
            foreach (Entity entity in entities.Where(entity => entity.isplayer == false)) { 
                entities.Remove(entity);
            }
            Helper.Say((byte)LogTypes.RELEASE, "Game has been wiped, all entities deleted.", ConsoleColor.Yellow);
        }

        public static void WipeEntity(int id) {
            if (entities.FirstOrDefault(entity => entity.id == id) == null)
                return;
            entities.Remove(entities.FirstOrDefault(e => e.id == id)!);
        }

        public static void Update() {
            if (currentMap != previousMap) {
                Wipe();
                return;
            }

            foreach (Entity entity in entities.ToList().Where(entity => entity != null && entity.isplayer == false)) {
                if (entity.health <= 0) {
                    entities.Remove(entity);
                    Helper.Say((byte)LogTypes.RELEASE, $"Entity {entity.id} died, removing from entity list.", ConsoleColor.Yellow);
                }
            }
        }
    }
}
