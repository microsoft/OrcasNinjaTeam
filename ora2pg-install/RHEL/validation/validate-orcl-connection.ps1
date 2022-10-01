<#
.SYNOPSIS 
Ora2Pg Oralce Connection Validation

.DESCRIPTION
Runs the basic connection test to an Oracle instance through Ora2Pg tool.

.PARAMETER OracleDNS
Oracle server connection DNS in format 'dbi:Oracle:host=0.0.0.0;sid=orcl;port=1521'.

.PARAMETER OracleUser
Oracle server conncetion user name.

.PARAMETER OraclePwd
(Optional) Oracle server connection password. If not provided, then user will be prompted.
#>

param (
    # Oracle server DNS
    [Parameter(Mandatory)][string]$OracleDNS,
    # Oracle database user name
    [Parameter(Mandatory)][string]$OracleUser,
    # Oracle database password
    [Parameter()][string]$OraclePwd,
    # Expected result
    [Parameter(Mandatory)][string]$ExpectedResult
)

if (-not $OraclePwd) {
    $securePwd = Read-Host -Prompt "Enter Oracle database password:" -AsSecureString
    $OraclePwd =[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd))
}

$projectPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.DateTime]::Now.ToString("yyyyMMddHHmmss"))
$projectName = "migv1"
if(Test-Path $projectPath) {
    Remove-Item -Path $projectPath -Force -Recurse | Out-Null
}

Write-Host "Creating target directory..." -ForegroundColor Yellow
[System.IO.Directory]::CreateDirectory($projectPath) | Out-Null

try {
    Write-Host "Initializing Ora2Pg project $projectName at $projectPath"
    Invoke-Expression "ora2pg --project_base $projectPath --init_project $projectName" `
        -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
    $projectInitPath = Join-Path $projectPath $projectName
    $configFilePath = Join-Path $projectInitPath "config\ora2pg.conf"

    $initSuccess = (Test-Path -Path $configFilePath)
    if ($initSuccess) { Write-Host "Project initialization successful" -ForegroundColor Green } else { throw "Project init failed" }

    $expression = "ora2pg -t SHOW_VERSION -c $configFilePath"
    $expression += " -s '$OracleDNS'"
    $expression += " -u '$OracleUser'"
    $expression += " -w '$OraclePwd'"

    $version = Invoke-Expression $expression -ErrorAction Continue
    Write-Host "Expression output: $version" -ForegroundColor Yellow
    
    if ($version.ToString().Contains($ExpectedResult)) {
        Write-Host "Database version check successful" -ForegroundColor Green
    } else {
        throw "Database version check failed."
    }
    Write-Host "TEST SUCCESSFUL" -ForegroundColor Green
}
catch {
    Write-Host ($_.Exception.ToString()) -ForegroundColor Red
    Write-Host "TEST FAILED" -ForegroundColor Red
}
finally {
    Write-Host "Clearing temp project..." -ForegroundColor Yellow
    [System.IO.Directory]::Delete($projectPath, $true) | Out-Null
}