param(
    [string]$Mode = "interactive",
    [int]$Users = 50,
    [int]$SpawnRate = 5,
    [string]$Duration = "1m",
    [int]$ScaleTo = 2
)

Set-StrictMode -Version Latest
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptRoot\.." | Select-Object -ExpandProperty Path

$k8sDir = Join-Path $RepoRoot "k8s"
$backendDir = Join-Path $RepoRoot "back_end"
$resultsDir = Join-Path (Join-Path $RepoRoot "locust") "results"
$imageTag = "ark-backend:latest"
$namespace = "default"
$deployment = "backend"
$service = "backend-service"

function Print-Line {
  Write-Host ("=" * 70)
}

function Log {
  param([string]$Message)
  Write-Host "[DEMO] $Message" -ForegroundColor Cyan
}

function Pause-Menu {
  Write-Host "Press Enter to continue..." -ForegroundColor Gray
  $null = Read-Host
}

function Test-Command {
  param([string]$Cmd)
  $null = Get-Command $Cmd -ErrorAction SilentlyContinue
  return $?
}

function Build-Image {
  Print-Line
  Log "Building Docker image into Minikube..."
  if (-not (Test-Command "minikube")) {
    Write-Error "minikube not found in PATH"
    return
  }
  Push-Location $RepoRoot
  & minikube image build -t $imageTag ./back_end
  Pop-Location
  Log "Image build complete." -ForegroundColor Green
}

function Deploy-K8s {
  Print-Line
  Log "Applying Kubernetes manifests..."
  if (-not (Test-Command "kubectl")) {
    Write-Error "kubectl not found in PATH"
    return
  }
  & kubectl apply -f $k8sDir
  Log "Manifests applied." -ForegroundColor Green
}

function Scale-Deployment {
  Print-Line
  $n = Read-Host "Enter number of replicas"
  if ($n -match '^\d+$') {
    Log "Scaling $deployment to $n replica(s)..."
    & kubectl scale deployment/$deployment --replicas=$n
    & kubectl rollout status deployment/$deployment --timeout=120s
  } else {
    Write-Host "Invalid number" -ForegroundColor Red
  }
}

function Show-Status {
  Print-Line
  Write-Host "Namespace: $namespace" -ForegroundColor Green
  Write-Host "Deployment: $deployment" -ForegroundColor Green
  Write-Host "Image: $imageTag" -ForegroundColor Green
  Print-Line
  Log "Pods:"
  & kubectl get pods -o wide
  Print-Line
  Log "Services:"
  & kubectl get svc -o wide
}

function Get-BackendServiceUrl {
  try {
    $svc = & kubectl get svc $service -o json 2>$null | ConvertFrom-Json
  } catch {
    $svc = $null
  }

  if ($svc) {
    if ($svc.spec.type -eq 'LoadBalancer' -and $svc.status.loadBalancer.ingress) {
      $ingress = $svc.status.loadBalancer.ingress[0]
      if ($ingress.ip) {
        return "http://$($ingress.ip):$($svc.spec.ports[0].port)"
      }
      if ($ingress.hostname) {
        return "http://$($ingress.hostname):$($svc.spec.ports[0].port)"
      }
    }

    if ($svc.spec.ports[0].nodePort) {
      try {
        $minikubeIp = (& minikube ip 2>$null).Trim()
      } catch {
        $minikubeIp = $null
      }
      if ($minikubeIp) {
        return "http://${minikubeIp}:$($svc.spec.ports[0].nodePort)"
      }
    }
  }

  return $null
}

function Watch-Pods {
  Print-Line
  Log "Watching pods (Ctrl+C to stop)..."
  while ($true) {
    Clear-Host
    & kubectl get pods -n $namespace -o wide
    Write-Host "`nRefreshing every 2s (Ctrl+C to stop)..."
    Start-Sleep -Seconds 2
  }
}

function Run-Locust-Interactive {
  Print-Line
  Write-Host "Configure Locust run:" -ForegroundColor Yellow
  $u = Read-Host "Users (default $Users)"
  if ($u) { $Users = [int]$u }
  
  $s = Read-Host "Spawn rate (default $SpawnRate)"
  if ($s) { $SpawnRate = [int]$s }
  
  $d = Read-Host "Duration like '1m' or '30s' (default $Duration)"
  if ($d) { $Duration = $d }
  
  $sc = Read-Host "Scale to N replicas (default $ScaleTo)"
  if ($sc) { $ScaleTo = [int]$sc }
  
  Run-Locust-Internal $Users $SpawnRate $Duration $ScaleTo
}

