using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Networking {
    public static class MessageIds {
        public static int
            PlayerDisconnect = 0,
            PlayerRegister = 1,
            PlayerCFrame = 2,
            PlayerStateUpdate = 3,
            PlayerKnockback = 4,
            EntitySpawn = 5,
            EntityCFrame = 6,
            PlayerInput = 8,
            PlayerPickTalent = 10,
            GameStateChanged = 13, // this might work as one message in the future
            DamageRequest = 14,
            EntityAnimation = 15,
            PlayerChat = 16,
            SubjectPotionAdd = 17;
    }
}
