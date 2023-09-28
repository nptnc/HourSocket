using HourSocketServerCS.Hours;
using HourSocketServerCS.Networking;
using HourSocketServerCS.Util;

namespace HourSocketServerCS.Network.Messages {
    public class PlayerCFrameMessage : Message {
        public override int Index() => MessageIds.PlayerCFrame;

        public override void Handle(Player player, string data) {
            if (!player.hasRegistered)
                return;

            Reader reader = new(data);
            string position = reader.ReadUntilSeperator();
            string rotation = reader.ReadUntilSeperator();

            string contents2 = Networker.PrepareForLua(Index(), player.id.ToString(), position, rotation);
            Networker.SendToAll(contents2, new Player[] { player });
        }
    }
}