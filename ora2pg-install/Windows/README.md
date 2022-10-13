# Ora2Pg Client Installer for Windows 10 & above

## Supported Versions

- Windows 10 with PowerShell 6.0 and above
- Windows 11 with PowerShell 6.0 and above

## Installer Details

**installora2pg.ps1** PowerShell script can be used for installing _ora2pg_ on Windows platform. The script does not have any pre-requisites as long as there is an internet connection available to download the required packages. The script also checks if the components are already installed and does not installs it again if already found. The installation log ```installora2pg-yyyyMMddHHmmss.log``` is created for every run under the workspace folder.

The script tries to call the following  urls which should have access from the machine (needs attention incase of corporate internet proxy).

- http://microsoft.com (to check internet access)
- https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html
- https://www.oracle.com/database/technologies/instant-client/microsoft-windows-32-downloads.html
- https://download.oracle.com/
- https://aka.ms/vs/17/release/vc_redist.x64.exe
- https://aka.ms/vs/17/release/vc_redist.x32.exe
- https://aka.ms/highdpimfc2013x64enu
- https://aka.ms/highdpimfc2013x32enu
- http://strawberryperl.com/
- http://strawberryperl.com/download/
- https://cpan.metacpan.org/authors/id
- https://github.com/darold/ora2pg/releases
- https://github.com/darold/ora2pg/archive/refs/tags/v*.zip

Once the installer is successfully run on one machine, which is connected to the internet, all the required packages are downloaded in the workspace folder. The installer tries to download the latest installer even when the component is already installed. After that, the PowerShell script and the workspace folder can be copied to any other machine which do not have internet connection, to install ora2pg and all its dependencies.

## Installed Components

The components installed by the installer are:

- Latest version of Oracle InstantClient, InstantClient SDK and InstantClient SQLPlus
  - If the _instantclient-basic*.zip_, _instantclient-sdk*.zip_ and _instantclient-sqlplus*.zip_ are present in the same folder as the script then those zip files are used and latest version is not downloaded. So if your environment for some reason does not support the latest version of Oracle InstantClient, then download the desired version from Oracle download site ([x64](https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html) or [x36](https://www.oracle.com/database/technologies/instant-client/microsoft-windows-32-downloads.html)) and save them in the same folder as the script before running the installer.
- Dependency version of Microsoft VC++ Redistributable package based on the installed Oracle InstantClient.
  - Oracle InstantClient v19 and above need Microsoft Visual C++ Redistributable 2017
  - Oracle InstantClient v18 and below need Microsoft Visual C++ Redistributable 2013
- Latest version of Strawberry Perl
- Latest version of Strawberry Perl libraries for Oracle and PostgreSQL
- Latest version of Ora2Pg

## Installer Parameters

The script only requires two mandatory parameters. The complete list of parameters can also be seen using ```Get-Help .\installora2pg.ps1 -detailed```

```powershell
<#
.PARAMETER InstallFolderPath
(Mandatory) Specify the full path for the root installation folder under which all the components will be installed. The same paths would be 
updated in the environment variables.

.PARAMETER WorkspaceFolderPath
(Mandatory) Specify the full path for the workspace folder where the component installer packages will be downloaded before installation. If the installer already exists, then it will not be downloaded again.

.PARAMETER Is32bit
(Optional) [Switch] Specifies if the machine processor architecture is 64bit or 32bit. If set then it means machine is 32bit.
Default Value: False

.PARAMETER DeleteWorkspace
(Optional) [Switch] Forces the script to delete the workspace folder on completion (success or failure)
Default Value: False
#>
```

## Example

The script execution can be triggered using the command like

```powershell
PS C:\...\repoclone> .\installora2pg.ps1 -InstallFolderPath C:\anyfolder\Ora2PgInstall -WorkspaceFolderName C:\anyfolder\@download

PS C:\...\repoclone> .\installora2pg.ps1 -InstallFolderPath C:\anyfolder\Ora2PgInstall -WorkspaceFolderName C:\anyfolder\@download -Is32bit -DeleteWorkspace
```

## Validation

Once the installation is successful, the installer insures that all the required components are available on the machine. It also configures the interdependencies between the components. But in order to check for proper configuration with Oracle InstantClient we need Oracle database connection which is not available in the installer.

For available scenarios, check the [validation](validation) folder.
