#!/usr/bin/env python


"""
[+] Usage: python.exe pe_section_dump.py [input filename] [output filename]

    [input filename]    - Path to PE file whose .text section is to be extracted
    [output filename]   - Path to PIC file which will be saved to disk after extraction

    Example: python.exe pe_section_dump.py PIC.exe shellcode.bin
"""


import sys
import pip
import os


def install(package):
	if hasattr(pip, 'main'):
		pip.main(['install', package])
	else:
		pip._internal.main(['install', package])


try:
	import pefile
except:
	print("Missing pefile module.")
	install("pefile")
	os.execv(sys.executable, ['python'] + sys.argv)


def main():
	try:
		if len(sys.argv) == 3:
			inputfilename = sys.argv[1]
			outputfilename = sys.argv[2]
		else:
			raise
	except:
		print("Invalid args.")
		print(__doc__)
		sys.exit(0)

	pe = pefile.PE(inputfilename)
	text = pe.sections[0].get_data()
	file = open(outputfilename, "wb+")
	file.write(text)
	file.close()

	print("[+] Dumped .text section from PE file.")


if __name__ == '__main__':
	main()