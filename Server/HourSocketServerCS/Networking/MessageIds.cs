using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Networking {
    public static class MessageIds {
        public static int
            PlayerDisconnect = 0,
            PlayerUpdate = 1,
            PlayerCFrame = 2,
            PlayerStateUpdate = 3,
            PlayerInput = 8,
            SubjectPotionAdd = 17;
    }
}
