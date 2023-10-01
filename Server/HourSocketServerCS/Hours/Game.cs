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
        private static string? previousMap;

        public static void Start() {
            previousMap = currentMap;
        }

        public static Entity? GetEntityByNetworkId(int networkid) {
            return entities.FirstOrDefault(entity => entity.hostNetworkId == networkid);
        }

        public static Entity? GetEntityById(int id) {
            return entities.FirstOrDefault(entity => entity.id == id);
        }

        public static void Wipe() {
            foreach (Entity entity in entities.Where(entity => entity.isplayer == false)) { 
                entities.Remove(entity);
            }
            Helper.Say((byte)LogTypes.RELEASE, "Game has been wiped, reset entity list.", ConsoleColor.Yellow);
        }

        public static void WipeEntity(int id) {
            if (entities.FirstOrDefault(entity => entity.id == id) == null)
                return;
            entities.Remove(entities.FirstOrDefault(e => e.id == id)!);
        }

        public static void Update() {
            if (currentMap != previousMap) {
                Wipe();
                previousMap = currentMap;
                return;
            }

            List<Entity> zazaEntities = entities.ToList();
            foreach (Entity entity in zazaEntities.Where(entity => entity != null && entity.isplayer == false)) {
                if (entity.health <= 0) {
                    entities.Remove(GetEntityById(entity.id));
                    Helper.Say((byte)LogTypes.RELEASE, $"Entity {entity.id} died, removing from entity list.", ConsoleColor.Yellow);
                }
            }
        }
    }
}
