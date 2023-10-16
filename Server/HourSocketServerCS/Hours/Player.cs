using Fleck;
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
    public class Player {
        public static int globalId;

        public int id;

        // this is for their connection, we use this to identify their connection
        public int connection;
        public IWebSocketConnection socket;

        public bool isHost = false;
        public bool hasRegistered {
            get;
            protected set;
        }

        // these are for when the player registers.
        public Entity? entity;

        public Vector3 cameraPos;
        public Vector3 cameraRot;

        public string? username = null;
        public string? playerclass;

        public bool? pickedTalent;
        public int pickedTalentIndex;

        public Player(int connection, IWebSocketConnection socket) {
            globalId++;
            id = globalId;

            this.connection = connection;
            this.socket = socket;
            isHost = id == 1;

            PlayerHandler.RegisterPlayer(this);
        }

        public void OnRegister(string username, string playerclass, Vector3 position, Vector3 rotation) {
            if (hasRegistered)
                return;
            hasRegistered = true;

            entity = new(playerclass, 1, true, false);

            this.username = username;
            this.playerclass = playerclass;
            entity.position = position;
            entity.rotation = rotation;
            Helper.Say((byte)LogTypes.INFO, $"player {id} has registered as {username}");
        }
    }
}
