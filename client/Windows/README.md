# Windows Setup Guidance

## Setup Steps
1. Download CA
1. Open `Powershell` as Administrator
1. `Set-ExecutionPolicy -Scope CurrentUser Unrestricted`
1. `.\setup_windows.ps1 -CAPath <path to CA> -ServerIP <IP of the VPN> -VPNName <name>`
1. `Set-ExecutionPolicy -Scope CurrentUser Restricted`