import sys, subprocess

command = sys.argv[1]
invocation = sys.argv[2]
start = len(command)
typo_length = invocation.find(" ") - start
prefix = invocation[start:start + typo_length]
args = prefix + invocation[start + typo_length + 1:]

print(f"Did you typo '{command} {args}'?")
subprocess.run([command] + args.split())
