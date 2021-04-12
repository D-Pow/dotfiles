#!/usr/bin/env python3
class PrettifyJson:

    def __init__(self, filename):
        self._filename = filename
        self._tab = "    "
        self._numtabs = 0

    def prettify(self):
        """Overwrites the JSON file specified in this PrettifyJson object
           and overwrites it with a formatted version"""
        with open(self._filename, 'r') as f:
            lines = f.readlines()
            newlines = []
            for line in lines:
                line = line.strip()
                newline = self._process(line)
                newlines.append(newline)
        self._writeFile(newlines)

    def _process(self, line):
        """Processes a single line from a file"""
        i = 0
        length = len(line)
        new = []
        instring = False  #JSON starts outside a string
        while i < length:
            #opening bracket = increase tab
            if line[i] == "{" or line[i] == "[":
                self._numtabs += 1
                t = self._tab*self._numtabs
                new.append(line[i] + '\n' + t)
            #closing bracket = decrease tab
            elif line[i] == "}" or line[i] == "]":
                self._numtabs -= 1
                t = self._tab*self._numtabs
                #don't include newline after bracket
                #because it will be included by comma
                new.append('\n' + t + line[i])
            #comma = add new line
            elif line[i] == ",":
                t = self._tab*self._numtabs
                new.append(line[i] + '\n' + t)
            #put only one space after colon
            elif line[i] == ":":
                j = i+1
                while line[j].isspace():
                    j += 1
                new.append(line[i] + " ")
                i = j-1 #i will be incremented later
            #other character = scan for content inside the string or pass over ints
            else:
                #skip over whitespace
                while line[i].isspace():
                    i += 1
                #get string
                if line[i] == "\"":
                    s, j = self._getString(line,i)
                    new.append(s)
                    i = j  #i will be incremented later
                #or int/bool/null
                elif "{[:,]}".count(line[i]) == 0:
                    new.append(line[i])
                #else, it's a special character
                else:
                    i -= 1 #i will be incremented later
            i += 1
        newline = "".join(new)
        return newline

    def _getString(self, line, i):
        """Parses `line` for an enclosing string starting at i.
           Requires that line[i] == '"'.
           Returns the string and the index of the closing quote."""
        #find closing quote
        j = i+1
        while line[j] != "\"":
            j += 1
            if line[j] == "\"":
                #make sure quote isn't escaped
                k = j-1
                count = 0
                while line[k] == "\\":
                    count += 1
                    k -= 1
                if count % 2 == 1:
                    #quote is escaped, so continue search
                    j += 1
        string = line[i:j+1]
        return (string, j)

    def _writeFile(self, newlines):
        """Overwrites the original file with the newly formatted lines"""
        with open(self._filename, 'w') as f:
            f.write("".join(newlines))


if __name__ == "__main__":
    import sys, os
    if len(sys.argv) != 2:
        print("Usage: python PrettifyJson.py <filename>")
    else:
        if os.path.isfile(sys.argv[1]):
            json = PrettifyJson(sys.argv[1])
            json.prettify()
        else:
            print("That file does not exist")
