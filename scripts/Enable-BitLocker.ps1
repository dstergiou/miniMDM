# Enable-BitLocker.ps1
param (
    [switch]$DryRun = $false
)

# Configuration
$recoveryKeyFilePath = ".\BitLocker_Recovery_Key.txt"
$driveLetter = "C:"

# Dry run mode
if ($DryRun) {
    Write-Host "[Dry Run] Would check BitLocker status and enable it if necessary."
    Write-Host "[Dry Run] Recovery key would be saved to: $recoveryKeyFilePath"
    return
}

# Check if BitLocker is already enabled
$bitLockerStatus = Get-BitLockerVolume -MountPoint $driveLetter | Select-Object -ExpandProperty ProtectionStatus

if ($bitLockerStatus -eq "On") {
    Write-Host "BitLocker is already enabled on drive $driveLetter."

    # Save the recovery key to a file
    if (Test-Path $recoveryKeyFilePath) {
        $confirm = Read-Host "The file $recoveryKeyFilePath already exists. Overwrite it? (Y/N)"
        if ($confirm -ne "Y") {
            Write-Host "Recovery key file was not overwritten. Exiting."
            return
        }
    }

    try {
        $recoveryKey = Get-BitLockerVolume -MountPoint $driveLetter | Select-Object -ExpandProperty KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } | Select-Object -ExpandProperty RecoveryPassword
        $recoveryKey | Out-File -FilePath $recoveryKeyFilePath
        Write-Host "Recovery key saved to: $recoveryKeyFilePath"
    } catch {
        Write-Host "Failed to save recovery key: $_" -ForegroundColor Red
        throw
    }
} else {
    Write-Host "BitLocker is not enabled on drive $driveLetter."

    # Prompt user
    $confirm = Read-Host "Do you want to enable BitLocker on drive $driveLetter? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "BitLocker enablement canceled by user."
        return
    }

    # Enable BitLocker
    try {
        Write-Host "Enabling BitLocker on drive $driveLetter..."
        Enable-BitLocker -MountPoint $driveLetter -EncryptionMethod XtsAes256 -RecoveryKeyPath $recoveryKeyFilePath -RecoveryKeyProtector
        Write-Host "BitLocker enabled successfully on drive $driveLetter."
    } catch {
        Write-Host "Failed to enable BitLocker: $_" -ForegroundColor Red
        throw
    }

    # Save the recovery key to a file
    try {
        $recoveryKey = Get-BitLockerVolume -MountPoint $driveLetter | Select-Object -ExpandProperty KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } | Select-Object -ExpandProperty RecoveryPassword
        $recoveryKey | Out-File -FilePath $recoveryKeyFilePath
        Write-Host "Recovery key saved to: $recoveryKeyFilePath"
    } catch {
        Write-Host "Failed to save recovery key: $_" -ForegroundColor Red
        throw
    }
}

# Validate BitLocker status
try {
    $bitLockerStatus = Get-BitLockerVolume -MountPoint $driveLetter | Select-Object -ExpandProperty ProtectionStatus
    if ($bitLockerStatus -eq "On") {
        Write-Host "Validation successful: BitLocker is enabled on drive $driveLetter."
    } else {
        Write-Host "Validation failed: BitLocker is not enabled on drive $driveLetter." -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to validate BitLocker status: $_" -ForegroundColor Red
}
