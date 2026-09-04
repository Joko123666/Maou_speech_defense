[CmdletBinding()]
param(
    [ValidateSet("full", "parse", "content", "meta", "preparation", "smoke", "tutorial", "verbose", "selftest")]
    [string]$Mode = "full",
    [string]$GodotPath = "",
    [string]$OutputRoot = "",
    [ValidateRange(1, 3600)]
    [int]$StageTimeoutSeconds = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ForbiddenPatterns = @(
    [pscustomobject]@{ Id = "script_error"; Pattern = "(?im)^\s*SCRIPT ERROR(?:\s*:|\s*$)" },
    [pscustomobject]@{ Id = "engine_error"; Pattern = "(?im)^\s*ERROR\s*:" },
    [pscustomobject]@{ Id = "objectdb_leak"; Pattern = "(?i)ObjectDB instances leaked at exit" },
    [pscustomobject]@{ Id = "resource_leak"; Pattern = "(?i)Resources still in use at exit" },
    [pscustomobject]@{ Id = "orphan_string_name"; Pattern = "(?i)Orphan StringName" }
)
$ExpectedFullStageSignature = "parse|content|meta|preparation|smoke|tutorial|verbose"
$ExpectedFullStages = [ordered]@{
    parse = ""
    content = "CONTENT ELECTION SMOKE PASS"
    meta = "META PERSISTENCE SMOKE PASS"
    preparation = "PREPARATION RUNTIME SMOKE PASS"
    smoke = "SMOKE TEST PASS"
    tutorial = "TUTORIAL RUNTIME SMOKE PASS"
    verbose = "SMOKE TEST PASS"
}
$ExpectedFullStageArgumentTemplates = [ordered]@{
    parse = @("--headless", "--editor", "--path", "{PROJECT_ROOT}", "--quit")
    content = @("--headless", "--path", "{PROJECT_ROOT}", "--audio-driver", "Dummy", "res://tests/content_election_runtime_smoke.tscn")
    meta = @("--headless", "--path", "{PROJECT_ROOT}", "--audio-driver", "Dummy", "res://tests/meta_progression_persistence_smoke.tscn")
    preparation = @("--headless", "--path", "{PROJECT_ROOT}", "--audio-driver", "Dummy", "res://tests/preparation_runtime_smoke.tscn")
    smoke = @("--headless", "--path", "{PROJECT_ROOT}", "--audio-driver", "Dummy", "res://tests/smoke_test.tscn")
    tutorial = @("--headless", "--path", "{PROJECT_ROOT}", "--audio-driver", "Dummy", "res://tests/tutorial_runtime_smoke_test.tscn")
    verbose = @("--headless", "--verbose", "--path", "{PROJECT_ROOT}", "--audio-driver", "Dummy", "res://tests/smoke_test.tscn")
}

function Resolve-GodotExecutable([string]$RequestedPath) {
    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        if (-not (Test-Path -LiteralPath $RequestedPath -PathType Leaf)) {
            throw "Godot executable was not found: $RequestedPath"
        }
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    if (-not [string]::IsNullOrWhiteSpace($desktopPath)) {
        $preferredPath = Join-Path $desktopPath "Godot_v4.7-stable_win64_console.exe"
        if (Test-Path -LiteralPath $preferredPath -PathType Leaf) {
            return (Resolve-Path -LiteralPath $preferredPath).Path
        }
    }

    foreach ($commandName in @("godot4", "godot")) {
        $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) {
            return $command.Source
        }
    }
    throw "Godot was not found. Pass -GodotPath with the Godot 4.7 console executable."
}

