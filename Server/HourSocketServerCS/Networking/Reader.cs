using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HourSocketServerCS.Networking {
    public class Reader {
        private string stringToRead;
        private int offset;

        public Reader(string stringToRead) {
            this.stringToRead = stringToRead;
        }

        public string ReadAll() {
            string readString = "";
            for (int i = offset; i < stringToRead.Length; i++) {
                string letter = stringToRead[i].ToString();
                readString += letter;
            }
            return readString;
        }

        public string? ReadUntilSeperator() {
            if (offset > stringToRead.Length) {
                return null;
            }

            string readString = "";
            string lastCharacters = "";
            for (int i = offset; i < stringToRead.Length; i++) {
                string letter = stringToRead[i].ToString();
                readString += letter;
                offset++;
                if (lastCharacters.Length >= ServerSettings.Lua.seperator.Length) {
                    string newString = "";
                    int index = 0;
                    foreach (char oldLetter in lastCharacters) {
                        if (index == 0) {
                            index++;
                            continue;
                        }
                        string oldLetterString = oldLetter.ToString();
                        newString += oldLetterString;
                        index++;
                    }
                    newString += letter;
                    lastCharacters = newString;
                } else {
                    lastCharacters += letter;
                }
                if (lastCharacters == ServerSettings.Lua.seperator) {
                    string newString = "";
                    int index = 0;
                    foreach (char oldLetter in readString) {
                        if (index >= readString.Length-lastCharacters.Length) {
                            index++;
                            continue;
                        }
                        string oldLetterString = oldLetter.ToString();
                        newString += oldLetterString;
                        index++;
                    }
                    readString = newString;
                    break;
                }
            }
            return readString;
        }
    }
}
