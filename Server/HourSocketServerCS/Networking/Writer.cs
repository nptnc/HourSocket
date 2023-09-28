using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Network {
    public class Writer {
        public List<byte> bytes = new();

        public byte[] Create() {
            return bytes.ToArray();
        }

        public void Write(byte aaaa) {
            bytes.Append(aaaa);
        }

        public void Write(byte[] bytes) {
            foreach (byte b in bytes) {
                bytes.Append(b);
            }
        }

        public void Write(string str) {
            Write(Encoding.ASCII.GetBytes(str));
        }

        public void Write(Vector3 v3) {
            string interpretableVector3 = $"{v3.X}_{v3.Y}_{v3.Z}";
            Write(interpretableVector3);
        }
    }
}
