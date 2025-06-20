$msiUrl = 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.msi'
$zipUrl = 'https://github.com/PowerShell/DSC/releases/download/v3.1.0/DSC-3.1.0-x86_64-pc-windows-msvc.zip'
$msiPath = $msiUrl.Split("/")[-1]
$zipPath = $zipUrl.Split("/")[-1]

Invoke-WebRequest -Uri $msiUrl -OutFile ./$msiPath
Invoke-WebRequest -Uri $zipUrl -OutFile ./$zipPath

Save-Module -Name PowerShellGet -RequiredVersion 2.2.5 -Path .

$dscModules = @(
    "ActiveDirectoryDsc",
    "ComputerManagementDsc",
    "DSCR_FileContent",
    "SChannelDsc",
    "SqlServerDsc",
    "WebAdministrationDsc",
    "xPSDesiredStateConfiguration"
)

$dscPreRelease = @(
    "SecurityPolicyDsc"
)

New-Item -Path ./modules -ItemType Directory -Force

Save-Package -Name $dscModules -ProviderName NuGet -Source 'https://www.powershellgallery.com/api/v2' -Path ./modules/

Save-Package -Name $dscPreRelease -ProviderName NuGet -Source 'https://www.powershellgallery.com/api/v2' -Path ./modules/ -AllowPrereleaseVersions

Copy-Item -Path ../s/scripts/bootstrap-package.ps1 -Destination . -Force
Copy-Item -Path ../s/scripts/PSRepositories.xml -Destination . -Force

# Patch a single function in a .psm1 file with an updated version
function Update-FunctionInFile {
    param (
        [string]$File,
        [string]$FunctionName,
        [string]$PatchPath
    )

    $originalContent = Get-Content -Path $File -Raw
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($originalContent, [ref]$tokens, [ref]$errors)

    $funcAst = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq $FunctionName
    }, $true)

    if (-not $funcAst) {
        Write-Warning "Function '$FunctionName' not found in '$File'. Skipping patch."
        return
    }

    $patchedFunction = Get-Content -Path $PatchPath -Raw
    $before = $originalContent.Substring(0, $funcAst.Extent.StartOffset)
    $after = $originalContent.Substring($funcAst.Extent.EndOffset)
    Set-Content -Path $File -Value "$before$patchedFunction$after" -Force
}

# # Setup
# $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "dsc"
# $targetFile = Join-Path $tempDir "psDscAdapter/win_psDscAdapter.psm1"

# # Unzip
# New-Item -ItemType Directory -Path $tempDir | Out-Null
# Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

# # Patch
# Update-FunctionInFile -File $targetFile -FunctionName 'Invoke-DscCacheRefresh' -PatchPath '../s/scripts/Invoke-DscCacheRefresh.ps1'

# # Re-zip
# Remove-Item $zipPath
# Compress-Archive -Path "$tempDir/*" -DestinationPath $zipPath
# Remove-Item -Recurse -Force $tempDir
