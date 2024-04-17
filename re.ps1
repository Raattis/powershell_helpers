param (
	[Parameter(Position = 0, Mandatory = $false)]
	[int]$open = -1
)

$prev_run = Get-History | Where-Object{ $_.CommandLine -like "f *" -or $_.CommandLine -eq "f" } | Select-Object -Last 1 | foreach { $_.CommandLine }

if ([string]::IsNullOrWhiteSpace($prev_run)) {
	$prev_run = "f -open 1"
} elseif ($open -lt 1) {
	if (($prev_run -like "f *-open *") -or ($prev_run -like "f *-o *")) {
		# nop
	} else {
		$prev_run = $prev_run + " -open 1"
	}
} else {
	$prev_run = $prev_run -replace " -open +[0-9]+", " "
	$prev_run = $prev_run + " -open $open"
}

echo "> $prev_run"
Invoke-Expression $prev_run