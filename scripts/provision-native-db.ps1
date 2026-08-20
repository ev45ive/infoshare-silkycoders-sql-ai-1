<#
.SYNOPSIS
    Point the RetailDW workshop at a native Windows SQL Server instance instead of Docker.

.DESCRIPTION
    Workshop tool - not a hardened setup. It deliberately mirrors docker-compose.yml:
    sa authentication with a throwaway password on a local instance.

        Server   : 127.0.0.1,14330
        Database : RetailDW
        User     : sa
        Password : Workshop_Dev2026#   (override with $env:MSSQL_SA_PASSWORD)

    so scripts/dw.sh, RetailDW.Local.publish.xml and sqlpackage work unchanged.

    Run from an elevated PowerShell: it switches the instance to mixed-mode auth and a
    static TCP port, which needs a service restart. Point it at a throwaway instance,
    not one a real application uses.

    To create a dedicated instance first:
        winget install Microsoft.SQLServer.2022.Express
        setup.exe /Q /ACTION=Install /FEATURES=SQLEngine /INSTANCENAME=RETAILDW `
                  /SQLSYSADMINACCOUNTS="$env:USERDOMAIN\$env:USERNAME" `
                  /SECURITYMODE=SQL /SAPWD="Workshop_Dev2026#" `
                  /TCPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS

.EXAMPLE
    .\scripts\provision-native-db.ps1 -InstanceName RETAILDW
#>
[CmdletBinding()]
param(
    [string]$InstanceName = 'RETAILDW',
    [int]$Port            = 14330,
    [string]$Database     = 'RetailDW',
    [string]$Password     = $(if ($env:MSSQL_SA_PASSWORD) { $env:MSSQL_SA_PASSWORD } else { 'Workshop_Dev2026#' })
)

$ErrorActionPreference = 'Stop'

$isDefault  = $InstanceName -eq 'MSSQLSERVER'
$winAuth    = if ($isDefault) { '.' } else { ".\$InstanceName" }
$service    = if ($isDefault) { 'MSSQLSERVER' } else { "MSSQL`$$InstanceName" }
$sqlAuth    = "127.0.0.1,$Port"
$pwdLiteral = $Password.Replace("'", "''")

# --- locate the instance -----------------------------------------------------
$names = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
if (-not ($names.PSObject.Properties.Name -contains $InstanceName)) {
    $installed = $names.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { $_.Name }
    throw "Instance '$InstanceName' not found. Installed: $($installed -join ', ')"
}
$root = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($names.$InstanceName)"

# --- mixed-mode auth + fixed port -------------------------------------------
Write-Host "Configuring $InstanceName for sa login on port $Port..."
Set-ItemProperty "$root\MSSQLServer" -Name LoginMode -Value 2 -Type DWord
Set-ItemProperty "$root\MSSQLServer\SuperSocketNetLib\Tcp" -Name Enabled -Value 1 -Type DWord
# A dynamic port would break the fixed 127.0.0.1,14330 endpoint the tooling assumes.
Set-ItemProperty "$root\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -Name TcpDynamicPorts -Value ''
Set-ItemProperty "$root\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -Name TcpPort -Value "$Port"

Restart-Service -Name $service -Force
Write-Host "  $service restarted"

# --- enable sa and create the database --------------------------------------
Write-Host 'Creating login and database...'
& sqlcmd -S $winAuth -E -C -b -Q @"
ALTER LOGIN [sa] WITH PASSWORD = N'$pwdLiteral';
ALTER LOGIN [sa] ENABLE;
IF DB_ID(N'$Database') IS NULL
    CREATE DATABASE [$Database];
"@
if ($LASTEXITCODE -ne 0) { throw "Setup failed against $winAuth. Are you sysadmin on this instance?" }

# --- verify the endpoint the workshop scripts will actually use --------------
Write-Host "Verifying $sqlAuth..."
& sqlcmd -S $sqlAuth -U sa -P $Password -C -b -d $Database -Q 'SELECT DB_NAME() AS [Database], SUSER_SNAME() AS [Login];'
if ($LASTEXITCODE -ne 0) {
    throw "Could not connect as sa. If this instance is SQL Server 2025, the old ODBC 17 sqlcmd cannot connect - run: winget install Microsoft.Sqlcmd"
}

Write-Host "`nReady - no changes needed to the workshop scripts." -ForegroundColor Green
Write-Host '  ./scripts/dw.sh build && ./scripts/dw.sh publish && ./scripts/dw.sh seed'
