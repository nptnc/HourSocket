using HourSocketServerCS;
using HourSocketServerCS.Network;

Main.LoadSettings();
Main.Start();
MessageHandler.RegisterMessages();

Server server = new Server();
server.Start();

while (true)
{
    server.Update();
}