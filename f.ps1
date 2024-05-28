<#
	.SYNOPSIS
	Find files by name and content.

	.DESCRIPTION
f	Lists all files recursive starting from the current working directory.
	Some folders are excluded from the search by default (such as .git, .vs and build). See $default_excludes in the source for the full list.
	Use -ndx/-no_default_excludes to disable this behavior

f -x Debug,Release
	To exclude more folders

f -p ../other/path
	Changes the search root

f hi
	Filter files by substrings (automatically expands to *hi*)

f .cpp
	Filter files by extension (automatically expands to *.cpp)

f .cpp,.h
	Filter supports comma-separated lists

f *test*.cpp
	Filter supports wildcards

f *
	Matches every file

f .cpp hello
	Find every .cpp file containing hello and output every hit line

f .cpp hello.*world
	Content search uses regex (not wildcards)

f * "hello|hiya"
f * hello`|hiya
f * `"hello
f * "`"hello"
	Remember to (") quote and/or (`) escape any special characters

f .cpp hello.*world -open 1
	Open the first hit at the correct line

f -pf \my_project\,\my_tests\
	Filter based on full path

help f -detailed
help f -full
	For more info on parameters

	.LINK
	Repo: https://github.com/Raattis/powershell_helpers
#>

param (
	[Alias("filter")]
	[Parameter(Position = 0, Mandatory = $false)]
	[string[]]
	# Filename filter (supports wildcards and comma-separated list)
	$filters = @("*"),

	[Parameter(Position = 1, Mandatory = $false)]
	[string]
	# Match patterns in file contents (uses regex, use backtick (`) to escape quotes ("))
	$pattern,

	[Alias("ndx")]
	[Parameter(Mandatory = $false)]
	[switch]
	# Disable default excludes (*\.git\*, *\build\*, *\.vs\*, *\__pycache__\*, *\.*cache*\*)
	$no_default_excludes,

	[Alias("x", "exclude")]
	[Parameter(Mandatory = $false)]
	[string[]]
	# Exclude some directories manually (f.ex. "*\Debug\*,*\Release\*")
	$user_excludes = @(),

	[Alias("p")]
	[Parameter(Mandatory = $false)]
	[string]
	# Set the root path (defaults to current working directory)
	$path = ".",

	[Alias("i")]
	[Parameter(Mandatory = $false)]
	[bool]
	# Show indices in results, on by default. -index:0 to disable
	$index = $true,

	[Alias("o")]
	[Parameter(Mandatory = $false)]
	[int]
	# Open the nth result in Notepad++
	$open = 0,

	[Alias("pf")]
	[Parameter(Mandatory = $false)]
	[string[]]
	# Filter that matches the path. Use comma-separated list for a logical or filter
	$path_filters = @(),

	[Alias("c", "fc")]
	[Parameter(Mandatory = $false)]
	[switch]
	# Make content search case sensitive
	$case_sensitive_pattern,

	[Alias("pfc")]
	[Parameter(Mandatory = $false)]
	[switch]
	# Make file path matching case sensitive
	$case_sensitive_path_filter,

	[Alias("nfc")]
	[Parameter(Mandatory = $false)]
	[switch]
	# Make file name matching case sensitive
	$case_sensitive_name_filter
)

function Progress {
	param (
		$item
	)
	$length = $item.fullname.Length
	$width = $Host.UI.RawUI.WindowSize.Width - 25
	if ($length -gt $width) {
		write-host -NoNewline "Current position $($item.fullname.substring($length - $width, $width))...`r"
	} else{
		$empty_tail = " " * ($width - $length + 3)
		write-host -NoNewline "Current position $($item.fullname)$empty_tail`r"
	}
}

function ClearProgress {
	write-host -NoNewline "`r$(" " * $Host.UI.RawUI.WindowSize.Width)`r"
}

function OpenAtLine {
	param (
		[string]$line
	)

	$parts = $line -split ":"
	$filename = ""
	$line = ""
	if ($parts[1] -like "\*") {
		$filename = $parts[0] + ":" + $parts[1]
		$line = $parts[2]
	} else {
		$filename = $parts[0]
		$line = $parts[1]
	}
	$args = $filename + ":" + $line
	& "e" $args
}

function OpenFile {
	param (
		[string]$filepath
	)
	& "e" $filepath
}

$global:old = @{}
$name_like_operator = if ($case_sensitive_name_filter) { { param($a, $b) $a -clike $b } }else { { param($a, $b) $a -ilike $b } }
$pf_like_operator = if ($case_sensitive_path_filter) { { param($a, $b) $a -clike $b } }else { { param($a, $b) $a -ilike $b } }

function Output {
	param ($item)
	if ([string]::IsNullOrWhiteSpace($item)) {
		return
	}

	Progress($item)

	if (-not (&$name_like_operator $item.name $filter)) {
		return
	}

	foreach ($excl in $combined_excludes) {
		if ($item.fullname -like $excl) {
			#echo "excluded: $item"
			return
		}
	}

	$pf_ok = $path_filters.Length -eq 0
	foreach ($pf in $path_filters) {
		if (&$pf_like_operator $item.fullname $pf) {
			$pf_ok = $true
			break
		}
	}
	if (-not $pf_ok) {
		#echo "pf fail: $item"
		return
	}

	if ($global:old.ContainsKey($item.fullname)) {
		#echo "old: $item.fullname"
		return
	}
	$global:old.Add($item.fullname, 1)

	if (-not [string]::IsNullOrWhiteSpace($pattern)) {
		$old_hits = $global:hits
		if ($index -or ($open -ne 0)){
			$item | sls $pattern -CaseSensitive:$case_sensitive_pattern | foreach {
				ClearProgress
				$global:hits += 1
				echo "[$($global:hits)] $_"
				if ($open -eq $global:hits) {
					OpenAtLine($_)
				}
			}
		} else {
			$item | sls $pattern -CaseSensitive:$case_sensitive_pattern | foreach {
				ClearProgress
				$global:hits += 1
				echo "$_"
			}
		}
		if ($old_hits -lt $global:hits) {
			$global:files += 1
		}
	} elseif (-not $recurse) {
		ClearProgress
		$global:files += 1
		if ($open -eq 0) {
			write-host -NoNewline "[$($global:files)] "
			$item | cat
		} else {
			OpenAtLine($item.fullname + ":" + $open)
		}
	} else {
		if ($index -or ($open -ne 0)) {
			$item | foreach {
				ClearProgress
				$global:files += 1
				echo "[$($global:files)] $_"
				if ($open -eq $global:files) {
					OpenFile($_)
				}
			}
		} else {
			$item | foreach {
				if (-not [string]::IsNullOrWhiteSpace($_)) {
					ClearProgress
					$global:files += 1
					echo "$_"
				}
			}
		}
	}
}

##############################################################################

$path = $path.TrimEnd(@("\", "/"))

for (($i = 0); $i -lt $path_filters.Length; $i++) {
	if ($path_filters[$i] -notmatch ".*\*.*") {
		$path_filters[$i] = "*" + $path_filters[$i] + "*"
	}
}

$global:hits = 0
$global:files = 0

$default_excludes = @("*\.git\*", "*\build\*", "*\.vs\*", "*\__pycache__\*", "*\.*cache*\*")
$combined_excludes = $default_excludes + $user_excludes

if ($no_default_excludes) {
	$combined_excludes = @("dummy_exclude_value") + $user_excludes
}

$recurses = @($true) * $filters.Length

for (($i = 0); $i -lt $filters.Length; $i++)
{
	$filter = $filters[$i]
	$exact = $false

	if (($filter -match ".*[\\/].*")) {
		# filter is a path
		$filter_file = $path + "\" + $filter.TrimStart(".\").TrimEnd("./").TrimEnd("!")
		if ((split-path -leaf $filter) -match ".*[*!].*") {
			# filter:".\path\to\*.ext"
			$path = split-path -parent $filter_file
			if (-not (Test-Path $path -PathType Container)) {
				Write-Error -Message "ERROR: '$path' isn't a folder." -Category InvalidArgument
				exit 1
			}
			$filter = split-path -leaf $filter
		}
		elseif (Test-Path $filter_file -PathType Leaf) {
			# filter:".\path\to\file.ext"
			$recurses[$i] = $false
			$exact = $true
			$path = split-path -parent $filter_file
			$filter = split-path -leaf $filter
		}
		elseif (Test-Path $filter_file -PathType Container) {
			# filter:".\path\to\"
			$path = $filter_file
			$filter = "*"
		}
		else {
			Write-Error -Message "ERROR: '$filter_file' doesn't exist." -Category InvalidArgument
			exit 1
		}
	}

	if (($filter -like "*!") -or ($filter -like ("*" + [wildcardpattern]::Escape("*") + "*"))) {
		# filter contains a * or ends in !, so treat it as a non-substring search
		$filter = $filter -replace "!"
	} elseif (-not $exact) {
		if ($filter -like ".*" -and $filter -ne ".") {
			# extension filter
			$filter = "*" + $filter
		} else {
			# the default filter is a substring search
			$filter = "*" + $filter + "*"
		}
	}

	if (-not [string]::IsNullOrWhiteSpace($pattern)) {
		if ($recurses[$i]) {
			echo "Finding '$pattern' in files matching '$filter' under '$(Resolve-Path $path)'."
		} else {
			echo "Finding '$pattern' in '$(Resolve-Path $path)\$filter'."
		}
	} elseif ($recurses[$i]) {
		echo "Searching for files matching '$filter' under '$(Resolve-Path $path)'."
	} else {
		#echo "Splatting '$path\$filter'"
	}
	$filters[$i] = $filter
}

$exclude_root = foreach($ex in $combined_excludes) { $ex -replace "\*\\" -replace "\\\*" }
$paths = ls $path -force -exclude $exclude_root

for (($i = 0); $i -lt $filters.Length; $i++)
{
	$filter = $filters[$i]
	$recurse = $recurses[$i]
	foreach ($p in $paths) {
		if (Test-Path $p -PathType Leaf) {
			if ((-not [string]::IsNullOrWhiteSpace($filter)) -and (&$name_like_operator (split-path -leaf $p) $filter)) {
				Output($p)
			}
		} else {
			Progress($p)
			ls $p -force -Recurse:$recurse -filter $filter -exclude $combined_excludes -file | foreach { Output($_) }
		}
	}
}

ClearProgress
if ($recurse -or $filters.Length -gt 1) {
	if ([string]::IsNullOrWhiteSpace($pattern)) {
		echo "Matched $global:files files"
	} else {
		echo "Found $global:hits hits in $global:files files"
	}
}
