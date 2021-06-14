#!/usr/bin/python3

import sys
import os
import subprocess
import re

if len(sys.argv) != 4:
	print("Usage: python3 run_autoref_tests.py <tests directory> <autoref location> <replaycli binary>")
	exit(1)

def createLuaScript(jsonFile):
	def nameReplace(match):
		name = match[0].replace(" ", "").replace("\t", "").replace(":", "")
		# normalize to snake case
		name = re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()
		return "[" + name + "] ="

	with open(jsonFile, "r") as f:
		json = f.read()
		filtered = re.sub('".*"\\ *\\t*:', nameReplace, json)
		
		with open("init.lua", "w") as initScript:
			initScript.write('local Helper = require "autoreftesthelper"\n')
			initScript.write('return Helper.testEvent(' + filtered + ')')

exitCode = 0
numFailingTests = 0
for (dirPath, dirNames, fileNames) in os.walk(sys.argv[1]):
	containsStrategy = False
	for file in fileNames:
		if file.endswith(".log"):
			jsonFileName = file.replace(".log", ".json")
			if not jsonFileName in fileNames:
				print("No matching .json file found for log file " + file)
				numFailingTests += 1
				continue
			fullName = os.path.join(dirPath, file)
			fullJSONName = os.path.join(dirPath, jsonFileName)
			createLuaScript(fullJSONName)
			result = subprocess.run([sys.argv[3], "-t", "init.lua", fullName, sys.argv[2]], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
			if result.returncode != 0:
				print(str(result.stdout, "utf8"))
				print(str(result.stderr, "utf8"))
				print("Test \"" + dirPath + "/" + file + "\" failed with exit code " + str(result.returncode))
				numFailingTests += 1
os.remove("init.lua")
if numFailingTests == 0:
	print("All tests successfull!")
else:
	print(str(numFailingTests) + " testcase(s) failed!")
	exit(1)
