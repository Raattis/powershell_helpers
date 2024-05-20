param (
	[Parameter(Position = 0, Mandatory = $false)]
	[int]$open = -1
)

$prev_run = Get-History | Where-Object{ $_.CommandLine -like "git show*" -or $_.CommandLine -like "git diff*" -or $_.CommandLine -like "git st*" } | Select-Object -Last 1 | foreach { $_.CommandLine }

if ([string]::IsNullOrWhiteSpace($prev_run)) {
	echo "Nothing to run"
	exit 0
}

Invoke-Expression "python C:\Users\riku.rajaniemi\Documents\KOODAUS\powershell\my_bin\run_and_open.py $open $prev_run"
