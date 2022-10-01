# Ora2Pg Client Installer for RHEL/CentOS

> **IMPORTANT** This is an **Interactive script** and may require your input from time to time. Please do not expect the installation to complete if left unattended.

## Supported Versions

- RHEL 8
- RHEL 7

## Prerequisites

The script needs PowerShell to be installed on the machine. PowerShell is a cross-platform task automation solution made up of a command-line shell, a scripting language, and a configuration management framework. PowerShell runs on Windows, Linux, and macOS.

To install PowerShell on RHEL please follow the [official Microsoft documentation](https://learn.microsoft.com/en-us/powershell/scripting/install/install-rhel). Below script is copied from the official documentation as of 30th Sep 2022.

Use the following shell commands to install PowerShell on the target OS.
> **NOTE** This only works for supported versions of RHEL.

```powershell
# Register the Microsoft RedHat repository
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo

# Install PowerShell
sudo yum install --assumeyes powershell

# Start PowerShell
pwsh
```

## Installer Details

**installora2pg.ps1** PowerShell script can be used for installing _ora2pg_ on RHEL/CentOS platform. The script checks if a component are already installed and does not installs it again if already found. The installation log ```installora2pg-yyyyMMddHHmmss.log``` is created for every run under the same folder where the script is saved.

The script tries to call the following  urls which should have access from the machine (needs attention incase of corporate internet proxy). The installers are downloaded into the workspace folder.

- http://microsoft.com (to check internet access)
- https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html
- https://www.oracle.com/database/technologies/instant-client/linux-x86-32-downloads.html
- https://download.oracle.com/
- https://github.com/darold/ora2pg/releases
- https://github.com/darold/ora2pg/archive/refs/tags/v*.zip

The installer can only run when connected to the internet and is able to download the required components.

## Installed Components

The components installed by the installer are:

- Latest version of Oracle InstantClient, InstantClient SDK and InstantClient SQLPlus
  - If the _oracle-instantclient-basic*.rpm_, _oracle-instantclient-devel*.rpm_ and _oracle-instantclient-sqlplus*.rpm_ are present in the same folder as the script then those rpm files are used and latest version is not downloaded. So if your environment for some reason does not support the latest version of Oracle InstantClient, then download the desired version from Oracle download site ([x64](https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html) or [x36](https://www.oracle.com/database/technologies/instant-client/linux-x86-32-downloads.html)) and save them in the same folder as the script before running the installer.
- RHEL/CentOS comes with Perl already installed. The script checks and if not found the uses ```yum``` to install Perl.
- Latest version of Perl libraries for Oracle and PostgreSQL using ```CPAN```.
- Latest version of Ora2Pg. Ora2Pg repo is copied under "$HOME/opt/ora2pg" path.

## Installer Parameters

The script only requires two mandatory parameters. The complete list of parameters can also be seen using ```Get-Help .\installora2pg.ps1 -detailed```

```powershell
<#
.PARAMETER Is32bit
(Optional) [Switch] Specifies if the machine processor architecture is 64bit or 32bit. If set then it means machine is 32bit.
Default Value: False
#>
```

## Example

The script execution can be triggered on the PowerShell console like shown below

```powershell
~$ pwsh

PS $HOME/user/repoclone> ./installora2pg.ps1 
OR
PS $HOME/user/repoclone> ./installora2pg.ps1 -Is32bit
```

## Validation

Once the installation is successful, the installer insures that all the required components are available on the machine. It also configures the interdependencies between the components. But in order to check for proper configuration with Oracle InstantClient we need Oracle database connection which is not available in the installer.

For available scenarios, check the [validation](validation) folder.
