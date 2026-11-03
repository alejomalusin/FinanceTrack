$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Windows solicitará permiso de administrador para configurar SQLEXPRESS en localhost.' -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $elevated = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    if ($elevated.ExitCode -ne 0) {
        $logPath = Join-Path $PSScriptRoot 'setup-local.log'
        if (Test-Path $logPath) { Get-Content $logPath -Tail 40 | Write-Host }
        throw "La configuración elevada terminó con código $($elevated.ExitCode). Revisa database\setup-local.log."
    }
    exit 0
}

$logPath = Join-Path $PSScriptRoot 'setup-local.log'
Start-Transcript -Path $logPath -Append | Out-Null
trap {
    Write-Host "ERROR: $_" -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch { }
    exit 1
}

$instanceRoot = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL17.SQLEXPRESS'
$tcp = Join-Path $instanceRoot 'MSSQLServer\SuperSocketNetLib\Tcp'
if (-not (Test-Path $tcp)) { throw "No se encontró la configuración de red de SQLEXPRESS: $tcp" }

# Restringe TCP a las interfaces loopback; no publica SQL Server en la LAN.
Set-ItemProperty -Path $tcp -Name Enabled -Value 1
Set-ItemProperty -Path $tcp -Name ListenOnAllIPs -Value 0
foreach ($ip in @('IP3', 'IP4')) {
    $ipPath = Join-Path $tcp $ip
    if (Test-Path $ipPath) {
        Set-ItemProperty -Path $ipPath -Name Enabled -Value 1
        Set-ItemProperty -Path $ipPath -Name TcpPort -Value '1433'
        Set-ItemProperty -Path $ipPath -Name TcpDynamicPorts -Value ''
    }
}

# Habilita autenticación SQL para una cuenta de aplicación dedicada.
$sqlServerKey = Join-Path $instanceRoot 'MSSQLServer'
Set-ItemProperty -Path $sqlServerKey -Name LoginMode -Value 2
Restart-Service -Name 'MSSQL$SQLEXPRESS' -Force
$deadline = (Get-Date).AddSeconds(60)
do {
    Start-Sleep -Seconds 2
    $service = Get-Service -Name 'MSSQL$SQLEXPRESS'
} while ($service.Status -ne 'Running' -and (Get-Date) -lt $deadline)
if ($service.Status -ne 'Running') { throw 'SQLEXPRESS no volvió a iniciar.' }

