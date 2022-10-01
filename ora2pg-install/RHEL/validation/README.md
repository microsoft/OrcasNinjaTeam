# Ora2Pg Client Installer Validation

Once the installation is successful, the installer insures that all the required components are available on the machine. It also configures the interdependencies between the components. But we still need to check if the components are properly configured before we can move forward.

In order to do that, you can use the testing scripts and run some sanity testing before starting on your Oracle to PostgreSQL journey.

## RHEL/CentOS Installer

Once you have successfully run the **installora2pg.ps1** and received the output like below, you can start with the test scenarios.

```cmd
...
...
2022-09-28 12:05:58.655:INFO:Applying resolution for v23 issue 1445...
2022-09-28 12:05:58.665:INFO:Resolution for v23 issue 1445 applied.
2022-09-28 12:05:58.672:INFO:INSTALLATION SUCCESSFUL :)
```

### Oracle Connectivity Validation

To check for proper configuration with Oracle InstantClient we need Oracle database connection which is not available in the installer. So in-order to test the Oracle connectivity you can use the ```validate-orcl-connection.ps1``` in the validation folder to check the basic connectivity. The below example runs the test script against an Oracle 12c database and asserts an expected result on the output.

```powershell
PS $HOME/user/repoclone> ./validation/validate-orcl-connection.ps1 -OracleDNS "dbi:Oracle:host=X.X.X.X;sid=orcl;port=1521" -OracleUser "system" -ExpectedResult "12c Enterprise Edition Release 12.2.0.1.0"
```

The output of the above script looks like this

```cmd
Enter Oracle database password:: *********
Creating target directory...
Initializing Ora2Pg project migv1 at $HOME/user/tmp/20220423153258
Creating project migv1.
Project initialization successful
Expression output: Oracle Database 12c Enterprise Edition Release 12.2.0.1.0
Database version check successful
TEST SUCCESSFUL
Clearing temp project...
```
