<#
.DESCRIPTION
Uninstalls ora2pg tool on a Windows machine which was installed by the installer script. Script should be run with "administrator" context.
This script will not be able to uninstall if Ora2Pg custom installation is done as the system changes will be different.
It is discouraged to use this uninstall script for custom Ora2Pg installations.


.PARAMETER InstallFolderPath
Specify the full path for the root installation folder under which all the components will be installed. The same paths would be 
updated in the environment variables.
#>

param (
    [Parameter(Mandatory)][string]$InstallFolderPath
)

Function Delete-EnvironmentPath {
    <#
    .DESCRIPTION
    Deletes path value from the environment path variable value if it exists. The method does not saves the updated value
    back into the environment variable.

    .OUTPUTS
    [string]: Updated path variable.
    #>
    Param(        
        # Name of the environment variable
        [Parameter(Mandatory)]
        [string] $variableName,
        # The new path value which needs to be appended to the variable value
        [Parameter(Mandatory)]
        [string] $path,
        # Path delimiter
        [Parameter()]
        [string] $delimiter = ";"
    )

    $variableValue = [System.Environment]::GetEnvironmentVariable($variableName, [System.EnvironmentVariableTarget]::Machine)
    $paths = if($variableValue) { $variableValue -split $delimiter } else { @("") }

    $paths = $paths | Where-Object { $_ –notlike $path }
    $paths = $paths | ? {$_}

    $result = [string]::Join($delimiter, $paths)
    return $result
}

###################################### Permission Check ######################################
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ALERT!!!" -ForegroundColor Red
    Write-Host "Can not run installation script." -ForegroundColor Red
    Write-Host "Please run the script under administrative context. Launch powershell with " + `
     "`"RunAsAdministrator`" option." -ForegroundColor Red
    exit
}

###################################### Script Main #################################

$installFolder = $InstallFolderPath
$ErrorActionPreference = "SilentlyContinue"

Write-Host "Uninstalling Strawberry Perl..." -ForegroundColor Yellow
Uninstall-Package -Name "Strawberry Perl (64-bit)"
Write-Host "Updating envornment variables..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("ORACLE_HOME_ORA2PG", $null, [System.EnvironmentVariableTarget]::Machine)
$updatedPath = Delete-EnvironmentPath -variableName "LD_LIBRARY_PATH" -path "$installFolder*"
[System.Environment]::SetEnvironmentVariable("LD_LIBRARY_PATH", $updatedPath, [System.EnvironmentVariableTarget]::Machine)
$updatedPath = Delete-EnvironmentPath -variableName "Path" -path "$installFolder*"
[System.Environment]::SetEnvironmentVariable("Path", $updatedPath, [System.EnvironmentVariableTarget]::Machine)
Write-Host "Deleting C:\ora2pg folder..." -ForegroundColor Yellow
if(Test-Path "C:\ora2pg") { Remove-Item -Path "C:\ora2pg" -Recurse -Force | Out-Null }
Write-Host "Deleting complete install folder..." -ForegroundColor Yellow
Remove-Item -Path $installFolder -Recurse -Force | Out-Null
