$destinationPath = 'C:\Program Files\DesiredStateConfiguration'
$msiPath = ".\PowerShell-7.5.1-win-x64.msi"
$zipPath = ".\DSC-3.1.0-x86_64-pc-windows-msvc.zip"

# Create destination directory if it doesn't exist
if (-Not (Test-Path -Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory -Force
}

Expand-Archive -Path $zipPath -DestinationPath $destinationPath -Force

$envPath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

if ($envPath -notlike "*$destinationPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$envPath;$destinationPath", [System.EnvironmentVariableTarget]::Machine)
}

Start-Process -FilePath $msiPath -ArgumentList '/quiet /norestart' -Wait

if (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\PackageManagement\1.0.0.1') {
    Copy-Item -Path .\PackageManagement -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force
    Remove-Item 'C:\Program Files\WindowsPowerShell\Modules\PackageManagement\1.0.0.1' -Recurse -Force
}

if (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\1.0.0.1') {
    Copy-Item -Path .\PowerShellGet -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force
    Remove-Item 'C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\1.0.0.1' -Recurse -Force
}

$localRepo = "C:\ProgramData\PowerShell\LocalRepo"

if (-Not (Test-Path -Path $localRepo)) {
    New-Item -Path $localRepo -ItemType Directory -Force
}

if (-Not (Get-PSRepository -Name LocalRepo -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Name LocalRepo `
        -SourceLocation "$localRepo\" `
        -InstallationPolicy Trusted
}

Copy-Item -Path .\modules\* -Include *.nupkg -Destination $localRepo -Recurse -Force

$systemXml = "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet\PSRepositories.xml"

if (-Not (Test-Path -Path $systemXml)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $systemXml) -Force
    Copy-Item -Path .\PSRepositories.xml -Destination $systemXml -Force
}
