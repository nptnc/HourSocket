using HourSocketServerCS.Extensions;
using HourSocketServerCS.Hours;
using HourSocketServerCS.Network;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace HourSocketServerCS.Networking.Messages {
    /// <summary>
    /// we have EntityInputMessage and EntityAnimationMessage, this caused host entities (not players.) to not work correctly
    /// </summary>
    public class EntityAnimationMessage : Message {
        public override int Index() => MessageIds.EntityAnimation;

        public override void Handle(Player player, string data) {
            if (!player.hasRegistered || !player.isHost)
                return;

            Reader reader = new(data);
            string entityId = reader.ReadUntilSeperator();
            string someIndex = reader.ReadUntilSeperator();
            string animationName = reader.ReadUntilSeperator();

            Entity? entity = Game.GetEntityByNetworkId(entityId.NetInt());
            if (entity == null)
                return;

            // send this player to everyone except the player.
            string contents = Networker.PrepareForLua(Index(), entityId, someIndex, entityId);
            Networker.SendToAll(contents, new Player[] { player });
        }
    }
}
