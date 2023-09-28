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

        public Entity(string entityid, bool isplayer = false)
        {
            globalId += 1;
            
            if (isplayer) {
                Helper.Say((byte)LogTypes.RELEASE, $"Created a new player entity {entityid} as id {globalId}", ConsoleColor.Yellow);
            } else {
                Helper.Say((byte)LogTypes.RELEASE, $"Created a new entity {entityid} as id {globalId}", ConsoleColor.Cyan);
            }
            
            id = globalId;
            this.isplayer = isplayer;
            this.entityid = entityid;
            Game.entities.Add(this);
        }

        public int id;
        public int health;

        public string entityid;
        
        public bool isplayer = false;

        public Vector3 position;
        public Vector3 rotation;
    }
}
