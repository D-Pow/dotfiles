#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os

class FileHierarchy:

    def __init__(self, directory=".", ignoreHidden=False, encodeAscii=False):
        self._dir = directory
        self._ignoreHidden = ignoreHidden
        if encodeAscii:
            self._branch = "+"
            self._trunk = "|"
            self._entry = "-"*3      #make each entry branch 3 units long
            self._end = "+"
            self._tab = " "*3
        else:                        #UTF-8
            self._branch = "├"
            self._trunk = "|"
            self._entry = "─"*3
            self._end = "└"
            self._tab = " "*3

    def printHierarchy(self):
        heirarchy = self._buildTree(self._dir)
        print("".join(heirarchy))

    def _buildTree(self, root, strArr=None, pre=""):
        """root = directory currently being searched in this recursive call
           strArr = array holding strings to be concatenated as output
           pre = prefix string showing how deep in the subfolders the item exists"""
        # First call initialization
        if strArr == None:
            strArr = [os.path.abspath(root) + "\n"]
        files = []
        dirs = []
        try:
            for item in os.listdir(root):
                # Make files appear after directories
                if os.path.isfile(root + "/" + item):  #isfile() requires full path
                    if not self._ignoreHidden or item[0] != ".":
                        files.append(item)
                else:
                    if not self._ignoreHidden or item[0] != ".":
                        dirs.append(item)
            for folder in dirs:
                # Make middle or end version of branch
                if folder == dirs[-1] and not files:   #last folder in the directory
                    branch = self._end + self._entry
                    # Last directory in current folder, so don't include
                    # trunk character
                    childPre = pre + " " + self._tab
                else:
                    branch = self._branch + self._entry
                    childPre = pre + self._trunk + self._tab
                strArr.append(pre + branch + folder + "/\n")
                self._buildTree(root + "/" + folder, strArr, childPre)
            for file in files:
                if file == files[-1]:   #last file
                    branch = self._end + self._entry
                else:
                    branch = self._branch + self._entry
                fileString = pre + branch + file + "\n"
                strArr.append(fileString)
        # Case where we don't have permission to view the file
        except (OSError, WindowsError) as e:
            pass
        return strArr


def printUsage():
    print("Usage: python PrintFileHeirarchy.py [-i, -a] <path>")
    print("-i: ignore hidden files/folders")
    print("-a: encode in ASCII instead of UTF-8")
    exit()

if __name__ == "__main__":
    import sys
    options = ['-i', '-a']
    ignoreHidden = False
    encodeAscii = False
    if len(sys.argv) < 2 or len(sys.argv) > 4:
        printUsage()
    for entry in sys.argv:
        if entry[0] == '-' and entry not in options:
            printUsage()
        if entry == '-i':
            ignoreHidden = True
        elif entry == '-a':
            encodeAscii = True
        else:
            path = entry
    heirarchy = FileHierarchy(path, ignoreHidden, encodeAscii)
    heirarchy.printHierarchy()
