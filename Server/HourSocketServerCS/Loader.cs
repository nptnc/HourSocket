using HourSocketServerCS;
using HourSocketServerCS.Network;

Main.Start();
MessageHandler.RegisterMessages();

Server server = new Server();
server.Start();

while (true)
{
    server.Update();
}