using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Numerics;
using System.Threading.Tasks;

namespace HourSocketServerCS.Extensions {
    public static class Vector3Extension {
        public static string ToNetwork(this Vector3 v3) {
            return $"{v3.X}_{v3.Y}_{v3.Z}";
        }
    }
}