$connectionString = 'Server=127.0.0.1,1433;Database=master;Integrated Security=True;TrustServerCertificate=True;Connection Timeout=10'
$connection = [System.Data.SqlClient.SqlConnection]::new($connectionString)
$connection.Open()
try {
    $check = $connection.CreateCommand()
    $check.CommandText = "SELECT DB_ID(N'FinanceTrack')"
    $databaseId = $check.ExecuteScalar()
    $check.Dispose()

    if ($databaseId -eq [DBNull]::Value) {
        $schemaPath = Join-Path $PSScriptRoot 'schema.sql'
        $schema = Get-Content -Raw -Encoding UTF8 $schemaPath
        $batches = [regex]::Split($schema, '(?im)^\s*GO\s*;?\s*(?:--.*)?$')
        foreach ($batch in $batches) {
            if ([string]::IsNullOrWhiteSpace($batch)) { continue }
            $command = $connection.CreateCommand()
            $command.CommandText = $batch
            $command.CommandTimeout = 60
            [void]$command.ExecuteNonQuery()
            $command.Dispose()
        }
    }
    else {
        $check = $connection.CreateCommand()
        $check.CommandText = @"
USE [FinanceTrack];
SELECT STRING_AGG(required.name, N', ')
FROM (VALUES (N'users'),(N'roles'),(N'user_roles'),(N'categories'),(N'income'),(N'expenses'),(N'budgets'),(N'predictions'),(N'notifications'),(N'user_settings'),(N'refresh_tokens')) required(name)
WHERE OBJECT_ID(N'dbo.' + required.name, N'U') IS NULL;
"@
        $missing = $check.ExecuteScalar()
        $check.Dispose()
        if ($missing -ne [DBNull]::Value -and $missing) {
            throw "La base FinanceTrack tiene un esquema parcial. Faltan tablas: $missing. No se borró ni modificó ningún dato."
        }
    }

    $seed = $connection.CreateCommand()
    $seed.CommandText = @"
USE [FinanceTrack];
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE name = N'USER') INSERT dbo.roles(name) VALUES (N'USER');
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE name = N'ADMIN') INSERT dbo.roles(name) VALUES (N'ADMIN');
MERGE dbo.categories AS target
USING (VALUES
 (N'Sueldo',N'INCOME'),(N'Freelance',N'INCOME'),(N'Bonos',N'INCOME'),(N'Inversiones',N'INCOME'),(N'Otros ingresos',N'INCOME'),
 (N'Alimentación',N'EXPENSE'),(N'Transporte',N'EXPENSE'),(N'Vivienda',N'EXPENSE'),(N'Salud',N'EXPENSE'),(N'Educación',N'EXPENSE'),
 (N'Streaming',N'EXPENSE'),(N'Compras',N'EXPENSE'),(N'Viajes',N'EXPENSE'),(N'Servicios',N'EXPENSE'),(N'Deudas',N'EXPENSE'),
 (N'Entretenimiento',N'EXPENSE'),(N'Otros',N'EXPENSE')
) AS source(name,kind)
ON target.name=source.name AND target.kind=source.kind
WHEN NOT MATCHED THEN INSERT(name,kind) VALUES(source.name,source.kind);
"@
    [void]$seed.ExecuteNonQuery()
    $seed.Dispose()

    $passwordBytes = [byte[]]::new(32)
    $random = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $random.GetBytes($passwordBytes)
    $random.Dispose()
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@$%_-'
    $password = -join ($passwordBytes | ForEach-Object { $alphabet[[int]$_ % $alphabet.Length] })
    $quotedPassword = $password.Replace("'", "''")
    $provision = @"
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'financetrack_app')
    CREATE LOGIN [financetrack_app] WITH PASSWORD = N'$quotedPassword', CHECK_POLICY = ON;
ELSE
    ALTER LOGIN [financetrack_app] WITH PASSWORD = N'$quotedPassword', CHECK_POLICY = ON;
USE [FinanceTrack];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'financetrack_app')
    CREATE USER [financetrack_app] FOR LOGIN [financetrack_app];
IF NOT EXISTS (
    SELECT 1 FROM sys.database_role_members drm
    JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id
    JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'db_datareader' AND m.name = N'financetrack_app'
) ALTER ROLE [db_datareader] ADD MEMBER [financetrack_app];
IF NOT EXISTS (
    SELECT 1 FROM sys.database_role_members drm
    JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id
    JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'db_datawriter' AND m.name = N'financetrack_app'
) ALTER ROLE [db_datawriter] ADD MEMBER [financetrack_app];
"@
    $command = $connection.CreateCommand()
    $command.CommandText = $provision
    [void]$command.ExecuteNonQuery()
    $command.Dispose()
}
finally {
    $connection.Dispose()
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$localProperties = Join-Path $projectRoot 'backend\local.properties'
@(
    'spring.datasource.url=jdbc:sqlserver://127.0.0.1:1433;databaseName=FinanceTrack;encrypt=true;trustServerCertificate=true'
    'spring.datasource.username=financetrack_app'
    "spring.datasource.password=$password"
) | Set-Content -Encoding ASCII $localProperties
Write-Host 'FinanceTrack quedó creado y conectado a SQLEXPRESS en localhost.' -ForegroundColor Green
Write-Host 'Credenciales de la app guardadas en backend/local.properties (archivo local ignorado por Git).'
