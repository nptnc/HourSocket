using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Extensions
{
    public static class BooleanExtension
    {
        public static string ToNetwork(this bool boolean) {
            return boolean.ToString().ToLower();
        }
    }
}
