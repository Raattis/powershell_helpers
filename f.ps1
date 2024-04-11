param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$filter = "*",

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$pattern,
	
    [Parameter(Mandatory = $false)]
    [string[]]$exclude = @("*\.git\*", "*\build\*", "*\.vs\*"),

    [Parameter(Mandatory = $false)]
    [string]$path = "."
)

$exclude_root = foreach($ex in $exclude) { $ex -replace "\*\\" -replace "\\\*" }
$paths = ls $path -force -exclude $exclude_root
$items = foreach ($p in $paths) {
	if (Test-Path $p -PathType Leaf) {
		if ([string]::IsNullOrWhiteSpace($filter) -or $p -like $filter) {
			$p
		}
	} else {
		ls $p -force -r -filter $filter -exclude $exclude
	}
}

$items = $items | where-object{ Test-Path $_.fullname -PathType Leaf}
foreach ($excl in $exclude) {
	$items = $items | where-object{ $_.fullname -notlike $excl }
}

if (-not [string]::IsNullOrWhiteSpace($pattern)) {
	$items | sls $pattern | foreach { echo $_ }
} else {
	$items | foreach { $_.fullname }
}
