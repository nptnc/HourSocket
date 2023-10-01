using HourSocketServerCS;
using HourSocketServerCS.Hours;
using HourSocketServerCS.Network;

try {
    Main.LoadSettings();
    Main.Start();
    Game.Start();
    MessageHandler.RegisterMessages(); // register network messages from assembly

    Server server = new Server();
    server.Start();

    while (true) {
        server.Update();
    }
} catch(Exception exc) {
    Console.WriteLine($"Fucking caught error lmao!!!!! {exc.ToString()}");
    while (true) { }
}