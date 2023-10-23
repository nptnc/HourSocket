using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Hours {
    public class Entity
    {
        public static int globalId = 0;

        public Entity(string entitytype, int team, bool isplayer = false, bool isBoss = false)
        {
            globalId += 1;
            
            if (isplayer) {
                Helper.Say((byte)LogTypes.INFO, $"Created a new player entity {entitytype} as id {globalId}", ConsoleColor.Cyan);
            } else {
                Helper.Say((byte)LogTypes.INFO, $"Created a new entity {entitytype} as id {globalId}", ConsoleColor.Cyan);
            }
            
            id = globalId;
            this.isplayer = isplayer;
            this.entitytype = entitytype;
            this.isBoss = isBoss;
            this.team = team;
            Game.entities.Add(this);
        }

        public int id;
        public string? hostNetworkId; // might not have one, its a player
        public int health = 9999; // default health, because we dont know it
        public int team;

        public string entitytype;

        public bool isBoss = false;
        public bool isplayer = false;

        public Vector3 position;
        public Vector3 rotation;
    }
}
