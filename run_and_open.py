import os, sys, subprocess, re, time

open_index = int(sys.argv[1])
open_index = 1 if open_index < 1 else open_index

cmd = sys.argv[2]
args = sys.argv[3:]

def get_file():
	_cmd = cmd + ' ' + ' '.join(args)
	print(f"Re-running '{_cmd}' and scanning the output for files, to run the {open_index}th one.")
	output = subprocess.check_output(_cmd).decode('utf-8')
	print(output)
	
	def diff_show(output):
		results = []
		try:
			header = None
			for line in output.split("\n"):
				if line.startswith("+++ "):
					header = line[line.index("/")+1:]
				elif line.startswith("@@ "):
					l = line.split("@@")[1]
					lno = l[l.index("+")+1:l.rindex(",")]
					results.append((header, lno))
		except:
			pass
		return results

	expressions = [
			#("show/diff", "[+]{3} ./([^\r\n]*)\r?\n?@@ .*-.*\+(.*),"),
			("show/diff", diff_show),
			("status", "[ \t]+(?:modified|add|removed|missing):[ \t]+(.*)"),
		]

	for name, e in expressions:
		matches = None
		if isinstance(e, str):
			matches = re.findall(e, output)
		else:
			matches = e(output)
		if len(matches) > 0:
			result = None
			print(f"'{name}' regex produced {len(matches)} matches:")
			for i in range(len(matches)):
				if isinstance(matches[i], str):
					print(f"{'>' if open_index-1 == i else ' '}{i+1}: {matches[i]}")
				else:
					print(f"{'>' if open_index-1 == i else ' '}{i+1}: {matches[i][0]}:{matches[i][1]}")

			if open_index - 1 < len(matches):
				if isinstance(matches[open_index - 1], str):
					result = matches[open_index - 1], "0"
				else:
					result = matches[open_index - 1]
			if result:
				return result
			exit(1)
	print(f"No regexes matched the output")
	exit(1)

file, line = get_file()

cmd = 'cmd'
args = [cmd, "/C", '"C:\\Program Files (x86)\\Notepad++\\notepad++.exe"', f'-n{line}', file]
os.execvp(cmd, args)