function ConvertTo-NativeArgument([string]$Value) {
    if ($Value.Length -eq 0) {
        return '""'
    }
    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-BoundedProcess(
    [string]$Executable,
    [string[]]$Arguments,
    [int]$TimeoutSeconds
) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Executable
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $argumentListProperty = $startInfo.PSObject.Properties["ArgumentList"]
    if ($null -ne $argumentListProperty) {
        foreach ($argument in $Arguments) {
            $startInfo.ArgumentList.Add([string]$argument)
        }
    } else {
        $startInfo.Arguments = (@($Arguments | ForEach-Object { ConvertTo-NativeArgument ([string]$_) }) -join ' ')
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $stdoutText = ""
    $stderrText = ""
    $exitCode = -1
    $timedOut = $false
    $launchError = ""
    try {
        if (-not $process.Start()) {
            throw "The process did not start."
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        if (-not $completed) {
            $timedOut = $true
            try {
                $process.Kill($true)
            } catch {
                $process.Kill()
            }
        }
        $process.WaitForExit()
        $stdoutText = $stdoutTask.GetAwaiter().GetResult()
        $stderrText = $stderrTask.GetAwaiter().GetResult()
        if (-not $timedOut) {
            $exitCode = $process.ExitCode
        }
    } catch {
        $launchError = $_.Exception.Message
    } finally {
        $stopwatch.Stop()
        $process.Dispose()
    }

    $outputLines = [System.Collections.Generic.List[string]]::new()
    foreach ($textBlock in @($stdoutText, $stderrText)) {
        foreach ($line in [regex]::Split($textBlock, "\r?\n")) {
            if (-not [string]::IsNullOrEmpty($line)) {
                $outputLines.Add($line)
            }
        }
    }
    return [pscustomobject]@{
        output_lines = @($outputLines)
        exit_code = $exitCode
        timed_out = $timedOut
        timeout_seconds = $TimeoutSeconds
        elapsed_ms = $stopwatch.ElapsedMilliseconds
        launch_error = $launchError
    }
}

function Test-StageOutput(
    [string]$Name,
    [string[]]$OutputLines,
    [int]$ExitCode,
    [string]$ExpectedMarker = "",
    [bool]$TimedOut = $false
) {
    $violations = [System.Collections.Generic.List[string]]::new()
    if ($ExitCode -ne 0) {
        $violations.Add("nonzero_exit")
    }
    if ($TimedOut) {
        $violations.Add("timeout")
    }

    $markerFound = $true
    if (-not [string]::IsNullOrWhiteSpace($ExpectedMarker)) {
        $markerFound = @($OutputLines | Where-Object { $_.Trim() -ceq $ExpectedMarker }).Count -gt 0
        if (-not $markerFound) {
            $violations.Add("missing_success_marker")
        }
    }

    $joinedOutput = $OutputLines -join [Environment]::NewLine
    foreach ($rule in $script:ForbiddenPatterns) {
        if ([regex]::IsMatch($joinedOutput, $rule.Pattern)) {
            $violations.Add([string]$rule.Id)
        }
    }

    return [pscustomobject]@{
        name = $Name
        passed = $violations.Count -eq 0
        exit_code = $ExitCode
        expected_marker = $ExpectedMarker
        marker_found = $markerFound
        timed_out = $TimedOut
        violations = @($violations)
    }
}

function Invoke-GodotStage(
    [string]$Name,
    [string[]]$Arguments,
    [string]$ExpectedMarker,
    [string]$Executable,
    [string]$RunDirectory,
    [int]$TimeoutSeconds
) {
    $logPath = Join-Path $RunDirectory "$Name.log"
    Write-Host "QUALITY GATE START: $Name"
    $outputLines = [System.Collections.Generic.List[string]]::new()
    $execution = Invoke-BoundedProcess $Executable $Arguments $TimeoutSeconds
    foreach ($line in $execution.output_lines) {
        $outputLines.Add([string]$line)
    }
    if (-not [string]::IsNullOrWhiteSpace($execution.launch_error)) {
        $outputLines.Add("QUALITY GATE LAUNCH ERROR: $($execution.launch_error)")
    }
    if ($execution.timed_out) {
        $outputLines.Add("QUALITY GATE TIMEOUT: $Name exceeded $TimeoutSeconds second(s)")
    }
    $outputLines | Set-Content -LiteralPath $logPath -Encoding utf8

    $result = Test-StageOutput $Name @($outputLines) $execution.exit_code $ExpectedMarker $execution.timed_out
    $result | Add-Member -NotePropertyName log_path -NotePropertyValue $logPath
    $result | Add-Member -NotePropertyName arguments -NotePropertyValue @($Arguments)
    $result | Add-Member -NotePropertyName timeout_seconds -NotePropertyValue $execution.timeout_seconds
    $result | Add-Member -NotePropertyName elapsed_ms -NotePropertyValue $execution.elapsed_ms
    if ($result.passed) {
        Write-Host "QUALITY GATE PASS: $Name (exit $($execution.exit_code); $($execution.elapsed_ms) ms)"
    } else {
        Write-Host "QUALITY GATE FAIL: $Name (exit $($execution.exit_code); $($result.violations -join ', '); $($execution.elapsed_ms) ms)"
        $tail = @($outputLines | Select-Object -Last 40)
        if ($tail.Count -gt 0) {
            Write-Host "--- $Name log tail ---"
            $tail | ForEach-Object { Write-Host $_ }
        }
    }
    return $result
}

function Get-QualityGateStages([string]$Root) {
    return @(
        [pscustomobject]@{
            Name = "parse"
            Arguments = @("--headless", "--editor", "--path", $Root, "--quit")
            Marker = ""
        },
        [pscustomobject]@{
            Name = "content"
            Arguments = @("--headless", "--path", $Root, "--audio-driver", "Dummy", "res://tests/content_election_runtime_smoke.tscn")
            Marker = "CONTENT ELECTION SMOKE PASS"
        },
        [pscustomobject]@{
            Name = "meta"
            Arguments = @("--headless", "--path", $Root, "--audio-driver", "Dummy", "res://tests/meta_progression_persistence_smoke.tscn")
            Marker = "META PERSISTENCE SMOKE PASS"
        },
        [pscustomobject]@{
            Name = "preparation"
            Arguments = @("--headless", "--path", $Root, "--audio-driver", "Dummy", "res://tests/preparation_runtime_smoke.tscn")
            Marker = "PREPARATION RUNTIME SMOKE PASS"
        },
        [pscustomobject]@{
            Name = "smoke"
            Arguments = @("--headless", "--path", $Root, "--audio-driver", "Dummy", "res://tests/smoke_test.tscn")
            Marker = "SMOKE TEST PASS"
        },
        [pscustomobject]@{
            Name = "tutorial"
            Arguments = @("--headless", "--path", $Root, "--audio-driver", "Dummy", "res://tests/tutorial_runtime_smoke_test.tscn")
            Marker = "TUTORIAL RUNTIME SMOKE PASS"
        },
        [pscustomobject]@{
            Name = "verbose"
            Arguments = @("--headless", "--verbose", "--path", $Root, "--audio-driver", "Dummy", "res://tests/smoke_test.tscn")
            Marker = "SMOKE TEST PASS"
        }
    )
}

function Test-StageConfiguration([object[]]$Stages) {
    $failures = [System.Collections.Generic.List[string]]::new()
    $actualNames = @($Stages | ForEach-Object { [string]$_.Name })
    $expectedNames = @($script:ExpectedFullStageSignature.Split("|"))
    if (($actualNames -join "`n") -cne ($expectedNames -join "`n")) {
        $failures.Add("expected ordered stages '$($expectedNames -join ', ')', got '$($actualNames -join ', ')'")
    }
    if (@($actualNames | Select-Object -Unique).Count -ne $actualNames.Count) {
        $failures.Add("stage names must be unique")
    }
    foreach ($expectedName in $expectedNames) {
        if (-not $script:ExpectedFullStages.Contains($expectedName)) {
            $failures.Add("stage '$expectedName' must define an expected marker")
        }
        if (-not $script:ExpectedFullStageArgumentTemplates.Contains($expectedName)) {
            $failures.Add("stage '$expectedName' must define expected process arguments")
        }
    }
    foreach ($stage in $Stages) {
        $name = [string]$stage.Name
        if (-not $script:ExpectedFullStages.Contains($name)) {
            continue
        }
        $expectedMarker = [string]$script:ExpectedFullStages[$name]
        if ([string]$stage.Marker -cne $expectedMarker) {
            $failures.Add("stage '$name' expected marker '$expectedMarker', got '$([string]$stage.Marker)'")
        }
        if (@($stage.Arguments).Count -eq 0) {
            $failures.Add("stage '$name' must define process arguments")
            continue
        }
        $expectedArguments = @($script:ExpectedFullStageArgumentTemplates[$name] | ForEach-Object {
            if ([string]$_ -ceq "{PROJECT_ROOT}") { $script:ProjectRoot } else { [string]$_ }
        })
        $actualArguments = @($stage.Arguments | ForEach-Object { [string]$_ })
        if (($actualArguments -join "`n") -cne ($expectedArguments -join "`n")) {
            $failures.Add("stage '$name' process arguments differ from the frozen manifest")
        }
    }
    return @($failures)
}

function Invoke-EvaluatorSelfTest {
    $cases = @(
        [pscustomobject]@{ Name = "clean_smoke"; Lines = @("SMOKE TEST PASS"); ExitCode = 0; Marker = "SMOKE TEST PASS"; Expected = $true; Violation = "" },
        [pscustomobject]@{ Name = "false_pass_script_error"; Lines = @("SCRIPT ERROR: Invalid call", "SMOKE TEST PASS"); ExitCode = 0; Marker = "SMOKE TEST PASS"; Expected = $false; Violation = "script_error" },
        [pscustomobject]@{ Name = "missing_marker"; Lines = @("Godot Engine v4.7"); ExitCode = 0; Marker = "SMOKE TEST PASS"; Expected = $false; Violation = "missing_success_marker" },
        [pscustomobject]@{ Name = "nonzero_exit"; Lines = @("SMOKE TEST PASS"); ExitCode = 3; Marker = "SMOKE TEST PASS"; Expected = $false; Violation = "nonzero_exit" },
        [pscustomobject]@{ Name = "engine_error"; Lines = @("ERROR: A runtime failure", "SMOKE TEST PASS"); ExitCode = 0; Marker = "SMOKE TEST PASS"; Expected = $false; Violation = "engine_error" },
        [pscustomobject]@{ Name = "leak_warning"; Lines = @("WARNING: ObjectDB instances leaked at exit", "SMOKE TEST PASS"); ExitCode = 0; Marker = "SMOKE TEST PASS"; Expected = $false; Violation = "objectdb_leak" },
        [pscustomobject]@{ Name = "resource_leak"; Lines = @("WARNING: Resources still in use at exit", "SMOKE TEST PASS"); ExitCode = 0; Marker = "SMOKE TEST PASS"; Expected = $false; Violation = "resource_leak" },
        [pscustomobject]@{ Name = "orphan_string_name"; Lines = @("Orphan StringName: combat_source", "SMOKE TEST PASS"); ExitCode = 0; Marker = "SMOKE TEST PASS"; Expected = $false; Violation = "orphan_string_name" },
        [pscustomobject]@{ Name = "clean_content"; Lines = @("CONTENT ELECTION SMOKE PASS"); ExitCode = 0; Marker = "CONTENT ELECTION SMOKE PASS"; Expected = $true; Violation = "" },
        [pscustomobject]@{ Name = "clean_meta"; Lines = @("META PERSISTENCE SMOKE PASS"); ExitCode = 0; Marker = "META PERSISTENCE SMOKE PASS"; Expected = $true; Violation = "" },
        [pscustomobject]@{ Name = "clean_preparation"; Lines = @("PREPARATION RUNTIME SMOKE PASS"); ExitCode = 0; Marker = "PREPARATION RUNTIME SMOKE PASS"; Expected = $true; Violation = "" },
        [pscustomobject]@{ Name = "timeout"; Lines = @("Godot Engine v4.7"); ExitCode = -1; Marker = ""; TimedOut = $true; Expected = $false; Violation = "timeout" },
        [pscustomobject]@{ Name = "clean_parse"; Lines = @("Godot Engine v4.7", "SCRIPT ERROR is a documented phrase, not a diagnostic line"); ExitCode = 0; Marker = ""; Expected = $true; Violation = "" }
    )
    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($case in $cases) {
        $timedOut = $null -ne $case.PSObject.Properties["TimedOut"] -and [bool]$case.TimedOut
        $result = Test-StageOutput $case.Name $case.Lines $case.ExitCode $case.Marker $timedOut
        if ($result.passed -ne $case.Expected) {
            $failures.Add("$($case.Name): expected passed=$($case.Expected), got $($result.passed)")
        }
        if (-not [string]::IsNullOrWhiteSpace($case.Violation) -and $case.Violation -notin $result.violations) {
            $failures.Add("$($case.Name): missing violation $($case.Violation)")
        }
    }
    foreach ($configurationFailure in Test-StageConfiguration (Get-QualityGateStages $script:ProjectRoot)) {
        $failures.Add("stage_configuration: $configurationFailure")
    }
    $missingVerboseStages = @(Get-QualityGateStages $script:ProjectRoot)
    $missingVerboseStage = $missingVerboseStages | Where-Object { $_.Name -eq "verbose" } | Select-Object -First 1
    $missingVerboseStage.Arguments = @($missingVerboseStage.Arguments | Where-Object { [string]$_ -cne "--verbose" })
    if (@(Test-StageConfiguration $missingVerboseStages).Count -eq 0) {
        $failures.Add("stage_configuration_mutation: removing --verbose must fail the frozen manifest")
    }
    $wrongTutorialStages = @(Get-QualityGateStages $script:ProjectRoot)
    $wrongTutorialStage = $wrongTutorialStages | Where-Object { $_.Name -eq "tutorial" } | Select-Object -First 1
    $wrongTutorialStage.Arguments = @($wrongTutorialStage.Arguments | ForEach-Object {
        if ([string]$_ -ceq "res://tests/tutorial_runtime_smoke_test.tscn") { "res://tests/smoke_test.tscn" } else { [string]$_ }
    })
    if (@(Test-StageConfiguration $wrongTutorialStages).Count -eq 0) {
        $failures.Add("stage_configuration_mutation: replacing the tutorial scene must fail the frozen manifest")
    }
    $selfExecutable = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $timeoutProbe = Invoke-BoundedProcess $selfExecutable @("-NoProfile", "-Command", "Start-Sleep -Seconds 3") 1
    if (-not $timeoutProbe.timed_out -or $timeoutProbe.elapsed_ms -ge 3000) {
        $failures.Add("bounded_process_timeout: expected a 1-second timeout before the 3-second probe completed")
    }
    if ($failures.Count -gt 0) {
        $failures | ForEach-Object { Write-Host "QUALITY GATE SELFTEST FAIL: $_" }
        return $false
    }
    Write-Host "QUALITY GATE SELFTEST PASS: $($cases.Count) evaluator cases, exact seven-stage manifest and arguments, two manifest mutation probes, and bounded-process timeout probe"
    return $true
}

if ($Mode -eq "selftest") {
    if (Invoke-EvaluatorSelfTest) {
        exit 0
    }
    exit 1
}

try {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "project.godot") -PathType Leaf)) {
        throw "project.godot was not found under $ProjectRoot"
    }
    $GodotExecutable = Resolve-GodotExecutable $GodotPath
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
        $OutputRoot = Join-Path ([System.IO.Path]::GetTempPath()) "td-survival-headless-quality-gate"
    }
    $runId = "{0}_{1}" -f (Get-Date -Format "yyyyMMdd_HHmmss_fff"), $PID
    $runDirectory = Join-Path $OutputRoot $runId
    New-Item -ItemType Directory -Force -Path $runDirectory | Out-Null
} catch {
    [Console]::Error.WriteLine("QUALITY GATE SETUP FAIL: $($_.Exception.Message)")
    exit 2
}

