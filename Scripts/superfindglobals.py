import sys
import os

import subprocess
import re
import threading
import ntpath
from collections import OrderedDict

arg1 = ""
toc = ""
if len(sys.argv) <= 1:
	arg1 = ""
else:
	arg1 = sys.argv[1]

if os.path.isfile(arg1) and arg1.endswith("toc"):
	toc = arg1
elif os.path.isdir(arg1):
	for name in os.listdir(arg1):
		if name.endswith("toc"):
			toc = os.path.join(arg1, name)
			break

if not toc:
	print("Couldn't find toc")
	print(arg1, toc)
	exit()





def scan_source(in_file, excluded_globals, flags):
	with open(in_file) as ifile:
		for line in ifile:
			globals = re.search(r'--\s*GLOBALS:\s*(.*)', line)
			if globals:
				excluded_globals.extend(re.findall(r'(\w+)', globals.group(1)))


			args = re.search(r'--\s*(SETGLOBALFILE|GETGLOBALFILE|SETGLOBALFUNC|GETGLOBALFUNC)\s+([A-Z]+)', line)
			if args:
				flags[args.group(1)] = args.group(2) == "ON"

def scan_bytecode(in_file, found_globals):
	try:
		startupinfo = subprocess.STARTUPINFO()
		startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

		bytecode = subprocess.check_output([r'luac-wow.exe', '-l', '-p', in_file], startupinfo=startupinfo, stderr=subprocess.STDOUT)
	except subprocess.CalledProcessError as e:
		print(e.output)
	else:
		bytecode = bytecode.decode()

		for line in bytecode.split("\n"):
			match = re.match("(function|main)", line)
			if match:
				found_globals.append((match.group(1),None,None,None,None))

			match = re.search(r'\[(\d+)\]\s+(.ETGLOBAL)\s+(\d+) ([\d-]+)\s+; (\w+)', line)
			if match:
				found_globals.append(match.groups())


def parse_lua_file(test_file):

	if not os.path.isfile(test_file):
		print("Missing file", test_file)
		return

	print("")
	print(test_file)

	excluded_globals = []
	found_globals = []

	flags = {
		"SETGLOBALFILE": True,
		"SETGLOBALFUNC": True,
		"GETGLOBALFILE": False,
		"GETGLOBALFUNC": True,
	}

	scan_bytecode_thread = threading.Thread(target=scan_bytecode, args=(test_file, found_globals))
	scan_bytecode_thread.start()

	scan_source_thread = threading.Thread(target=scan_source, args=(test_file, excluded_globals, flags))
	scan_source_thread.start()


	scan_bytecode_thread.join()
	scan_source_thread.join()

	file_name_base = ntpath.basename(test_file)


	funcScope = False

	reported_globals = []

	for linenum, op, start, end, name in found_globals:
		if linenum == "main" or linenum == "function":
			funcScope = linenum == "function"
		elif name not in excluded_globals:

			if (funcScope and flags[op + "FUNC"]) or (not funcScope and flags[op + "FILE"]):
				out = test_file + ":" + linenum + ": " + op[:3] + " " + name
				print(out)
				reported_globals.append(name)

	reported_globals = list(OrderedDict.fromkeys(reported_globals))


	# if len(reported_globals) > 0:
	# 	print("\nStrings to ignore these globals. Check them for bad globals before pasting:")

	# 	ignoreStr = "-- GLOBALS: "
	# 	for g in reported_globals:
	# 		ignoreStr += g + ", "
	# 		if len(ignoreStr) > 80:
	# 			print(ignoreStr[:-2])
	# 			ignoreStr = "-- GLOBALS: "

	# 	# Print out any that are remianing
	# 	print(ignoreStr[:-2])
	# else:
	# 	print("The file has no leaked, undeclared global variables.")



def parse_xml_file(xml_file):
	base_path = os.path.split(xml_file)[0]

	if not os.path.isfile(xml_file):
		print("Missing file", xml_file)
		return

	with open(xml_file, "r") as ifile:
		for line in ifile:
			match = re.match("<\s*Script\s*file\s*=\s*\"([^\"]+)\"", line)
			if match:
				parse_lua_file(os.path.join(base_path, match.group(1)))

			match = re.match("<\s*Include\s*file\s*=\s*\"([^\"]+)\"", line)
			if match:
				parse_xml_file(os.path.join(base_path, match.group(1)))

def parse_toc_file(toc_file):
	base_path = os.path.split(toc_file)[0]

	with open(toc_file, "r") as ifile:
		for line in ifile:
			line = line.strip()
			if not line.startswith("#"):
				if line.endswith(".lua"):
					parse_lua_file(os.path.join(base_path, line))
				elif line.endswith(".xml"):
					parse_xml_file(os.path.join(base_path, line))

parse_toc_file(toc)
