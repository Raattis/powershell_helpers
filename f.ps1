param (
	[Parameter(Position = 0, Mandatory = $false)]
	[string]$filter = "*",

	[Parameter(Position = 1, Mandatory = $false)]
	[string]$pattern,

	[Parameter(Mandatory = $false)]
	[string[]]$exclude = @("*\.git\*", "*\build\*", "*\.vs\*", "*\__pycache__\*"),

	[Parameter(Mandatory = $false)]
	[string]$path = ".",

	[Parameter(Mandatory = $false)]
	[switch]$index,

	[Parameter(Mandatory = $false)]
	[int]$open = 0
)

$path = $path.TrimEnd(@("\", "/"))

$recurse = $true
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
		$recurse = $false
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
	# the default filter is a substring search
	$filter = "*" + $filter + "*"
}

if (-not [string]::IsNullOrWhiteSpace($pattern)) {
	if ($recurse) {
		echo "Finding '$pattern' in files matching '$filter' under '$(Resolve-Path $path)'."
	} else {
		echo "Finding '$pattern' in '$path\$filter'."
	}
} elseif ($recurse) {
	echo "Searching for files matching '$filter' under '$path'."
} else {
	#echo "Splatting '$path\$filter'"
}


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

$global:hits = 0
$global:files = 0

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

function Output {
	param (
		$item
	)
	foreach ($excl in $exclude) {
		if ($item.fullname -like $excl) {
			return
		}
	}
	Progress($item)

	if (-not [string]::IsNullOrWhiteSpace($pattern)) {
		$old_hits = $global:hits
		if ($index -or ($open -ne 0)){
			$item | sls $pattern | foreach {
				ClearProgress
				$global:hits += 1
				echo "[$($global:hits)] $_"
				if ($open -eq $global:hits) {
					OpenAtLine($_)
				}
			}
		} else {
			$item | sls $pattern | foreach {
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
		$item | cat
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
				ClearProgress
				$global:files += 1
				echo "$_"
			}
		}
	}
}

$exclude_root = foreach($ex in $exclude) { $ex -replace "\*\\" -replace "\\\*" }
$paths = ls $path -force -exclude $exclude_root
foreach ($p in $paths) {
	if (Test-Path $p -PathType Leaf) {
		if ([string]::IsNullOrWhiteSpace($filter) -or ((split-path -leaf $p) -like $filter)) {
			Output($p)
		}
	} else {
		Progress($p)
		ls $p -force -Recurse:$recurse -filter $filter -exclude $exclude -file | foreach { Output $_ }
	}
}

ClearProgress
if ($recurse) {
	if ([string]::IsNullOrWhiteSpace($pattern)) {
		echo "Matched $global:files files"
	} else {
		echo "Found $global:hits hits in $global:files files"
	}
}