﻿using HourSocketServerCS.Extensions;
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

namespace HourSocketServerCS.Networking.Messages
{
    public class EntityCFrameMessage : Message
    {
        public override int Index() => MessageIds.EntityCFrame;

        public override void Handle(Player player, string data)
        {
            if (!player.hasRegistered || !player.isHost)
                return;

            Reader reader = new(data);
            string entityNetworkId = reader.ReadUntilSeperator();
            string position = reader.ReadUntilSeperator();
            string rotation = reader.ReadUntilSeperator();

            Entity? entity = Game.GetEntityByNetworkId(entityNetworkId);
            if (entity == null)
                return;

            entity.position = position.NetVector3();
            entity.rotation = rotation.NetVector3();

            // send this player to everyone except the player.
            string contents = Networker.PrepareForLua(Index(), entityNetworkId, position, rotation);
            Networker.SendToAll(contents, new Player[] { player });
        }
    }
}
