# Set-PasswordPolicy.ps1
param (
    [switch]$DryRun = $false
)

# Configuration
$minPasswordLength = 12

# Dry run mode
if ($DryRun) {
    Write-Host "[Dry Run] Would configure minimum password length to $minPasswordLength characters."
    return
}

# Set minimum password length
try {
    Write-Host "Configuring minimum password length to $minPasswordLength characters..."
    secedit /export /cfg $env:TEMP\secpol.cfg
    (Get-Content $env:TEMP\secpol.cfg) -replace "MinimumPasswordLength = \d+", "MinimumPasswordLength = $minPasswordLength" | Set-Content $env:TEMP\secpol.cfg
    secedit /configure /db $env:TEMP\secedit.sdb /cfg $env:TEMP\secpol.cfg
    Write-Host "Minimum password length set to $minPasswordLength characters."
} catch {
    Write-Host "Failed to configure password policy: $_" -ForegroundColor Red
    throw
}

# Validate the changes
try {
    Write-Host "Validating password policy settings..."
    $currentPolicy = secedit /export /cfg $env:TEMP\secpol_validate.cfg
    $currentMinLength = (Get-Content $env:TEMP\secpol_validate.cfg | Select-String "MinimumPasswordLength").Line -replace "MinimumPasswordLength = ", ""

    if ($currentMinLength -eq $minPasswordLength) {
        Write-Host "Validation successful: Minimum password length is set to $minPasswordLength characters."
    } else {
        Write-Host "Validation failed: Minimum password length is not set correctly." -ForegroundColor Red
        Write-Host "Current minimum password length: $currentMinLength characters"
    }
} catch {
    Write-Host "Failed to validate password policy settings: $_" -ForegroundColor Red
}