$allStages = @(Get-QualityGateStages $ProjectRoot)
$stageConfigurationFailures = @(Test-StageConfiguration $allStages)
if ($stageConfigurationFailures.Count -gt 0) {
    $stageConfigurationFailures | ForEach-Object { [Console]::Error.WriteLine("QUALITY GATE CONFIGURATION FAIL: $_") }
    exit 2
}
$selectedStages = if ($Mode -eq "full") { $allStages } else { @($allStages | Where-Object { $_.Name -eq $Mode }) }
$results = [System.Collections.Generic.List[object]]::new()
foreach ($stage in $selectedStages) {
    $results.Add((Invoke-GodotStage $stage.Name $stage.Arguments $stage.Marker $GodotExecutable $runDirectory $StageTimeoutSeconds))
}

$passed = @($results | Where-Object { -not $_.passed }).Count -eq 0
$summary = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToString("o")
    project_root = $ProjectRoot
    godot_path = $GodotExecutable
    mode = $Mode
    stage_timeout_seconds = $StageTimeoutSeconds
    passed = $passed
    stages = @($results)
}
$summaryPath = Join-Path $runDirectory "summary.json"
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding utf8

if ($passed) {
    Write-Host "HEADLESS QUALITY GATE PASS: $($results.Count) stage(s)"
    Write-Host "QUALITY GATE REPORT: $summaryPath"
    exit 0
}
Write-Host "HEADLESS QUALITY GATE FAIL: $(@($results | Where-Object { -not $_.passed }).Count) stage(s)"
Write-Host "QUALITY GATE REPORT: $summaryPath"
exit 1
