param(
    [int]$Seconds = 8
)

$working = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $working "lavalink-test.log"
$err = Join-Path $working "lavalink-test.err"

Remove-Item $log -ErrorAction SilentlyContinue
Remove-Item $err -ErrorAction SilentlyContinue

$proc = Start-Process -FilePath "java" -ArgumentList "-jar","Lavalink.jar" -WorkingDirectory $working -RedirectStandardOutput $log -RedirectStandardError $err -PassThru

try {
    Start-Sleep -Seconds $Seconds
} finally {
    if ($proc -and !$proc.HasExited) {
        Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue
    }
}
