# infoshare-silkycoders-sql-ai-1


# Visual Studio Code

# GIT
Ctrl+Shift+P -> CLone 
PASTE : https://github.com/ev45ive/infoshare-silkycoders-sql-ai-1.git 
Clone from URL
select location
open window

# Extensions
Ctrl+Shift+X
.vscode\extensions.json @recommended

# Powershell
powershell -ExecutionPolicy Bypass -File .\scripts\..


# Docker
Menu Start -> Docker Desktop

Terminal => [+|v] - git bash
```sh
 ./scripts/dw.sh up
```

# memory limit
git bash + 
```sh
./scripts/dw.sh wsl-memory
```

# Connection string
Local SQL Server container (see `scripts/dw.sh`), default credentials can be overridden via `MSSQL_SA_PASSWORD`:
```
Server=127.0.0.1,14330;Database=RetailDW;User Id=sa;Password=Workshop_Dev2026#;TrustServerCertificate=True;
```


# Po urlopie
```
run sql server, build, run baseline
```