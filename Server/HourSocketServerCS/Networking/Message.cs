using HourSocketServerCS.Hours;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Network
{
    public class Message
    {
        public virtual int Index() {
            return 0;
        }

        public virtual void Handle(Player player, string data) { }
    }
}