function Run-Locust-Internal {
  param([int]$UsersCount, [int]$SpawnRateCount, [string]$DurationStr, [int]$ReplicasCount)
  
  Print-Line
  Log "Scaling backend deployment to $ReplicasCount replicas..."
  & kubectl scale deployment $deployment --replicas=$ReplicasCount
  & kubectl rollout status deployment/$deployment --timeout=120s
  Write-Host "  Deployment ready." -ForegroundColor Green

  Log "Getting backend service URL..."
  $serviceUrl = Get-BackendServiceUrl

  if (-not $serviceUrl) {
    Write-Host "  WARNING: Unable to resolve service URL from minikube; using port-forward fallback..." -ForegroundColor Yellow
    $serviceUrl = "http://localhost:8080"
    
    $pfJob = Start-Job -ScriptBlock {
      & kubectl port-forward svc/$service 8080:80 -n $namespace 2>$null
    }
    Start-Sleep -Seconds 2
  }
  
  if (-not $serviceUrl) {
    Write-Host "  ERROR: Could not determine service URL." -ForegroundColor Red
    return 1
  }
  Write-Host "  Service URL: $serviceUrl" -ForegroundColor Green

  Log "Waiting for health endpoint..."
  $healthUrl = "$serviceUrl/health"
  $tries = 0
  while ($tries -lt 30) {
    try {
      $resp = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 5
      if ($resp.status -eq 'healthy') { 
        Write-Host "  Health OK - service is ready" -ForegroundColor Green
        break 
      }
    } catch {
      Write-Host "  Try $($tries + 1)/30: service not ready..."
      Start-Sleep -Seconds 2
    }
    $tries++
  }
  if ($tries -ge 30) {
    Write-Host "  ERROR: Service did not become healthy in time." -ForegroundColor Red
    return 2
  }

  Log "Preparing results directory..."
  if (-not (Test-Path $resultsDir)) { 
    New-Item -ItemType Directory -Path $resultsDir | Out-Null
  }
  $csvPrefix = Join-Path $resultsDir "locust"

  Log "Starting headless Locust: users=$UsersCount spawn_rate=$SpawnRateCount duration=$DurationStr"
  $locustPath = (Get-Command locust -ErrorAction SilentlyContinue).Source
  if (-not $locustPath) {
    Write-Host "ERROR: 'locust' command not found in PATH. Install Locust: pip install locust" -ForegroundColor Red
    return 1
  }

  $argList = @(
    '-f', "$RepoRoot\locust\locustfile.py",
    '--headless',
    '-u', $UsersCount.ToString(),
    '-r', $SpawnRateCount.ToString(),
    '-t', $DurationStr,
    '--host', $serviceUrl,
    '--csv', $csvPrefix
  )

  $proc = Start-Process -FilePath 'locust' -ArgumentList $argList -NoNewWindow -Wait -PassThru
  Write-Host "  Locust exit code: $($proc.ExitCode)" -ForegroundColor Yellow

  if ($proc.ExitCode -ne 0) {
    Write-Host "Locust exited with code $($proc.ExitCode)" -ForegroundColor Red
  } else {
    Write-Host "Locust run completed successfully." -ForegroundColor Green
  }

  Log "Collecting metrics and pod status..."
  $timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")

  Write-Host "  Checking CSV outputs..."
  $csvStats = "$csvPrefix`_stats.csv"
  $csvFailures = "$csvPrefix`_failures.csv"
  $csvDist = "$csvPrefix`_distribution.csv"

  foreach ($csv in @($csvStats, $csvFailures, $csvDist)) {
    if (Test-Path $csv) {
      $size = (Get-Item $csv).Length
      Write-Host "    [OK] $(Split-Path -Leaf $csv) ($size bytes)" -ForegroundColor Green
    } else {
      Write-Host "    [MISSING] $(Split-Path -Leaf $csv)" -ForegroundColor Yellow
    }
  }

  $metricsFile = Join-Path $resultsDir "metrics_$timestamp.json"
  try {
    Write-Host "  Fetching /metrics endpoint..."
    $metrics = Invoke-RestMethod -Uri "$serviceUrl/metrics" -Method Get -TimeoutSec 5
    $metrics | ConvertTo-Json | Out-File -FilePath $metricsFile -Encoding utf8
    $size = (Get-Item $metricsFile).Length
    Write-Host "    [OK] Saved metrics ($size bytes)" -ForegroundColor Green
  } catch {
    Write-Host "    [WARNING] Failed to fetch /metrics: $($_.Exception.Message)" -ForegroundColor Yellow
  }

  $podsFile = Join-Path $resultsDir "pods_$timestamp.txt"
  $hpaFile = Join-Path $resultsDir "hpa_$timestamp.txt"
  kubectl get pods -o wide | Out-File -FilePath $podsFile
  kubectl get hpa | Out-File -FilePath $hpaFile
  Write-Host "    [OK] Pods and HPA saved" -ForegroundColor Green

  Log "Demo complete. Results in: $resultsDir"
  return 0
}

