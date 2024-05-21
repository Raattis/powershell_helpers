param(
	[string]$command,
	[string]$invocation
)

$start = $command.Length
$typo_length = $invocation.IndexOf(" ") - $start
$prefix = $invocation.Substring($start, $typo_length)
$args = $prefix + $invocation.Substring($start + $typo_length + 1)
echo "Did you mean: '$command $args'?"
& $command $args
