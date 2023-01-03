#!/usr/bin/env python


"""
[+] Usage: python.exe bin_to_shc.py [input filename] [-c (optional)]

    [input filename]    - Path to PIC file whose contents will be displayed as either byte array literal or C-style string literal
    [-c (optional)]     - Optional argument to override default display mode of byte array literal to C-style string literal

    Example: python.exe bin_to_shc.py shellcode.bin -c
"""


import sys
import binascii
import re


def main():
	try:
		if len(sys.argv) > 1:
			inputfilename = sys.argv[1]
		else:
			raise
	except:
		print("Invalid args.")
		print(__doc__)
		sys.exit(0)

	try:
		file = open(inputfilename, "rb")
		data = binascii.b2a_hex(file.read().rstrip(b'\0')).decode()
	except:
		print("Error reading %s" % inputfilename)
		sys.exit(0)

	if "-c" in sys.argv:
		print("\\x" + "\\x".join(re.findall("..", data)))
	else:
		print("0x" + ", 0x".join(re.findall("..", data)))

	file.close()


if __name__ == '__main__':
	main()