function Collect-Results {
  Print-Line
  New-Item -ItemType Directory -Path $resultsDir -Force -ErrorAction SilentlyContinue | Out-Null
  Log "Results directory: $resultsDir"
  Get-ChildItem $resultsDir -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  - $($_.Name) ($($_.Length) bytes)" -ForegroundColor Cyan
  }
  Print-Line
  Log "Current pods:"
  & kubectl get pods -o wide
}

function Check-Tools {
  Print-Line
  Log "Checking prerequisites..."
  $tools = @("minikube", "kubectl", "docker")
  foreach ($tool in $tools) {
    if (Test-Command $tool) {
      Write-Host "  [OK] $tool found" -ForegroundColor Green
    } else {
      Write-Host "  [MISSING] $tool not found" -ForegroundColor Red
    }
  }
}

function Show-Menu {
  Clear-Host
  Print-Line
  Write-Host "ARK Backend Scaling Demo - Minikube + Locust" -ForegroundColor Cyan
  Print-Line

  $replicasStr = "Unknown (deployment not found)"
  if (Test-Command "kubectl") {
    $replicas = & kubectl get deployment/$deployment -n $namespace -o jsonpath='{.status.replicas}' 2>$null
    $readyReplicas = & kubectl get deployment/$deployment -n $namespace -o jsonpath='{.status.readyReplicas}' 2>$null
    if ($replicas -ne $null -and $replicas -ne "") {
      if ($readyReplicas -eq "") { $readyReplicas = 0 }
      $replicasStr = "$readyReplicas/$replicas Ready"
    }
  }

  Write-Host "Config:" -ForegroundColor Yellow
  Write-Host "  Namespace: $namespace"
  Write-Host "  Deployment: $deployment"
  Write-Host "  Image: $imageTag"
  Write-Host "  Current Pods: $replicasStr" -ForegroundColor Yellow
  Write-Host "  Locust: Users=$Users SpawnRate=$SpawnRate Duration=$Duration"
  Print-Line
  Write-Host "Menu:" -ForegroundColor Green
  Write-Host " 1) Check tools (minikube, kubectl, docker)"
  Write-Host " 2) Build Docker image into Minikube"
  Write-Host " 3) Apply Kubernetes manifests"
  Write-Host " 4) Scale deployment (Current: $replicasStr)"
  Write-Host " 5) Show cluster status"
  Write-Host " 6) Watch pods (live refresh)"
  Write-Host " 7) Configure and run Locust load test"
  Write-Host " 8) Collect and show results"
  Write-Host " 9) Run full demo (build > deploy > run > collect)"
  Write-Host " 0) Exit"
  Print-Line
}


function Run-Full-Demo {
  Build-Image
  Deploy-K8s
  Run-Locust-Interactive
  Collect-Results
}

function Main-Loop {
  while ($true) {
    Show-Menu
    $choice = Read-Host "Choose option"
    
    switch ($choice) {
      "1" { Check-Tools; Pause-Menu }
      "2" { Build-Image; Pause-Menu }
      "3" { Deploy-K8s; Pause-Menu }
      "4" { Scale-Deployment; Pause-Menu }
      "5" { Show-Status; Pause-Menu }
      "6" { Watch-Pods }
      "7" { Run-Locust-Interactive; Pause-Menu }
      "8" { Collect-Results; Pause-Menu }
      "9" { Run-Full-Demo; Pause-Menu }
      "0" { exit 0 }
      default { Write-Host "Invalid option" -ForegroundColor Red; Pause-Menu }
    }
  }
}

$hasRunArgs = @($PSBoundParameters.Keys | Where-Object { $_ -ne 'Mode' }).Count -gt 0

if ($Mode -eq "interactive" -and $hasRunArgs) {
  Write-Host "Parameters detected; running non-interactive demo." -ForegroundColor Green
  Build-Image
  Deploy-K8s
  Run-Locust-Internal $Users $SpawnRate $Duration $ScaleTo
  Collect-Results
} elseif ($Mode -eq "interactive") {
  Main-Loop
} else {
  Build-Image
  Deploy-K8s
  Run-Locust-Internal $Users $SpawnRate $Duration $ScaleTo
  Collect-Results
}
