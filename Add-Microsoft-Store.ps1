#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs Microsoft Store and dependencies on Windows LTSC editions.

.DESCRIPTION
    Zero-touch installation script that automatically installs the Microsoft Store
    and all required dependencies on Windows LTSC (Long-Term Servicing Channel) editions.

    The script will:
    - Stop related processes automatically
    - Install all required dependencies
    - Download and install the latest DesktopAppInstaller
    - Install Microsoft Store

.NOTES
    File Name      : Add-Microsoft-Store.ps1
    Author         : Updated from czvv's batch script
    Prerequisite   : PowerShell 5.1 or later, Administrator privileges

.EXAMPLE
    .\Add-Microsoft-Store.ps1
    Runs the installation with default settings (zero-touch).
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = 'Stop'

#region Functions

function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Stop-RelatedProcesses {
    Write-ColorMessage "Stopping related processes to prevent errors..." -Color DarkYellow

    $processesToStop = @(
        'backgroundTaskHost',
        'RuntimeBroker',
        'dllhost',
        'WindowsTerminal',
        'msedgewebview2',
        'Widgets',
        'WidgetService'
    )

    # Stop WindowsApps processes
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like 'C:\Program Files\WindowsApps\*' } |
        Stop-Process -Force -ErrorAction SilentlyContinue

    # Stop specific processes
    foreach ($processName in $processesToStop) {
        Get-Process -Name $processName -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

function Install-AppxPackageWithLogging {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    Write-ColorMessage "`nAdding $DisplayName" -Color Magenta

    try {
        Add-AppxPackage -Path $Path -ErrorAction Stop
        Write-ColorMessage "Successfully installed $DisplayName" -Color Green
        return $true
    }
    catch {
        Write-ColorMessage "An error occurred during the operation for $Path" -Color Red
        Write-ColorMessage $_.Exception.Message -Color Red
        return $false
    }
}

function Get-ArchitecturePackages {
    param(
        [string]$Pattern,
        [string]$Architecture
    )

    $scriptPath = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptPath) {
        $scriptPath = $PSScriptRoot
    }

    Get-ChildItem -Path $scriptPath -Filter $Pattern -Recurse -File |
        Where-Object { $_.Name -match $Architecture }
}

#endregion

#region Main Script

try {
    # Display header
    Write-Host "`n"
    Write-ColorMessage "Script Made by czvv - Updated to PowerShell" -Color Black -BackgroundColor White
    Write-Host "`n"

    Write-ColorMessage "Running as Administrator" -Color Green

    # Detect architecture
    $arch = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    Write-ColorMessage "Detected Architecture: $arch" -Color Blue

    # Stop related processes
    Stop-RelatedProcesses

    Write-ColorMessage "`nInstalling $arch packages..." -Color DarkGray

    $scriptPath = $PSScriptRoot
    if (-not $scriptPath) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    $hasError = $false

    # Install .NET Native Framework
    $packages = Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Framework*$arch*.Appx" -Recurse
    foreach ($package in $packages) {
        $result = Install-AppxPackageWithLogging -Path $package.FullName -DisplayName "Microsoft .NET Native Framework"
        if (-not $result) { $hasError = $true }
    }

    # Install .NET Native Runtime
    $packages = Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Runtime*$arch*.Appx" -Recurse
    foreach ($package in $packages) {
        $result = Install-AppxPackageWithLogging -Path $package.FullName -DisplayName "Microsoft .NET Native Runtime"
        if (-not $result) { $hasError = $true }
    }

    # Install VCLibs 140.00 UWP Desktop
    $packages = Get-ChildItem -Path $scriptPath -Filter "*VCLibs.140.00.UWPDesktop*$arch*.Appx" -Recurse
    foreach ($package in $packages) {
        $result = Install-AppxPackageWithLogging -Path $package.FullName -DisplayName "Microsoft VCLibs 140.00 UWP Desktop"
        if (-not $result) { $hasError = $true }
    }

    # Install VCLibs 140.00
    $packages = Get-ChildItem -Path $scriptPath -Filter "*VCLibs.140.00_*$arch*.Appx" -Recurse |
        Where-Object { $_.Name -notmatch 'UWPDesktop' }
    foreach ($package in $packages) {
        $result = Install-AppxPackageWithLogging -Path $package.FullName -DisplayName "Microsoft Visual C++ 2015-2019 UWP Desktop Runtime"
        if (-not $result) { $hasError = $true }
    }

    # Install UI Xaml
    $packages = Get-ChildItem -Path $scriptPath -Filter "*UI.Xaml*$arch*.Appx" -Recurse
    foreach ($package in $packages) {
        $result = Install-AppxPackageWithLogging -Path $package.FullName -DisplayName "Microsoft UI Xaml"
        if (-not $result) { $hasError = $true }
    }

    # Download and install DesktopAppInstaller
    Write-ColorMessage "`nAdding Microsoft DesktopAppInstaller" -Color Magenta

    $installerPath = Join-Path $scriptPath "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    try {
        Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $installerPath -TimeoutSec 10 -ErrorAction Stop

        if (Test-Path $installerPath) {
            Add-AppxPackage -Path $installerPath -ErrorAction Stop
            Write-ColorMessage "Successfully installed Microsoft DesktopAppInstaller" -Color Green
        }
        else {
            throw "Failed to download Microsoft.DesktopAppInstaller"
        }
    }
    catch {
        Write-ColorMessage "ERROR: Failed to download or install Microsoft.DesktopAppInstaller" -Color Red
        Write-ColorMessage $_.Exception.Message -Color Red
        $hasError = $true
    }

    # Install Store Purchase App
    $packages = Get-ChildItem -Path $scriptPath -Filter "*StorePurchaseApp*.AppxBundle" -Recurse
    foreach ($package in $packages) {
        $result = Install-AppxPackageWithLogging -Path $package.FullName -DisplayName "Microsoft Store Purchase App"
        if (-not $result) { $hasError = $true }
    }

    # Install Microsoft Store
    $packages = Get-ChildItem -Path $scriptPath -Filter "*WindowsStore*.Msixbundle" -Recurse
    foreach ($package in $packages) {
        $result = Install-AppxPackageWithLogging -Path $package.FullName -DisplayName "Microsoft Store"
        if (-not $result) { $hasError = $true }
    }

    # Display completion message
    Write-Host "`n"
    if ($hasError) {
        Write-ColorMessage "Completed with errors. Please review the messages above." -Color Yellow
        exit 1
    }
    else {
        Write-ColorMessage "Done." -Color Green
        exit 0
    }
}
catch {
    Write-Host "`n"
    Write-ColorMessage "An unexpected error occurred:" -Color Red
    Write-ColorMessage $_.Exception.Message -Color Red
    Write-ColorMessage $_.ScriptStackTrace -Color DarkRed
    exit 1
}

#endregion
