#!/usr/bin/env -S python3

"""
Removes photos downloaded from Drive that are the
same as the photos from the hard drive except with
the Drive versions replacing ' with _
i.e. hard drive's file is `funny's.jpg` and
     Drive's is `funny_s.jpg`,
     this will delete funny_s.jpg
"""

import glob, os, sys

if len(sys.argv) < 2:
    raise RuntimeError('Please specify a directory')

directory = sys.argv[1]
allFiles = glob.iglob(os.path.join(directory, "*"))
files, ufiles, afiles = [], {}, {}

for file in allFiles:
    files.append(file)

for file in files:
    if "_" in file and "'" not in file:
        ufiles[file.replace("_","")] = file
    elif "'" in file:
        afiles[file.replace("'","").replace("_","")] = file

for file in list(afiles.keys()):
    if file not in ufiles.keys():
        del afiles[file]

toDel = list(ufiles.values())

for file in toDel:
    os.remove(file)