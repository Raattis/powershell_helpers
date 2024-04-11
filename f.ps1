param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$filter = "*",

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$pattern,
	
    [Parameter(Mandatory = $false)]
    [string]$exclude = "*\build\*",

    [Parameter(Mandatory = $false)]
    [string]$path = "."
)

if (-not [string]::IsNullOrWhiteSpace($pattern)) {
	ls $path -r $filter | ?{ $_.fullname -notlike $exclude } | sls $pattern
} else {
	ls $path -r $filter | ?{ $_.fullname -notlike $exclude } | select fullname | foreach { $_.fullname }
}