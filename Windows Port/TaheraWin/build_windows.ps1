$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

dotnet restore
dotnet publish -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true -o "$root\\build"
Write-Host "Built $root\\build\\Tahera.exe"
