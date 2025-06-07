###############################################################################################
#/***This Artifact belongs to the Microsoft Engineering Team***/
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# $Id: installora2pg.ps1 17 2021-02-02 10:12:44Z bpahlawa $
# $Date: 2022-09-21 (Wed, 21 Sep 2022) $
# $Revision: 20 $
# $Author: sgaur $ bpahlawa $
# $Contributor: vijku $ adkumara
###############################################################################################

<#
.SYNOPSIS 
Installs ora2pg tool on a Windows machine along with its dependencies. Script should be run with "administrator" context.

.DESCRIPTION
The script checks, downloads, checks and installs ora2pg and its dependencies. The different dependencies are downloaded 
from the internet, stored in the workspace directory and then installed. 

The workspace directory is not deleted by default, so that it could be copied over to any other machine which does not have 
internet connection and the same script can be run to install ora2pg from the cached downloads. This is the reason that 
downloads are done before checking for existing installs so that the packages are always present in the download folder
which can be used on another machine which does not have internet.

Desired Oracle instant instantclient*.zip and instantclient-sdk*.zip can be downloaded and placed in the script folder. 
If not then latest version of the packages will be downloaded from the public Oracle site.

Query and Download URLs:
https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html
https://www.oracle.com/database/technologies/instant-client/microsoft-windows-32-downloads.html
https://download.oracle.com/otn.*/instantclient/.*/*-windows.*zip
https://aka.ms/vs/17/release/vc_redist.x*.exe
https://aka.ms/highdpimfc2013x*enu
http://strawberryperl.com/
http://strawberryperl.com/download/*/strawberry-perl-*.msi
https://cpan.metacpan.org/authors/id/*.tar.gz
https://github.com/darold/ora2pg/releases
https://github.com/darold/ora2pg/archive/refs/tags/*.zip


.PARAMETER InstallFolderPath
Specify the full path for the root installation folder under which all the components will be installed. The same paths would be 
updated in the environment variables.

.PARAMETER WorkspaceFolderPath
Specify the full path for the workspace folder where the components will be downloaded before installation. If the installer
already exists, then it will not be downloaded again.

.PARAMETER Is32bit
(Optional) [switch] Specifies if the machine processor architecture is 64bit or 32bit. If set then it means machine is 32bit.
Default Value: False

.PARAMETER DeleteWorkspace
(Optional) Forces the script to delete the workspace folder on completion (success or failure)
Default Value: False
#>

param (
    [Parameter(Mandatory)][string]$InstallFolderPath,
    [Parameter(Mandatory)][string]$WorkspaceFolderName,
    [Parameter()][switch]$Is32bit = $false,
    [Parameter()][switch]$DeleteWorkspace = $false
)

$Global:ScriptId = '70671196-bc26-489a-bbb5-1af626a585ca'

