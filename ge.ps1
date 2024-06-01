param (
	[Parameter(Position = 0, Mandatory = $false)]
	[int]$open = -1
)

$regex = "^((git diff.*)|(git show.*)|(git st.*)|(gitd iff.*)|(gits t(atus)?))"

$prev_run = Get-History | Where-Object{ $_.CommandLine -match $regex } | Select-Object -Last 1 | foreach { $_.CommandLine }

if ([string]::IsNullOrWhiteSpace($prev_run)) {
	echo "Nothing to run"
	exit 0
}

$prev_run = $prev_run -replace "^git(.) (.*)", "git $1$2"

Invoke-Expression "python $PSScriptRoot\run_and_open.py $open $prev_run"
