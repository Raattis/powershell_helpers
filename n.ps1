param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$filename,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$line,
	
    [Parameter(Mandatory = $false)]
    [string]$exclude = "*\build\*",

    [Parameter(Mandatory = $false)]
    [string]$path = "."
)

$splitresults = $filename -split ":"
$filename = $splitresults[0]
if ($filename.length -eq 1)
{
	if ($splitresults[1] -like "/*" -or $splitresults[1] -like "\*")
	{
		$filename = $splitresults[0] + ":" + $splitresults[1]
		$splitresults[1] = $splitresults[2]
	}
}

if (-not [string]::IsNullOrWhiteSpace($splitresults[1])) {
	$line = $splitresults[1]
}

if (Test-Path $filename -PathType Leaf) {
	if (-not [string]::IsNullOrWhiteSpace($line)) {
		echo "Opening '$filename' at line $line"
		& "C:\Program Files (x86)\Notepad++\notepad++.exe" -n"$line" $filename
	} else {
		echo "Opening '$filename'"
		& "C:\Program Files (x86)\Notepad++\notepad++.exe" $filename
	}
} else {
	echo "'$filename' is not a file"
}