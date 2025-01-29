param (
  [switch]$dryRun = $false
)

# Configuration
$timeoutInSeconds = 600

# Dry run mode
if ($dryRun) {
  Write-Host "[Dry Run] Would configure screen lock timeout to $($timeoutInSeconds / 60) minutes."
  return
}

# Prompt user
$confirm = Read-Host "Do you want to set the screen lock timeout to 10 minutes? (Y/N)"
if ($confirm -ne "Y") {
  Write-Host "Screen lock timeout configuration canceled by user."
  return
}

# Set Screen auto-lock
try {
  Write-Host "Configuring screen lock timeout to 10 minutes..."

  # Registry setup
  $RegKey = "HKCU:\Control Panel\Desktop"
  Set-ItemProperty -Path $RegKey -Name ScreenSaveTimeOut -Value $timeoutInSeconds
  Set-ItemProperty -Path $RegKey -Name ScreenSaveActive -Value 1
  Set-ItemProperty -Path $RegKey -Name ScreenSaverIsSecure -Value 1


  Write-Host "Screen lock timeout set to 10 minutes."
} catch {
  Write-Host "Failed to set screen lock timeout: $_" -ForegroundColor Red
  throw
}

# Validate changes registry
try {
  Write-Host "Validating screen lock timeout settings (registry)..."

  $currentRegistryTimeout = (Get-ItemProperty -Path $RegKey -Name ScreenSaveTimeOut).ScreenSaveTimeOut
  $currentScreensaverActive = (Get-ItemProperty -Path $RegKey -Name ScreenSaveActive).ScreenSaveActive
  $currentScreensaverSecure = (Get-ItemProperty -Path $RegKey -Name ScreenSaverIsSecure).ScreenSaverIsSecure

  if ($currentRegistryTimeout -eq $timeoutInSeconds -and $currentScreensaverActive -eq 1 -and $currentScreensaverSecure -eq 1) {
    Write-Host "Validation successful: Screen lock (registry) timeout is set to 10 minutes."
  } else {
    Write-Host "Validation failed: Screen lock timeout (registry) was not set correctly." -ForegroundColor Red
    Write-Host "Current timeout (registry): $currentRegistryTimeout seconds"
    Write-Host "Current Screensaver enabled: $currentScreensaverActive"
    Write-Host "Current Screensaver secure: $currentScreensaverSecure"
  }
} catch {
  Write-Host "Failed to validate screen lock timeout settings: $_" -ForegroundColor Red
}
