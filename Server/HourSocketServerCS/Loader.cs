using HourSocketServerCS;
using HourSocketServerCS.Hours;
using HourSocketServerCS.Network;

Main.LoadSettings();
Main.Start();
Game.Start();
MessageHandler.RegisterMessages(); // register network messages from assembly

Server server = new Server();
server.Start();

while (true) {
    server.Update();
}