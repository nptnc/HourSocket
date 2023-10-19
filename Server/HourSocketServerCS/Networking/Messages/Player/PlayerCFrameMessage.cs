using HourSocketServerCS.Hours;
using HourSocketServerCS.Network;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;

namespace HourSocketServerCS.Networking.Messages
{
    public class PlayerCFrameMessage : Message
    {
        public override int Index() => MessageIds.PlayerCFrame;

        public override void Handle(Player player, string data)
        {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string position = reader.ReadUntilSeperator();
            string rotation = reader.ReadUntilSeperator();

            string contents2 = Networker.PrepareForLua(Index(), player.userId, position, rotation);
            Networker.SendToAll(contents2, new Player[] { player });
        }
    }
}