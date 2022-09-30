###############################################################################################
#/***This Artifact belongs to the Microsoft Engineering Team***/
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# $Id: installora2pg-lnx.ps1 17 2021-02-02 10:12:44Z sgaur $
# $Date: 2022-09-21 (Wed, 21 Sep 2022) $
# $Revision: 20 $
# $Author: sgaur $ 
# $Contributor: vbpahlawa $
###############################################################################################

<#
.SYNOPSIS 
Installs ora2pg tool on a Ubuntu machine along with its dependencies.

.DESCRIPTION
The script checks, downloads, checks and installs ora2pg and its dependencies. The different dependencies are downloaded 
from the internet. 

.PARAMETER Is32bit
(Optional) [switch] Specifies if the machine processor architecture is 64bit or 32bit. If set then it means machine is 32bit.
Default Value: False
#>

param (
    [Parameter()][switch]$Is32bit = $false
)

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
        Write-OutputAndLog 'Checking for internet connection...'
        $checkResult = Invoke-WebRequest 'http://microsoft.com' -ErrorAction SilentlyContinue
    }
    catch {
        Write-ErrorAndLog -exception $_.Exception
        $checkResult = $null
    }

    # if $result isnt null then internet is available, otherwise exit out
    if ($checkResult -eq $null) {    
        if($exitOnFailure) { 
            Write-ErrorAndLog 'Internet is not available: Please ensure that internet is available for the script to continue.'
		    Write-Host '........Press enter to exit........' -ForegroundColor Yellow
            $null = Read-Host
            exit 
        }
        Write-WarningAndLog 'Internet is not available'
        return $false
    }
    Write-OutputAndLog 'Internet connection check successful.'
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
        [string] $delimiter = ":"
    )

    $variableValue = [System.Environment]::GetEnvironmentVariable($variableName)
    $paths = if($variableValue) { $variableValue -split $delimiter } else { @("") }

    if($paths -inotcontains $newPath) {
        # add new path
        $paths = $paths + @($newPath)
        # remove empty entries
        $paths = $paths | ? {$_}
    }

    $result = [string]::Join($delimiter, $paths)
    return $result
}

Function Install-Prerequisites {
    <#
    .DESCRIPTION
    Installs all the required tools for the installation

    .OUTPUTS
    None
    #>
    Write-OutputAndLog "Starting pre-requisite check..."
    Invoke-Expression "sudo apt-get install libdbi-perl" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt-get install alien dpkg-dev debhelper build-essential" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt-get install libaio1" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt-get install make" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt-get install alien" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt-get install rpm" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt-get install libpq-dev" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt-get install libwww-perl" -ErrorAction SilentlyContinue
    Invoke-Expression "sudo apt install cpanminus"  -ErrorAction SilentlyContinue
    # other way of installing cpanm
    # Invoke-Expression "curl -L https://cpanmin.us | perl - --sudo App::cpanminus" -ErrorAction SilentlyContinue 
    Write-OutputAndLog "Prerequisite check completed." -ErrorAction SilentlyContinue
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
        Write-OutputAndLog "Package $packageName downloaded to $packagePath."
        Write-OutputAndLog ('Downloaded {0} bytes.' -f (Get-Item $packagePath).length)        
    }
    else {
	   # display message that file already exists 
       Write-OutputAndLog "Package $packageName found at $downloadFolder."
    }

    $packagePath
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

    $orclClientUrl = 'https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html'
    if ($architecture -eq "32") {
        $orclClientUrl = 'https://www.oracle.com/database/technologies/instant-client/linux-x86-32-downloads.html'
    }

    $clientMatch = (Invoke-WebRequest -Uri $orclClientUrl).Content -match "//download.oracle.com/otn.*/linux/instantclient/.*/oracle-" + $modulePrefixName + "-.*rpm'"
    if ($clientMatch) {
	    $clientModuleDownloadUrl = 'https:' + ($Matches.0).Replace("'", "")
        Write-OutputAndLog "Latest Oracle Instant Client download url $clientModuleDownloadUrl..."
        return $clientModuleDownloadUrl
    }
    else {
        Write-ErrorAndLog "Unable to find Oracle Instant Client module $modulePrefixName latest download url."
    }
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
        # Prefix for the module name which will need to be searched and installed. Without wildcard characters.
        [Parameter(Mandatory)]
        [string] $modulePrefix,
	    # Module key with which it is installed by the rpm package.
        [Parameter(Mandatory)]
        [string] $packageKey,
        # The OS architecture. By default it is set to 64bit but can be 32 for 32bit OS
        [Parameter()]
        [string] $architecture = "64"    
    )
	
	$packageName = "$packageKey.rpm"
	$url = Get-OracleClientDownloadUrl -modulePrefixName $modulePrefix
	$packagePath = Download-Package -packageName $packageName -url $url -downloadFolder $downloadFolder
	
	# check existing installation and if needed install the package
	$pkgListing = Invoke-Expression "sudo dpkg -l '$packageKey'"
	if ($pkgListing -eq $null) {
		# install the package	
		Write-OutputAndLog "Package $packageKey not found so initiating installation..."	
		Invoke-Expression "sudo alien -i $packagePath" | Out-Null
        
        # check the install for success
        $pkgListing = Invoke-Expression "sudo dpkg -l '$packageKey'" -ErrorAction SilentlyContinue
        if($pkgListing -eq $null) {
            throw "Installation failed for Oracle InstantClient module $modulePrefix"
        }
	}
	else {
		$installedItem = $pkgListing[$pkgListing.Count - 1]
		Write-OutputAndLog "Already installed: $installedItem"
	}
	
	Write-OutputAndLog "Package $packageKey installation successful."	
}