Function Write-OutputAndLog
{
    <#
    .DESCRIPTION
    Display the message on the console host and also log the message to the script log file.

    .OUTPUTS
    None.
    #>
    Param (
        # Progress message which needs to be logged
        [Parameter()]
        [string]$message
    )

    $logLine = ("{0}:INFO:" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")) + $message
    $color = if ($message.EndsWith("...")) { "Yellow" } else { "Green" }
    Write-Host "$logLine" -ForegroundColor $color
    if($Global:Logfile -ne $null) {
        Add-content "$Global:Logfile" -value $logLine
    }    
}

Function Write-WarningAndLog
{
    <#
    .DESCRIPTION
    Display the message on the console host and also log the message to the script log file.

    .OUTPUTS
    None.
    #>
    Param (
        # Progress message which needs to be logged
        [Parameter()]
        [string]$message
    )

    $logLine = ("{0}:Warning:" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")) + $message

    Write-Host "$logLine" -ForegroundColor Yellow
    if($Global:Logfile -ne $null) {
        Add-content "$Global:Logfile" -value $logLine
    }    
}

Function Write-ErrorAndLog
{
    <#
    .DESCRIPTION
    Display the error message on the console host and also log the error to the script log file.

    .OUTPUTS
    None.
    #>
    Param (
        # Error message which needs to be logged
        [Parameter()]
        [System.Exception] $message,
        # Exception instance which needs to be logged.
        [Parameter()]
        [System.Exception] $exception
    )

    if($message -ne $null) {
        $logLine = ("{0}:ERROR:" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")) + $message
        Write-Host $logLine -ForegroundColor Red
        if($Global:Logfile -ne $null) {
            Add-content "$Global:Logfile" -value $logLine
        }
    }

    if($exception -ne $null) {
        $logLine = "{0}:ERROR:{1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff"), ($exception.ToString())
        Write-Host $logLine -ForegroundColor Red
        if($Global:Logfile -ne $null) {
            Add-content "$Global:Logfile" -value $logLine
        }
    }     
}

Function Acquire-Lock {
    <#
    .DESCRIPTION
    The function acquires a file lock so that only one instance of the script can run at a time.
    Aborts the script run if already another powershell console has the lock using the script id.

    .OUTPUTS
    None
    #>
    $lockFile = Join-Path ([System.IO.Path]::GetTempPath()) "$Global:ScriptId.lk"
    
    $currentProcess = [System.Diagnostics.Process]::GetCurrentProcess()
    $takeLock = $false
    # lock exists
    if (Test-Path $lockFile){
        # if file exists then check if the process is powershell and still running
        $processId = [int]::Parse((Get-Content -Path $lockFile))
        $otherProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
        # if it is null and not equal to powershell then its safe to take a lock
        # otherwise show error to user and ask them to close the powershell process
        # with the defined process id
        if($otherProcess -eq $null -or $otherProcess.ProcessName -notlike "powershell"){
            Remove-Item -Path $lockFile -Force -ErrorAction SilentlyContinue | Out-Null
            $takeLock = $true
        } 
        else {
            Write-ErrorAndLog "Invalid Operation: Only one instance of the script is allowed to run at a time." + `
                "Another powershell console with processid $processId has a lock for installation." + `
                "If the last installation was aborted in middle, then please close the console or " + `
                "delete the file '$lockFile' to release the lock."
		    Write-Host "........Press enter to exit........" -ForegroundColor Yellow
		    $null = Read-Host
            exit
        }
    }

    # lock acquired
    Write-OutputAndLog "Installation lock acquired."
    Set-Content -Path $lockFile -Value ($currentProcess.Id)
}

Function Safe-Exit {
    <#
    .DESCRIPTION
    The function releases the file lock taken by this instance of the powershell console using the script id,
    so that other instances of this script can be run.

    .OUTPUTS
    None
    #>
    Write-OutputAndLog "Releasing installation lock..."
    $lockFile = Join-Path ([System.IO.Path]::GetTempPath()) "$Global:ScriptId.lk"
    
    if (Test-Path $lockFile) {
        Remove-Item -Path $lockFile -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Write-OutputAndLog "Script Completed!"
    exit
}

Function Validate-Path {
    <#
    .DESCRIPTION
    The function validates the path and if not existing generates the folder structure.
    If path is not rooted, then the root path is used to generate a fully qualified path.

    .OUTPUTS
    [System.String]: Fully qualified folder path.
    #>
    Param (
        [Parameter(Mandatory)]
        [string]$path,
        [Parameter(Mandatory)]
        [string]$rootPath
    )

    $fullPath = $path
    try{
        ## Generate full file path
        if(-not [System.IO.Path]::IsPathRooted($fullPath)){
            $fullPath = [System.IO.Path]::Combine($rootPath, $fullPath)
        }
        ## Check that the path is not pointing to a file
        if([System.IO.File]::Exists($fullPath)){
            throw "Invalid Path: Expected folder path but received file path."
        }
        ## Check if directory exists and if not then create it
        if(-not [System.IO.Directory]::Exists($fullPath)){
            [System.IO.Directory]::CreateDirectory($fullPath) | Out-Null
            Write-OutputAndLog "Generated directory $fullPath."
        }
        else{
            Write-OutputAndLog "Path $fullPath already exists."
        }

        return $fullPath
    }
    catch{
        Write-ErrorAndLog -exception $_.Exception
        throw "Invalid Path: Failed path validation."
    }    
}

Function Check-Internet
{
    <#
    .DESCRIPTION
    Checks the internet connection by pinging known sites and stops execution if internet connection is
    not available.

    .OUTPUTS
    $true if the connection is available; otherwise $false
    #>
    Param (
        [Parameter()]
        [switch]$exitOnFailure
    )
    try {
        Write-OutputAndLog "Checking for internet connection..."
        $checkResult = Invoke-WebRequest "http://microsoft.com" -ErrorAction SilentlyContinue
    }
    catch {
        Write-ErrorAndLog -exception $_.Exception
        $checkResult = $null
    }

    # if $result isnt null then internet is available, otherwise exit out
    if ($checkResult -eq $null) {    
        if($exitOnFailure) { 
            Write-ErrorAndLog "Internet is not available: Please ensure that internet is available for the script to continue."
		    Write-Host "........Press enter to exit........" -ForegroundColor Yellow
            $null = Read-Host
            exit 
        }
        Write-WarningAndLog "Internet is not available"
        return $false
    }
    Write-OutputAndLog "Internet connection check successful."
    return $true
}

Function Update-EnvironmentPath {
    <#
    .DESCRIPTION
    Updates the environment path variable value with the new path if it does not already exists. The method does not saves the updated value
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
        [string] $newPath,
        # Path delimiter
        [Parameter()]
        [string] $delimiter = ";"
    )

    $variableValue = [System.Environment]::GetEnvironmentVariable($variableName, [System.EnvironmentVariableTarget]::Machine)
    $paths = if($variableValue) { $variableValue -split $delimiter } else { @("") }

    if($paths -inotcontains $newPath) {
        # add new path to the start of the path list
        $paths = @($newPath) + $paths
        # remove empty entries
        $paths = $paths | Where-Object {$_}
    }

    $result = [string]::Join($delimiter, $paths)
    return $result
}

Function Download-Package {
    <#
    .DESCRIPTION
    Downloads the installer packages from the url to the local folder. If the installer is already downloaded, then the
    download is aborted unless the force flag is set to true.

    .OUTPUTS
    [string]: Path to the downloaded install package.
    #>
    Param(        
        # Full name of the installer package file which will be saved
        [Parameter(Mandatory)]
        [string] $packageName,
        # Url from where to download the installer package
        [Parameter(Mandatory)]
        [string] $url,
        # Download folder where the installer package will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # Flag which defines if the installer should be downloaded even if it already exists
        [Parameter()]
        [bool] $force = $false
    )

    $packagePath = Join-Path $downloadFolder $packageName
    $shouldDownload = $true
    # if the package already exists then the download flag respects the force flag
    if (Test-Path -path $packagePath) {
        $shouldDownload = $force
    }

    if ($shouldDownload) {
        # check for internet connection before going forward
        Check-Internet -exitOnFailure | Out-Null

        if (Test-Path -Path $packagePath) {
            # at this stage, we need to force download the file
            Remove-Item -Path $packagePath | Out-Null
            Write-OutputAndLog "Removed cache package from $downloadFolder."
        }

        if (-not (Test-Path -Path $downloadFolder)){
            # if folder does not exists then create
            New-Item $downloadFolder -ItemType Directory | Out-Null
            Write-OutputAndLog "Created folder $downloadFolder."
        }

        Write-OutputAndLog "Download url $url..."
        Write-OutputAndLog "Downloading $packageName package..."
        Invoke-WebRequest -Uri $url -OutFile $packagePath 
        Write-OutputAndLog "Package $packageName downloaded to $downloadFolder."
        Write-OutputAndLog ('Downloaded {0} bytes.' -f (Get-Item $packagePath).length)        
    }
    else {
	   # display message that file already exists 
       Write-OutputAndLog "Package $packageName found at $downloadFolder."
    }

    $packagePath
}

Function Install-FromExe {
    <#
    .DESCRIPTION
    Installs the component from the specified executable package and then verifies the installation.

    .OUTPUTS
    None.
    #>
    Param(
        # Name of the package to be installed
        [Parameter(Mandatory)]
        [string] $packageName,
        # Full path of the package along with executable name
        [Parameter(Mandatory)]
        [string] $packagePath,
        # Name of the working directory for the verification command
        [Parameter(Mandatory)]
        [string] $workingDirectory,
        # Post installation verification which should be executed
        [Parameter()]
        [string] $verifyCommand,
        # Installer package arguments
        [Parameter(Mandatory)]
        [string[]] $arguments = @()        
    )

    $currentLocation = Get-Location

    try {
        # if the working directory exists then set the current location to it
        if (Test-Path -Path $workingDirectory) {
            Set-Location $workingDirectory
        }

        # check if the installation is already done
        Write-OutputAndLog "Checking existing $packageName package installation..."
        try{
            $result = Invoke-Expression -Command $verifyCommand -ErrorAction SilentlyContinue
            if ($result -ne $null) {
                Write-OutputAndLog "$packageName package is already installed."
                return;
            }
        }
        catch {
            Write-WarningAndLog "$packageName package is not currently installed."
        }

        # execute installation process
        Write-OutputAndLog "Starting $packageName package installation..."
        Start-Process $packagePath -Wait -ArgumentList $arguments

        # verifying the installation
        Write-OutputAndLog "Verifying $packageName package installation..."
        try{
            $result = Invoke-Expression -Command $verifyCommand -ErrorAction SilentlyContinue        
            if ($result -ne $null) {
                Write-OutputAndLog "$packageName package installed correctly."
                $updatePath = Update-EnvironmentPath -variableName "Path" -newPath $workingDirectory
                [System.Environment]::SetEnvironmentVariable("Path", $updatePath, [System.EnvironmentVariableTarget]::Machine)
                $env:Path = $updatePath
            }
        }
        catch {
            # only throw the error incase there is a valid verification command
            if(-not [string]::IsNullOrEmpty($verifyCommand)) { throw "Installation Error: Installation of package $packageName failed verification" }
        }
        Write-OutputAndLog "$packageName package verification successful."
    }
    finally {
        # roll back the working directory to its original
        Set-Location $currentLocation
    }
}

Function Install-FromMsi {
    <#
    .DESCRIPTION
    Installs the component from the specified msi package and then verifies the installation.

    .OUTPUTS
    None.
    #>
    Param(
        # Name of the package to be installed
        [Parameter(Mandatory)]
        [string] $packageName,
        # Full path of the package along with executable name
        [Parameter(Mandatory)]
        [string] $packagePath,
        # Name of the working directory for the verification command
        [Parameter(Mandatory)]
        [string] $workingDirectory,
        # Post installation verification which should be executed
        [Parameter()]
        [string] $verifyCommand,
        # Installer package arguments
        [Parameter(Mandatory)]
        [string[]] $arguments = @()        
    )

    $currentLocation = Get-Location
    try {
        # if the working directory exists then set the current location to it
        if (Test-Path -Path $workingDirectory) {
            Set-Location $workingDirectory
        }

        # check if the installation is already done
        Write-OutputAndLog "Checking existing $packageName package installation..."
        try{
            $result = Invoke-Expression -Command $verifyCommand -ErrorAction SilentlyContinue        
            if ($result -ne $null) {
                Write-OutputAndLog "$packageName package is already installed."
                return;
            }
        }
        catch {
            Write-OutputAndLog "$packageName package is not currently installed."
        }
        

        # add necessary arguments to install quietly with no UI
        # for no UI /qn, basic UI /qb, reduced UI /qr, full UI /qf
        $argsx = @('/i', $packagePath, '/quiet', '/qb');
        $argsx += $arguments;

        # execute installation process
        Write-OutputAndLog "Starting $packageName package installation..."
        Write-OutputAndLog ('msiexec {0}' -f ($argsx -Join ' '))
        $process = Start-Process msiexec -Wait -NoNewWindow -PassThru -ArgumentList $argsx
        Write-OutputAndLog ("Installation msi process exited with code" + $process.ExitCode)
        # after installation update the environment variable for the powershell session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

        # verifying the installation
        Write-OutputAndLog "Verifying $packageName package installation..."
        try{
            $result = Invoke-Expression -Command $verifyCommand -ErrorAction SilentlyContinue        
            if ($result -ne $null) {
                Write-OutputAndLog "$packageName package installed correctly."
            }
        }
        catch {
            # only throw the error incase there is a valid verification command
            if(-not [string]::IsNullOrEmpty($verifyCommand)) { throw "Installation Error: Installation of package $packageName failed verification" }
        }
    }
    finally {
        $ErrorActionPreference = "Stop"
        # roll back the working directory to its original
        Set-Location $currentLocation
    }
}

Function Install-Perl {
    <#
    .DESCRIPTION
    Installs latest version of Strawberry Perl and then verifies the installation.

    .OUTPUTS
    None.
    #>
    Param(
        # Full path where the Perl installer will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # Full path where the installer will install Perl
        [Parameter(Mandatory)]
        [string] $installFolder,
        # Flag to force download of installer package even if it is available in download folder
        [Parameter(Mandatory)]
        [bool] $forceDownload,
        [Parameter()]
        [string] $architecture = "64"     
    )

    # The script checks for downloads first and then checks for existing installation
    # this is done so that even if the installation is done on the current system
    # the downloaded packages can be used on any other system which is not internet connected

    # Browse the web where perl is downloaded
    $urlPerl="http://strawberryperl.com/"
    # Get version of latest strawberry perl from the web
    Write-OutputAndLog "Getting version of strawberry-perl from $urlPerl..."
    $retVal = ( Invoke-WebRequest $urlPerl ) -Match "href=.*strawberry-perl-([0-9.]+).*" 
    $version = $Matches.1

    # check whether perl version can be gathered from the web or set default
    if ($retVal -eq $true) {
        Write-OutputAndLog "Latest version of Perl is $version"	          
    }
    else {
        $version = "5.32.1.1"
        Write-OutputAndLog "Could not find latest version so defaulting to $version"
    }

    # url link where the perl installation file can be downloaded    
    $urlDownload = "http://strawberryperl.com/download/$version/strawberry-perl-$version-{0}bit.msi" -f $architecture
    
    # download the installer
    $packageDownloadPath = Download-Package -packageName "strawberry-perl.msi" `
        -url $urlDownload `
        -downloadFolder $downloadFolder `
        -force $forceDownload

    # install using the MSI package
    $workingDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    # run the installer via msi package
    Install-FromMsi -packageName "Perl" `
        -packagePath $packageDownloadPath `
        -workingDirectory $workingDirectory `
        -verifyCommand "perl --version" `
        -arguments @(('INSTALLDIR="{0}"' -f $installFolder))
}

Function Install-PerlLib
{
    Param(
        # Full path where the Perl module folder will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # Name of the Perl library to be installed
        [Parameter(Mandatory)]
        [string] $libraryName      
    )

    # this is done because it is possible that Perl was already installed on the system
    # and this script skipped the Perl installation step, so that is why the Perl install
    # path variable can not be used here by default
    Write-OutputAndLog "Getting Strawberry Perl install directory..."
    $installPath = [System.Environment]::GetEnvironmentVariable("PATH").Split(";") | Where-Object { $_ -like "*\perl\bin" }
    
    # if path is null or not a valid path then throw exception as Strawberry Perl is not installed properly
    if ([string]::IsNullOrEmpty($installPath) -or (-not (Test-Path $installPath))) {
        Write-ErrorAndLog "Perl Installation: Please ensure that Strawberry Perl install path is updated in the system environment variable PATH."
		Write-Host "........Press enter to exit........" -ForegroundColor Yellow
		$null = Read-Host
        exit
    }

    $currentLocation = Get-Location
    try {
        Set-Location $downloadFolder
        $libraryFilePrefix = $libraryName.Replace("::", "-")
        # 1. Get the file name of the downloaded module gz from the download folder
        $gzFilePath = (Get-ChildItem -Path $downloadFolder -Filter "$libraryFilePrefix*" -File | Select-Object FullName).FullName
        # 2. Check for internet connection
        if (Check-Internet) {
            # 2.1. Internet available - Backup file if existing and download latest and update the full file name
            # if download fails then revert back to the already backup file
            if($gzFilePath) { 
                $tempBackup = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetFileName($gzFilePath))
                Write-OutputAndLog "Backup the cached install package $gzFilePath"
                Move-Item -Path $gzFilePath -Destination $tempBackup -Force | Out-Null
            }
            try {
                Write-OutputAndLog "Downloading the latest $libraryName package..."
                Invoke-Expression "cpan -g $libraryName" -ErrorAction SilentlyContinue
            }
            catch {
                # there may be warnings but we do not know how to deal with them correctly
                $logMessage = "cpan $libraryName - " + $_.Exception.Message
                Write-WarningAndLog $logMessage                
            }
        }

        $gzFilePath = (Get-ChildItem -Path $downloadFolder -Filter "$libraryFilePrefix*" -File | Select-Object FullName).FullName
        if(-not $gzFilePath) {
            if($tempBackup) {
                $gzFilePath = Join-Path ($downloadFolder) ([System.IO.Path]::GetFileName($tempBackup))
                Move-Item -Path $tempBackup -Destination $gzFilePath -Force | Out-Null
            } 
            else {
                # We get to this stage when file did not exist earlier and:
                # a. internet not available and the  also
                # b. internet available but download failed 
                Write-ErrorAndLog "$libraryName Installation Failed: Please check that you have internet connectivity " + `
                    " or the cache folder has the required installers for the Perl module."
		        Write-Host "........Press enter to exit........" -ForegroundColor Yellow
		        $null = Read-Host
                exit
            }
        }
        else {
            # new file is downloaded so delete the backup if there
            if($tempBackup) {
                Write-OutputAndLog "Removing backup install package from $tempBackup..."
                Remove-Item -Path $tempBackup -Force | Out-Null
            } 
        }
        
        # Install the module from the download folder - cpanm 
        Write-OutputAndLog "Installing latest available $libraryName library from $gzFilePath..."
        try {
            Invoke-Expression "cpanm --notest $gzFilePath" -ErrorAction SilentlyContinue
        } catch {
            $logMessage = "cpan $libraryName - " + $_.Exception.Message
            Write-WarningAndLog $logMessage

            try {
                Write-OutputAndLog "Retrying installation of $libraryName library with force..."
                Invoke-Expression "cpanm --notest --force $gzFilePath" -ErrorAction SilentlyContinue
            }
            catch {
                $logMessage = "cpan $libraryName - " + $_.Exception.Message
                Write-WarningAndLog $logMessage
            }
        }
    }
    finally {
        Set-Location $currentLocation
    }
}

Function Install-OracleClient
{
    <#
    .DESCRIPTION
    Installs the provided Oracle InstantClient and then verifies the installation.

    .OUTPUTS
    None
    #>
    Param(
        # Full path where the Oracle client package will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # Full path where the package will install Oracle client
        [Parameter(Mandatory)]
        [string] $installFolder,
        # [Deprecated]: Flag to force download of installer package even if it is available in download folder
        [Parameter(Mandatory)]
        [bool] $forceDownload,
        # The OS architecture. By default it is set to 64bit but can be 32 for 32bit OS
        [Parameter()]
        [string] $architecture = "64",
        # List of folders which needs to be scanned to find the already existing module installer packages
        [Parameter()]
        [string[]] $seekFolders = @()       
    )

    # list of paths where to search for the instant client zip files
    $seekPaths = @($downloadFolder) + $seekFolders

    $basicModuleInstallPath = Install-OracleClientModule -downloadFolder $downloadFolder `
            -installFolder $installFolder `
            -modulePrefix "instantclient-basic" `
            -moduleCheckItemName "oci.dll" `
            -architecture $architecture `
            -seekFolders $seekPaths

    $sdkModuleInstallPath = Install-OracleClientModule -downloadFolder $downloadFolder `
            -installFolder $installFolder `
            -modulePrefix "instantclient-sdk" `
            -moduleCheckItemName "sdk" `
            -architecture $architecture `
            -seekFolders $seekPaths

    $sqlplusModuleInstallPath = Install-OracleClientModule -downloadFolder $downloadFolder `
            -installFolder $installFolder `
            -modulePrefix "instantclient-sqlplus" `
            -moduleCheckItemName "sqlplus.exe" `
            -architecture $architecture `
            -seekFolders $seekPaths

    # if any of the module paths is null then the overall installation has failed.
    if($basicModuleInstallPath -eq $null -or $sdkModuleInstallPath -eq $null -or $sqlplusModuleInstallPath -eq $null) {
        Write-ErrorAndLog "Oracle Client installation failed. Please check the above warnings for required actions."
        Write-Host "........Press enter to exit........" -ForegroundColor Yellow
		$null = Read-Host
        exit
    }

    # find the path which needs to be updated in the environment variable
    # use the basic module install folder as the base
    $oracleInstallFolder = $basicModuleInstallPath

    Write-OutputAndLog "Updating environment variables which may take time."
    Write-OutputAndLog "Updating ORACLE_HOME_ORA2PG environment variable..."
    [System.Environment]::SetEnvironmentVariable("ORACLE_HOME_ORA2PG", $oracleInstallFolder, [System.EnvironmentVariableTarget]::Machine)
    $env:ORACLE_HOME_ORA2PG = $oracleInstallFolder
    $env:ORACLE_HOME = $oracleInstallFolder
    
    Write-OutputAndLog "Updating LD_LIBRARY_PATH environment variable..."
    $updatedPath = Update-EnvironmentPath -variableName "LD_LIBRARY_PATH" -newPath $oracleInstallFolder
    [System.Environment]::SetEnvironmentVariable("LD_LIBRARY_PATH", $updatedPath, [System.EnvironmentVariableTarget]::Machine)
    $env:LD_LIBRARY_PATH = $updatedPath
    
    Write-OutputAndLog "Updating PATH environment variable..."
    $updatedPath = Update-EnvironmentPath -variableName "Path" -newPath $oracleInstallFolder
    [System.Environment]::SetEnvironmentVariable("Path", $updatedPath, [System.EnvironmentVariableTarget]::Machine)        
    $env:Path = $updatedPath

    return $oracleInstallFolder
}

Function Install-OracleClientModule {
    <#
    .DESCRIPTION
    Checks, downloads and installs the Oracle Instant Client modules.

    .OUTPUTS
    [string]: Installed path for the OCI module
    #>
    Param(
        # Full path where the Oracle client package will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # Full path where the package will install Oracle client
        [Parameter(Mandatory)]
        [string] $installFolder,
        # Prefix for the module name which will need to be searched and installed. Without wildcard characters.
        [Parameter(Mandatory)]
        [string] $modulePrefix,
        # Name of the file or folder which needs to be checked to confirm if the module is already installed
        [Parameter(Mandatory)]
        [string] $moduleCheckItemName,
        # The OS architecture. By default it is set to 64bit but can be 32 for 32bit OS
        [Parameter()]
        [string] $architecture = "64",
        # List of folders which needs to be scanned to find the already existing module installer packages
        [Parameter()]
        [string[]] $seekFolders = @()    
    )

    # The script checks for downloads first and then checks for existing installation
    # this is done so that even if the installation is done on the current system
    # the downloaded packages can be used on any other system which is not internet connected
    Write-OutputAndLog "Check install for Oracle Client Module $modulePrefix"

    # check for the install package in existing files and if not found then 
    # check if the latest package can be downloaded from the internet
    ################    
    Write-OutputAndLog "Searching for Oracle Client Module $modulePrefix installer package..."
    foreach($p in $seekPaths) {
        $module = Get-ChildItem -Path $p -Filter "$modulePrefix*.zip" -File -Recurse -ErrorAction SilentlyContinue
        # if files are found then break the loop, otherwise continue to check other seek paths
        if($module -ne $null) {
            Write-OutputAndLog ("Oracle Client Module $modulePrefix installer package found at " + $module.FullName)
            break
        }
    }

    # If the seek was successful then $module is not null
    if($module -ne $null) {
        # copy the packages from seek folder to the download folder if it is different
        $modulePackagePath = Join-Path $downloadFolder "$modulePrefix.zip"
        if ($modulePackagePath -ine $module.FullName) {
            Write-OutputAndLog ("Copying Oracle Client Module $modulePrefix from " + $module.FullName + " to $modulePackagePath...")
            Copy-Item -Path ($module.FullName) -Destination $modulePackagePath -Force | Out-Null
        }       
    }
    else {
        # if file is not found in seek paths then check if the file can be downloaded from the internet
        $downloadUrl = Get-OracleClientDownloadUrl -modulePrefixName $modulePrefix -architecture $architecture
        if ($downloadUrl -ne $null -and (Check-Internet)) {
            $modulePackagePath = Join-Path $downloadFolder "$modulePrefix.zip"
            Write-OutputAndLog ("Downloading Oracle Client Module from " + $downloadUrl + "...")
            Invoke-WebRequest -Uri $downloadUrl -OutFile $modulePackagePath
            Write-OutputAndLog ("Oracle Client Module download complete.")
        }                    
    }
    ################

    # check if instant client is already installed
    ################    
    $orclHomePath = [System.Environment]::GetEnvironmentVariable('ORACLE_HOME_ORA2PG', [System.EnvironmentVariableTarget]::Machine)
    if($orclHomePath -and (Test-Path -Path $orclHomePath)) {
        # check if desired file or folder is already installed
        $checkItem = (Get-Childitem -Path $orclHomePath -Include $moduleCheckItemName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)
        if($checkItem -ne $null) {
            Write-OutputAndLog "Oracle Client Module item $moduleCheckItemName is already installed under $orclHomePath."
            return $orclHomePath
        }
    }
    ################

    # if the package files are found/downloaded then install the packages in the install folder
    # if not then inform the user that they need to get the required packages 
    if($modulePackagePath -ne $null) {
        Write-OutputAndLog "Extracting file $modulePackagePath..."
        Expand-Archive -LiteralPath $modulePackagePath -DestinationPath $installFolder -Force
        # do not search recursively. We want to find the folde just in the install folder
        $oracleInstallFolder = (Get-ChildItem -Path $installFolder -Filter "instantclient*" -Directory `
            | Sort-Object LastWriteTime -Descending `
            | Select -First 1).FullName
        Write-OutputAndLog "Oracle Client Module installed at $oracleInstallFolder"
        return $oracleInstallFolder
    }
    else {
        # install files are not found and need to ask the user to download the files and place them in the
        # same folder as the script
        Write-WarningAndLog "Oracle Client Module $modulePrefix is required."
        Write-WarningAndLog "Please download $modulePrefix*.zip for Windows from " + `
            "https://download.oracle.com/otn/nt/instantclient";
        Write-WarningAndLog "Please download the file and put it in zip format in the same folder as this script."
        Write-WarningAndLog "Re-run the script to continue with the installation."
		return
    }
}

Function Get-OracleClientDownloadUrl{
    <#
    .DESCRIPTION
    Gets the download url for the latest Oracle Instant Client from Oracle webpage

    .OUTPUTS
    None
    #>
    Param(
        # Prefix for the module name which will need to be searched in the url directory.
        [Parameter(Mandatory)]
        [string] $modulePrefixName,
        [Parameter()]
        [string] $architecture = "64"       
    )

    $orclClientUrl = "https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html"
    if ($architecture -eq "32") {
        $orclClientUrl = "https://www.oracle.com/database/technologies/instant-client/microsoft-windows-32-downloads.html"
    }
    $clientMatch = (Invoke-WebRequest -Uri $orclClientUrl).Content -match "//download.oracle.com/otn.*/instantclient/.*/$modulePrefixName-windows.*zip'" 
    if ($clientMatch) {
	    $clientModuleDownloadUrl = "https:" + ($Matches.0).Replace("'", "")
        Write-OutputAndLog "Latest Oracle Instant Client download url $clientModuleDownloadUrl..."
        return $clientModuleDownloadUrl
    }
    else {
        Write-ErrorAndLog "Unable to find Oracle Instant Client module $modulePrefixName latest download url."
    }
}

Function Install-VCPDependency {
    <#
    .DESCRIPTION
    Installs the VC++ dependencies for the Oracle instant client.

    .OUTPUTS
    None
    #>
    Param(
        # Full path where the Oracle client package will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # Full path where the Oracle client is installed
        [Parameter(Mandatory)]
        [string] $orcInstallFolder,
        # Flag to force download of installer package even if it is available in download folder
        [Parameter(Mandatory)]
        [bool] $forceDownload,
        [Parameter()]
        [string] $architecture = "64"       
    )

    # get oracle instant client version
    $ociFolderName = [System.IO.Path]::GetFileNameWithoutExtension($orcInstallFolder)
    $ociVersion = ($ociFolderName -split "_")[1]

    $version = -1
    $checkDependeniesOnly = $false
    # if the version information is not available then just check for dependencies
    # and inform the user to make sure that the correct dependencies are installed
    if(-not ($ociVersion -ne $null -and [int]::TryParse($ociVersion, [ref] $version))) {     
        Write-OutputAndLog "Not able to identify the version of installed Oracle client from " + `
            "ORACLE_HOME. As a result could not identify the required VC++ redistributable dependencies"
        Write-OutputAndLog "For Oracle client >= 19 : Microsoft Visual C++ Redistributable packages for Visual Studio 2017"
        Write-OutputAndLog "https://aka.ms/vs/17/release/vc_redist.x$architecture.exe"
        Write-OutputAndLog "For Oracle client < 19  : Microsoft Visual C++ Redistributable packages for Visual Studio 2013"
        Write-OutputAndLog ("https://aka.ms/highdpimfc2013x{0}enu" -f $architecture)
        $checkDependeniesOnly = $true
    }

    # checking the installed version of vc_redist
    Write-OutputAndLog "Checking Microsoft Visual C++ redistributable installations..."
    $installedList = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* `
        | Select-Object DisplayName, Publisher, InstallDate | Where-Object {$_.DisplayName -like $("Microsoft Visual C++*")}
    # if only check then just display the installed versions
    if ($checkDependeniesOnly) {
        Write-OutputAndLog "Installed packages:"
        foreach ($d in $installedList) {
            Write-OutputAndLog ("> " + $d.DisplayName)
        }
        Write-OutputAndLog "Please validate the requirements and ensure that the required packages are installed"

        # returns from the function and below installer code is not executed
        return
    }

    # The script checks for downloads first and then checks for existing installation
    # this is done so that even if the installation is done on the current system
    # the downloaded packages can be used on any other system which is not internet connected

    # we know the version of OIC and the version of VC++ distributable to be installed
    if ($version -lt 19) { 
        $vcppDownloadUrl = ("https://aka.ms/highdpimfc2013x{0}enu" -f $architecture) 
        $pkgName = "vc_redist.2013.x$architecture.exe"
    } 
    else { 
        $vcppDownloadUrl = "https://aka.ms/vs/17/release/vc_redist.x$architecture.exe"
        $pkgName = "vc_redist.2015-2022.x$architecture.exe" 
    }

    # download the package if not already existing
    $packagePath = Download-Package -packageName $pkgName `
                            -url $vcppDownloadUrl `
                            -downloadFolder $downloadFolder `
                            -force $forceDownload

    # check for existing installation. If the desired installation already exists then abort the installation
    $vcppVersion = if ($version -lt 19) { @("2013") } else { @("2017","2019","2022") }
    $checkResult = $installedList | Where-Object { ($_.DisplayName -split " ")[3] -in $vcppVersion }
    # if result is not null that means the desired version is alreay installed
    if ($checkResult -ne $null -and $checkResult.Length -gt 0) {
        $message = "Microsoft Visual C++ Redictribution ver " + [string]::Join(",", $vcppVersion) + " already installed"
        Write-OutputAndLog $message
        return
    }
    
    # install the VC++ package
    $workingDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    Install-FromExe -packageName "Microsoft Visual C++" `
        -packagePath $packagePath `
        -workingDirectory $workingDirectory `
        -arguments @('/install', '/quiet', '/norestart')

}

Function Install-Ora2Pg
{
    <#
    .DESCRIPTION
    Installs latest version of Ora2Pg tool and then verifies the installation.

    .OUTPUTS
    None
    #>
    Param(
        # Full path where the Ora2Pg installer will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # Full path where the Ora2Pg package will be installed
        [Parameter(Mandatory)]
        [string] $installFolder,
        # Flag to force download of installer package even if it is available in download folder
        [Parameter(Mandatory)]
        [bool] $forceDownload       
    )
    # Ora2Pg release path to get the latest version
    $o2pHomeUrl = "https://github.com/darold/ora2pg/releases"

    # downloading the latest bits from github
    $version = "v23.1"
    $versionMatch = (Invoke-WebRequest -Uri $o2pHomeUrl).Content -Match "`"https://github.com/darold/ora2pg/releases/expanded_assets/.*?`" "
    if ($versionMatch) {
	    $uriParts = (($Matches.0).Trim().Replace("`"", "")) -split "/"
        $version = ($uriParts[$uriParts.Length - 1]).Trim()
        Write-OutputAndLog "Latest Ora2Pg version $version detected..."
    }
    else {
        Write-OutputAndLog "Unable to find latest Ora2Pg version. Reverting back to v23.1"    
    }

    $o2pDownloadUrl = "https://github.com/darold/ora2pg/archive/refs/tags/$version.zip"
    $packagePath = Download-Package -packageName "Ora2Pg-Install-$version.zip" `
                    -url $o2pDownloadUrl `
                    -downloadFolder $downloadFolder `
                    -force $forceDownload

    # check if Ora2Pg is already installed
    # check if the installation is already done
    Write-OutputAndLog "Checking existing Ora2Pg installation..."
    try{
        $result = Invoke-Expression -Command "ora2pg --version" -ErrorAction SilentlyContinue        
        if ($result -ne $null) {
            Write-OutputAndLog "Ora2Pg is already installed."
            Write-OutputAndLog "In order to upgrade it, please delete ora2pg.bat under strawberry-perl bin directory."
            Write-OutputAndLog "Use `"where ora2pg`" in command window (not powershell) to find the install directory."
            return;
        }
    }
    catch {
        Write-OutputAndLog "Ora2Pg is not currently installed."        
    }

    # Before running the installation - First check the required Environment Variables
    Write-OutputAndLog "Checking required environment variable settings..."
    $env:ORACLE_HOME = [System.Environment]::GetEnvironmentVariable("ORACLE_HOME_ORA2PG", [System.EnvironmentVariableTarget]::Machine)
    if ($env:ORACLE_HOME -eq $null -or -not (Test-Path $env:ORACLE_HOME)) { throw "ORACLE_HOME not set to a valid value" }
    if ($env:LD_LIBRARY_PATH -eq $null -or -not $env:LD_LIBRARY_PATH.Contains($env:ORACLE_HOME)) { throw "LD_LIBRARY_PATH not point to ORACLE_HOME" }
    if ($env:Path -eq $null -or -not $env:Path.Contains($env:ORACLE_HOME)) { throw "PATH does not point to ORACLE_HOME" }

    # extract the ora2pg code to the install folder
    Expand-Archive -LiteralPath $packagePath -DestinationPath $installFolder -Force
    # this is done as the inner folder name keeps changing per version
    $codePath = (Get-childitem -Path $installFolder -File -Filter "Makefile.PL" -Recurse | Select -First 1).FullName
    $ora2pgCodePath = [System.IO.Path]::GetDirectoryName($codePath)

    # build the tool in the workspace folder itself and install it
    $currentLocation = Get-Location
    try {
        Write-OutputAndLog "Switching working directory to $ora2pgCodePath..."
        Set-Location $ora2pgCodePath
        $ErrorActionPreference = "Continue"

        # modify Makefile.PL to change GPLv3 to gpl_3 as the licensing clause which causes error
        # during perl make file stage
        # https://metacpan.org/pod/CPAN::Meta::Spec -> look for "The following list of license strings are valid"
        $fileContent = Get-Content "Makefile.PL"
        $fileContent = $fileContent.Replace("'GPLv3'", "'gpl_3'")
        Set-Content -Path "Makefile.PL" -Value $fileContent

        perl Makefile.PL
        gmake
        gmake install

        # update the ora2pg expected install path
        $updatedPath = Update-EnvironmentPath -variableName "Path" -newPath $ora2pgCodePath
        [System.Environment]::SetEnvironmentVariable("Path", $updatedPath, [System.EnvironmentVariableTarget]::Machine)
        $env:Path = $updatedPath
    }
    finally {
        $ErrorActionPreference = "Stop"
        Write-OutputAndLog "Switching back working directory to $currentLocation..."
        Set-Location $currentLocation
    }    

    # validate Ora2Pg installation
    Write-OutputAndLog "Validating Ora2Pg installation..."
    try{
        $result = Invoke-Expression -Command "ora2pg --version" -ErrorAction SilentlyContinue        
        if ($result -ne $null) {
            Write-OutputAndLog "Ora2Pg installed successfully."            
        }
    }
    catch {
        throw "Installation Error: Installation of Ora2Pg failed verification"       
    }
}

Function Run-PostInstall
{
    <#
    .DESCRIPTION
    Runs post installation modifications as required by the deployment.

    .OUTPUTS
    None
    #>

    # this is a hard coded path in Ora2Pg installation
    $ora2pgDocRoot = "C:\ora2pg"
    # https://github.com/darold/ora2pg/issues/1445
    # FATAL: file C:\ora2pg\ora2pg.conf.dist does not exists
    # RESOLUTION: create a copy of ora2pg_conf.dist as ora2pg.conf.dist so that it works right now
    # as well as when this change is propogated
    Write-OutputAndLog "Applying resolution for v23 issue 1445..."
    $confDistFile = Join-Path $ora2pgDocRoot "ora2pg_conf.dist"
    $oldConfDistFile = Join-Path $ora2pgDocRoot "ora2pg.conf.dist"
    # if new file exists always override the old file name
    if((Test-Path $confDistFile)){
        Copy-Item -Path $confDistFile -Destination $oldConfDistFile -Force
    }
    Write-OutputAndLog "Resolution for v23 issue 1445 applied."
}

###################################### Permission Check ######################################
$edition = $PSVersionTable
if(-not ($edition.PSEdition -eq "Desktop" -or ($edition.PSEdition -eq "Core" -and $edition.Platform  -eq "Windows"))) {
    Write-Host "ALERT!!!" -ForegroundColor Red
    Write-Host "Can not run installation script." -ForegroundColor Red
    Write-Host "This script is targeted for Windows Operating System only" -ForegroundColor Red
    exit
}

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ALERT!!!" -ForegroundColor Red
    Write-Host "Can not run installation script." -ForegroundColor Red
    Write-Host "Please run the script under administrative context. Launch powershell with " + `
     "`"RunAsAdministrator`" option." -ForegroundColor Red
    exit
}
###################################### Variable Initialization #################################
# environment setting
$Global:Logfile = $null
$ErrorActionPreference = "Stop"

$timeStamp = [System.DateTime]::Now.ToString("yyyyMMddHHmmss")
$scriptRootPath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
# root location for all installations
$fullInstallFolderPath = Validate-Path -Path $InstallFolderPath -RootPath $scriptRootPath -ErrorAction Stop
# root location for the workspace folder
$fullWorkspaceFolderPath = Validate-Path -Path $WorkspaceFolderName -RootPath $scriptRootPath -ErrorAction Stop

# workspace location to download ora2pg
$ora2pgWkspPath = Validate-Path -Path "Ora2Pg" -RootPath $fullWorkspaceFolderPath -ErrorAction Stop
# install location to download ora2pg
$ora2pgInstallPath = Validate-Path -Path "Ora2Pg" -RootPath $fullInstallFolderPath -ErrorAction Stop

# workspace location to download Oracle client 
$orclClientWkspPath = Validate-Path -Path "Oracle" -RootPath $fullWorkspaceFolderPath -ErrorAction Stop
# install location to install Oracle client 
$orclClientInstallPath = Validate-Path -Path "Oracle" -RootPath $fullInstallFolderPath -ErrorAction Stop
# workspace location for the VC++ redistributable package
$vcpPackageWkspPath = Validate-Path -Path "VCPP" -RootPath $fullWorkspaceFolderPath -ErrorAction Stop

# workspace location to download git exe
$perlWkspPath = Validate-Path -Path "Perl" -RootPath $fullWorkspaceFolderPath -ErrorAction Stop
# install location for git exe
$perlInstallPath = Validate-Path -Path "Perl" -RootPath $fullInstallFolderPath -ErrorAction Stop

# machine processor architecture
$arch = If ($Is32bit) {"32"} Else {"64"}

# log file path
$Global:Logfile = [System.IO.Path]::Combine($fullWorkspaceFolderPath, "installora2pg-$timeStamp.log")

###################################### Script Main #################################
# acquire lock on the temp file so only one instance of the script can run
Acquire-Lock
# setting the SSL/TSL versions specifically to avoid system default issues
[Net.ServicePointManager]::SecurityProtocol = 
  [Net.SecurityProtocolType]::Tls12 -bor `
  [Net.SecurityProtocolType]::Tls11 -bor `
  [Net.SecurityProtocolType]::Tls

try {
    # Install the Oracle instant client
    $seekFolderPaths = @(".\", $scriptRootPath)
    $oicFolder = Install-OracleClient -downloadFolder $orclClientWkspPath `
                    -installFolder $orclClientInstallPath `
                    -forceDownload $false `
                    -architecture $arch `
                    -seekFolders $seekFolderPaths
    
    # Install VC++ dependency for Oracle client
    Install-VCPDependency -downloadFolder $vcpPackageWkspPath `
            -orcInstallFolder $oicFolder `
            -forceDownload $false `
            -architecture $arch
    
    # Install Strawberry Perl framework 
    Install-Perl -downloadFolder $perlWkspPath `
            -installFolder $perlInstallPath `
            -forceDownload $false `
            -architecture $arch    
    
    # Install Strawberry Perl libraries for Oracle and Postgresql
    # https://strawberryperl.com/release-notes/5.32.0.1-64bit.html
    Install-PerlLib -downloadFolder $perlWkspPath `
            -libraryName "DBD::Oracle"
    Install-PerlLib -downloadFolder $perlWkspPath `
            -libraryName "DBD::Pg"
    
    # Install Ora2Pg tool
    Install-Ora2Pg -downloadFolder $ora2pgWkspPath `
            -installFolder $ora2pgInstallPath `
            -forceDownload $false
    
    Run-PostInstall   
    
    if ($DeleteWorkspace) {
        Remove-Item -Path $fullWorkspaceFolderPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-OutputAndLog "INSTALLATION SUCCESSFUL :)"

    ################ ADS Extension for Oracle Assessment ################
    for($x=0; $x -lt 2; $x=$x+1) { Write-Host " " }
    Write-Host "The Database Migration Assessment for Oracle extension" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host "The Database Migration Assessment for Oracle extension in Azure Data Studio helps" `
        "you assess an Oracle workload for migrating to SQL and PostgreSQL. The extension identifies an appropriate" `
        "Azure SQL and Azure PostgreSQL targets with right-sizing recommendations, and how complex the migration can be."
    Write-Host "https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/database-migration-assessment-for-oracle-extension?view=sql-server-ver16"
    Write-Host " "
    
    $titleText = "For configuring the ADS extension to perform code complexity assessment for PostgreSQL target, use the following configuration values:"
    $o2pfolder = (Get-childitem -Path $ora2pgInstallPath -File -Filter "Makefile.PL" -Recurse | Select-Object -First 1).FullName
    $o2pfolder = [System.IO.Path]::GetDirectoryName($o2pfolder)
    $o2pfolderText = ("Ora2Pg Installation Path  : " + $o2pfolder)
    $oracleHomeText = ("Oracle Home Path: " + $env:ORACLE_HOME)

    Write-Host $titleText
    Write-Host $oracleHomeText -ForegroundColor Yellow
    Write-Host $o2pfolderText -ForegroundColor Yellow
    if($Global:Logfile -ne $null) {
        Add-content "$Global:Logfile" -value $titleText
        Add-content "$Global:Logfile" -value $oracleHomeText
        Add-content "$Global:Logfile" -value $o2pfolderText
    }
    for($x=0; $x -lt 2; $x=$x+1) { Write-Host " " }
    ################ ADS Extension for Oracle Assessment ################
}
catch {
    Write-ErrorAndLog -exception $_.Exception    
    Write-ErrorAndLog "INSTALLATION FAILED :("
}
finally {
    Write-Host ("Log file generated  : " + $Global:Logfile) -ForegroundColor Green
    Safe-Exit
}
