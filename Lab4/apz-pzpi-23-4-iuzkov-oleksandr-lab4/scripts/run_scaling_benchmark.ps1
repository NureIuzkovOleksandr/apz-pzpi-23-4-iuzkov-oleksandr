param(
    [int]$Users = 50,
    [int]$SpawnRate = 10,
    [string]$Duration = "60s",
    [string]$HostUrl = "http://127.0.0.1:80"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptRoot\.." | Select-Object -ExpandProperty Path
$resultsDir = Join-Path $RepoRoot "locust\results"
$locustFile = Join-Path $RepoRoot "locust\locustfile.py"
$deployment = "backend"
$replicaCounts = @(1, 2, 4)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

function Log { param([string]$Msg) Write-Host "[BENCH] $Msg" -ForegroundColor Cyan }
function Separator { Write-Host ("=" * 70) -ForegroundColor DarkGray }

if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
}

$hpaFile = Join-Path $RepoRoot "k8s/hpa.yaml"
$hpaDeleted = $false
if (Get-Command "kubectl" -ErrorAction SilentlyContinue) {
    Log "Checking for active HPA..."
    $hpaExists = & kubectl get hpa backend-hpa 2>$null
    if ($hpaExists) {
        Log "Temporarily deleting HPA to prevent autoscaling conflicts during benchmark..."
        & kubectl delete hpa backend-hpa 2>$null | Out-Null
        $hpaDeleted = $true
    }
}


function Wait-ForPods {
    param([int]$Expected)
    Log "Waiting for $Expected pod(s) to be Ready..."
    $maxWait = 120
    $elapsed = 0
    while ($elapsed -lt $maxWait) {
        $readyCount = (kubectl get pods -l app=backend --no-headers 2>$null |
            Where-Object { $_ -match '1/1\s+Running' } | Measure-Object).Count
        if ($readyCount -ge $Expected) {
            Write-Host "  All $Expected pod(s) ready." -ForegroundColor Green
            return $true
        }
        Write-Host "  $readyCount/$Expected ready, waiting..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        $elapsed += 5
    }
    Write-Host "  WARNING: Timeout waiting for pods" -ForegroundColor Red
    return $false
}

function Wait-ForHealth {
    Log "Checking health endpoint..."
    for ($i = 0; $i -lt 20; $i++) {
        try {
            $r = Invoke-RestMethod -Uri "$HostUrl/health" -TimeoutSec 5
            if ($r.status -eq "healthy") {
                Write-Host "  Health OK" -ForegroundColor Green
                return $true
            }
        } catch { }
        Start-Sleep -Seconds 2
    }
    Write-Host "  WARNING: Health check failed" -ForegroundColor Red
    return $false
}

Separator
Log "SCALING BENCHMARK"
Log "Users: $Users | SpawnRate: $SpawnRate | Duration: $Duration"
Log "Host: $HostUrl"
$repList = $replicaCounts -join ", "
Log "Replica counts to test: $repList"
Separator

$summaryFile = Join-Path $resultsDir "benchmark_summary_$timestamp.txt"
$summaryLines = @()
$summaryLines += "=" * 70
$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$summaryLines += "SCALING BENCHMARK RESULTS - $dateStr"
$summaryLines += "Users: $Users | SpawnRate: $SpawnRate | Duration: $Duration"
$summaryLines += "=" * 70
$summaryLines += ""

foreach ($replicas in $replicaCounts) {
    Separator
    Log "TEST: $replicas replica(s)"
    Separator

    Log "Scaling deployment to $replicas replica(s)..."
    kubectl scale deployment/$deployment --replicas=$replicas 2>&1 | Out-Null
    Log "Performing rollout restart to ensure fresh pods for load balancing..."
    kubectl rollout restart deployment/$deployment 2>&1 | Out-Null
    kubectl rollout status deployment/$deployment --timeout=120s 2>&1 | Out-Null
    Wait-ForPods -Expected $replicas
    Start-Sleep -Seconds 5
    Wait-ForHealth

    $podsBefore = kubectl get pods -l app=backend -o wide 2>&1
    Write-Host "  Pods:" -ForegroundColor Yellow
    $podsBefore | ForEach-Object { Write-Host "    $_" }

    $csvPrefix = Join-Path $env:TEMP "locust_${replicas}rep_${timestamp}"
    Log "Running Locust (headless)..."

    $locustArgs = @(
        "-f", $locustFile,
        "--headless",
        "-u", $Users.ToString(),
        "-r", $SpawnRate.ToString(),
        "-t", $Duration,
        "--host", $HostUrl,
        "--csv", $csvPrefix
    )

    $stdoutFile = "${csvPrefix}_stdout.txt"
    $stderrFile = "${csvPrefix}_stderr.txt"

    $proc = Start-Process -FilePath "locust" -ArgumentList $locustArgs `
        -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutFile `
        -RedirectStandardError $stderrFile

    if ($proc.ExitCode -eq 0) {
        Write-Host "  Locust exit code: $($proc.ExitCode)" -ForegroundColor Green
    } else {
        Write-Host "  Locust exit code: $($proc.ExitCode)" -ForegroundColor Red
    }

    $statsFile = "${csvPrefix}_stats.csv"
    if (Test-Path $statsFile) {
        $csv = Import-Csv $statsFile
        $aggregated = $csv | Where-Object { $_.Name -eq "Aggregated" }
        if ($aggregated) {
            $rps = $aggregated."Requests/s"
            $failRate = $aggregated."Failure Count"
            $avg = $aggregated."Average Response Time"
            $p50 = $aggregated."Median Response Time"
            $p95 = $aggregated.'95%'
            $total = $aggregated."Request Count"

            $line = "Replicas: $replicas | RPS: $rps | Avg: ${avg}ms | P50: ${p50}ms | P95: ${p95}ms | Total: $total | Failures: $failRate"
            Write-Host ""
            Write-Host "  RESULT: $line" -ForegroundColor Magenta
            Write-Host ""
            $summaryLines += $line
        } else {
            $summaryLines += "Replicas: $replicas | ERROR: No aggregated row in CSV"
            Write-Host "  WARNING: No aggregated stats found" -ForegroundColor Yellow
        }
    } else {
        $summaryLines += "Replicas: $replicas | ERROR: CSV file not found"
        Write-Host "  WARNING: Stats CSV not found at $statsFile" -ForegroundColor Yellow
    }

    # Cleanup temp files from the OS TEMP folder
    Remove-Item -Path "${csvPrefix}*" -Force -ErrorAction SilentlyContinue

    if ($replicas -ne $replicaCounts[-1]) {
        Log "Pausing 10s before next test..."
        Start-Sleep -Seconds 10
    }
}

Separator
Log "BENCHMARK COMPLETE"
Separator

$summaryLines += ""
$summaryLines += "=" * 70
$summaryLines += "Files generated in: $resultsDir"
$summaryLines += "=" * 70

$summaryLines | Out-File -FilePath $summaryFile -Encoding utf8
$summaryLines | ForEach-Object { Write-Host $_ -ForegroundColor Green }

if ($hpaDeleted -and (Test-Path $hpaFile)) {
    Log "Restoring HPA..."
    & kubectl apply -f $hpaFile 2>&1 | Out-Null
}

Log "Summary saved to: $summaryFile"
Log "All results in: $resultsDir"
