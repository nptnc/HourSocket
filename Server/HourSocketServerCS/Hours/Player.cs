using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Sockets;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Hours {
    public class Player
    {
        private static int globalId;

        public Guid clientGuid;

        public bool hasRegistered {
            get;
            protected set;
        }

        // these are for when the player registers.
        public Entity? entity;

        public string? username;
        public string? playerclass;

        public int id;
        public bool isHost = false;

        public Player(Guid clientGuid) {
            globalId++;
            id = globalId;

            this.clientGuid = clientGuid;
            isHost = id == 1;

            PlayerHandler.RegisterPlayer(this);
        }

        public void OnRegister(string username, string playerclass, Vector3 position, Vector3 rotation) {
            if (hasRegistered)
                return;
            hasRegistered = true;

            entity = new(playerclass, true);

            this.username = username;
            this.playerclass = playerclass;
            entity.position = position;
            entity.rotation = rotation;
        }
    }
}