Function Install-OracleClient
{
    <#
    .DESCRIPTION
    Installs the provided Oracle InstantClient and then verifies the installation.

    .OUTPUTS
    [string] ORACLE_HOME installation location
    #>
    Param(
        # Full path where the Oracle client package will be downloaded
        [Parameter(Mandatory)]
        [string] $downloadFolder,
        # The OS architecture. By default it is set to 64bit but can be 32 for 32bit OS
        [Parameter()]
        [string] $architecture = "64"
    )

    Install-OracleClientModule -downloadFolder $downloadFolder `
        -modulePrefix "instantclient-basic" `
        -packageKey "oracle-instantclient-basic" `
        -architecture $architecture

    Install-OracleClientModule -downloadFolder $downloadFolder `
        -modulePrefix "instantclient-devel" `
        -packageKey "oracle-instantclient-devel" `
        -architecture $architecture

    Install-OracleClientModule -downloadFolder $downloadFolder `
        -modulePrefix "instantclient-sqlplus" `
        -packageKey "oracle-instantclient-sqlplus" `
        -architecture $architecture

    $pkgFileListing = Invoke-Expression "sudo dpkg -L 'oracle-instantclient-basic'" -ErrorAction SilentlyContinue
    if($pkgFileListing -eq $null) { throw "Oracle InstantClient installation failed. Basic client files not available." }
    $checkFile = $pkgFileListing | Where-Object { $_ -like "*libociei.so" } | Select-Object -First 1
    if($checkFile -eq $null) { throw "Oracle InstantClient installation failed. Check file not available." }
    
    # getting the environment variable values
    $orclLdLibPath = [System.IO.Path]::GetDirectoryName($checkFile)
    $orclHomePath = [System.IO.Path]::GetDirectoryName($orclLdLibPath)
    
    # setting the environment variable - ORACLE_HOME
    $env:ORACLE_HOME = $orclHomePath 
    Write-Host $env:ORACLE_HOME
    
    # setting the environment variable - LD_LIBRARY_PATH
    $updatedPath = Update-EnvironmentPath -variableName "LD_LIBRARY_PATH" -newPath $orclLdLibPath
    $env:LD_LIBRARY_PATH = $updatedPath
    Write-Host $env:LD_LIBRARY_PATH

    # setting the environment variable - PATH
    $updatedPath = Update-EnvironmentPath -variableName "PATH" -newPath $orclHomePath
    $env:PATH = $updatedPath
    Write-Host $env:PATH

    return $orclHomePath
}

Function Install-Perl {
    <#
    .DESCRIPTION
    Installs latest version of Strawberry Perl and then verifies the installation.
    Ubuntu comes with the default installation of Perl and script only checks the version.

    .OUTPUTS
    None.
    #>

    $perlVersion = Invoke-Expression "perl --version"
    if($perlVersion -eq $null) { 
        Write-WarningAndLog "Perl installation not detected on the system."
        Write-OutputAndLog "Starting Perl installation..."
        Invoke-Expression "sudo apt-get update"
        Invoke-Expression "sudo apt-get install perl"
        
        $perlVersion = Invoke-Expression "perl --version" -ErrorAction SilentlyContinue
        if($perlVersion -eq $null) { throw "Perl installation failed." }

        Write-OutputAndLog "Perl installation successful -  $perlVersion"
    }
    else { Write-OutputAndLog "Perl installation detected - $perlVersion" }
}

Function Install-PerlLib()
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
    Write-OutputAndLog "Getting Perl install status..."
    $perlVersion = Invoke-Expression "perl --version" -ErrorAction SilentlyContinue
    if($perlVersion -eq $null) {
        Write-ErrorAndLog "Perl Installation: Could not find Perl installation. Please install Perl and try again."
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
        if ($env:ORACLE_HOME -eq $null -or -not (Test-Path $env:ORACLE_HOME)) { Write-WarningAndLog "ORACLE_HOME not set to a valid value" }
        if ($env:LD_LIBRARY_PATH -eq $null -or -not $env:LD_LIBRARY_PATH.Contains($env:ORACLE_HOME)) { Write-WarningAndLog "LD_LIBRARY_PATH not point to ORACLE_HOME" }
        try {
            Invoke-Expression "sudo cpanm --notest --force $gzFilePath" -ErrorAction SilentlyContinue
        } catch {
            $logMessage = "cpan $libraryName - " + $_.Exception.Message
            Write-WarningAndLog $logMessage

            try {
                Write-OutputAndLog "Retrying installation of $libraryName library with force..."
                Invoke-Expression "sudo cpanm --notest --force $gzFilePath" -ErrorAction SilentlyContinue
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
        [string] $installFolder       
    )
    # Ora2Pg release path to get the latest version
    $o2pHomeUrl = "https://github.com/darold/ora2pg/releases"

    # downloading the latest bits from github
    $version = "v23.1"
    $versionMatch = (Invoke-WebRequest -Uri $o2pHomeUrl).Content -Match "`"https://github.com/darold/ora2pg/releases/expanded_assets/.*`" "
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
                    -downloadFolder $downloadFolder

    # check if Ora2Pg is already installed
    # check if the installation is already done
    Write-OutputAndLog "Checking existing Ora2Pg installation..."
    try{
        $result = Invoke-Expression -Command "ora2pg --version" -ErrorAction SilentlyContinue        
        if ($result -ne $null) {
            Write-OutputAndLog "Ora2Pg is already installed."
            ##### Feedback - Always upgrade Ora2Pg so that latest ORACLE_HOME is incorporated
            #Write-OutputAndLog "In order to upgrade it, please delete ora2pg.sh under perl bin directory."
            #Write-OutputAndLog "Use `"which ora2pg`" in unix shell (not powershell) to find the install directory."
            #return;

            $codePath = (Get-childitem -Path $installFolder -File -Filter "Makefile.PL" -Recurse `
                        | Sort-Object LastWriteTime -Descending `
                        | Select-Object -First 1).FullName
            if($codePath) { 
                $ora2pgCodePath = [System.IO.Path]::GetDirectoryName($codePath) 
                Write-OutputAndLog "Ora2Pg Installation files found at $ora2pgCodePath."
            }
        }
    }
    catch {
        Write-OutputAndLog "Ora2Pg is not currently installed."        
    }

    # Before running the installation - First check the required Environment Variables
    Write-OutputAndLog "Checking required environment variable settings..."
    if ($env:ORACLE_HOME -eq $null -or -not (Test-Path $env:ORACLE_HOME)) { throw "ORACLE_HOME not set to a valid value" }
    if ($env:LD_LIBRARY_PATH -eq $null -or -not $env:LD_LIBRARY_PATH.Contains($env:ORACLE_HOME)) { throw "LD_LIBRARY_PATH not point to ORACLE_HOME" }
    

    if(-not $ora2pgCodePath){
        Write-OutputAndLog "Extracting Ora2Pg code files to $installFolder."
        # extract the ora2pg code to the install folder
        Expand-Archive -LiteralPath $packagePath -DestinationPath $installFolder -Force
        # this is done as the inner folder name keeps changing per version so we pick the latest file
        $codePath = (Get-childitem -Path $installFolder -File -Filter "Makefile.PL" -Recurse `
                            | Sort-Object LastWriteTime -Descending `
                            | Select-Object -First 1).FullName
        $ora2pgCodePath = [System.IO.Path]::GetDirectoryName($codePath)
        Write-OutputAndLog "Extracted Ora2Pg code folder is $ora2pgCodePath."
    }   

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

        sudo perl Makefile.PL
        sudo make
        sudo make install

        # update the ora2pg expected install path
        $updatedPath = Update-EnvironmentPath -variableName "PATH" -newPath $ora2pgCodePath
        $env:PATH = $updatedPath
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

###################################### Permission Check ######################################
$edition = $PSVersionTable
if(-not ($edition.PSEdition -eq "Core" -and $edition.Platform  -eq "Unix" -and $edition.OS.Contains("Ubuntu"))) {
    Write-Host "ALERT!!!" -ForegroundColor Red
    Write-Host "Can not run installation script." -ForegroundColor Red
    Write-Host "This script is targeted for Ubuntu Operating System only" -ForegroundColor Red
    exit
}

###################################### Variable Initialization #################################
$Global:Logfile = $null
# environment setting
$ErrorActionPreference = "Stop"
$architecture = if($Is32bit) { "32" } else { "64" }

$workspacePath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$ora2pgInstallPath = [System.IO.Path]::Combine($env:HOME, "opt", "ora2pg")
if (-not(Test-Path $ora2pgInstallPath)) {
    New-Item -Path $ora2pgInstallPath -ItemType Directory -Force | Out-Null
}
###################################### Script Main #################################
Write-Host "This is an Interactive script and may require your input from time to time." -ForegroundColor Yellow
Write-Host "Please do not expect the installation to complete if left unattended." -ForegroundColor Yellow
Write-Host "  "

$timeStamp = [System.DateTime]::Now.ToString("yyyyMMddHHmmss")
$Global:Logfile = Join-Path $workspacePath ('installora2pg-' + $timeStamp + '.log')
# setting the SSL/TSL versions specifically to avoid system default issues
[Net.ServicePointManager]::SecurityProtocol = 
  [Net.SecurityProtocolType]::Tls12 -bor `
  [Net.SecurityProtocolType]::Tls11 -bor `
  [Net.SecurityProtocolType]::Tls

try {
    Check-Internet -exitOnFailure | Out-Null
    Install-Prerequisites
    # install Oracle instant client 
    $oicFolder = Install-OracleClient -downloadFolder $workspacePath `
                    -architecture $arch

    if($oicFolder -eq $null -or -not(Test-Path $oicFolder)){
        throw "Oracle InstantClient installation failed. ORACLE_HOME environment variable not set."
    }
    
    # check and install Perl
    Install-Perl
    # Install Perl libraries for Oracle and Postgresql
    Install-PerlLib -downloadFolder $workspacePath `
            -libraryName "DBD::Oracle"
    Install-PerlLib -downloadFolder $workspacePath `
            -libraryName "DBD::Pg"
    
    # Install Ora2Pg tool  
    $ora2pgInstallPath = [System.IO.Path]::Combine($env:HOME, "opt", "ora2pg")      
    Install-Ora2Pg -downloadFolder $workspacePath `
            -installFolder $ora2pgInstallPath

    Write-OutputAndLog "INSTALLATION SUCCESSFUL :)"

    ################ ADS Extension for Oracle Assessment ################
    for($x=0; $x -lt 2; $x=$x+1) { Write-Host " " }
    Write-Host "The Database Migration Assessment for Oracle extension" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host "The Database Migration Assessment for Oracle extension in Azure Data Studio helps" `
        "you assess an Oracle workload for migrating to SQL and PostgreSQL. The extension identifies an appropriate" `
        "Azure SQL and Azure PostgreSQL targets with right-sizing recommendations, and how complex the migration can be."
    Write-Host "https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/database-migration-assessment-for-oracle-extension?view=sql-server-ver16"
    Write-Host " "
    Write-Host "For configuring the ADS extension to perform code complexity assessment for PostgreSQL target, " `
        "use the following configuration values:"
    Write-Host ("Oracle Client Library Path: " + $env:ORACLE_HOME) -ForegroundColor Yellow
    $o2pfolder = (Get-childitem -Path $ora2pgInstallPath -File -Filter "Makefile.PL" -Recurse | Select -First 1).FullName
    $o2pfolder = [System.IO.Path]::GetDirectoryName($o2pfolder)
    Write-Host ("Ora2Pg Installation Path  : " + $o2pfolder) -ForegroundColor Yellow
    for($x=0; $x -lt 2; $x=$x+1) { Write-Host " " }
    ################ ADS Extension for Oracle Assessment ################
}
catch {
    Write-ErrorAndLog -exception $_.Exception    
    Write-ErrorAndLog "INSTALLATION FAILED :("
}
finally {
    Write-Host ("Log file generated  : " + $Global:Logfile) -ForegroundColor Green
}
