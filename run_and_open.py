import os, sys, subprocess, re, time

open_index = int(sys.argv[1])

cmd = sys.argv[2]
args = sys.argv[3:]

def get_file():
	_cmd = cmd + ' ' + ' '.join(args)
	print(f"Re-running '{_cmd}' and scanning the output for files, to run the {open_index}th one.")
	output = subprocess.check_output(_cmd).decode('utf-8')

	if not output or not output.strip():
		print("Output was empty")
		exit(1)

	print(output)

	def diff_show(output):
		results = []
		try:
			header = None
			lno = -1
			for line in output.split("\n"):
				if line.startswith("+++ "):
					header = line[line.index("/")+1:]
				elif line.startswith("@@ "):
					l = line.split("@@")[1]
					lno = int(l.split("+")[1].split(",")[0])
				elif lno != -1:
					if line.startswith("-") or line.startswith("+"):
						results.append((header, lno, line))
						lno = -1
					else:
						lno += 1
		except:
			pass
		return results

	expressions = [
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
					print(f"{'>' if open_index-1 == i else ' '}{i+1}: {matches[i][0]}:{matches[i][1]} - {matches[i][2]}")

			if open_index >= 1 and open_index - 1 < len(matches):
				if isinstance(matches[open_index - 1], str):
					result = matches[open_index - 1], "0"
				else:
					result = matches[open_index - 1][:2]
			if result:
				return result
			exit(0)

	print(output, "\n\nNo regexes matched the output")
	exit(1)

file, line = get_file()

cmd = 'cmd'
args = [cmd, "/C", '"C:\\Program Files (x86)\\Notepad++\\notepad++.exe"', f'-n{line}', file]
os.execvp(cmd, args)
