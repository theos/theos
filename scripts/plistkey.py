#!/usr/bin/env python
import plistlib, sys

if len(sys.argv) < 4:
	print 'Syntax:', sys.argv[0], 'plist key value'
	sys.exit(1)

filename = sys.argv[1]
key = sys.argv[2]
value = sys.argv[3]
maindict = plistlib.readPlist(filename)
maindict[key] = value
plistlib.writePlist(maindict, filename)
