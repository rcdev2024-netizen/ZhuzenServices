# PowerShell script to reset test user passwords
# Run this after the backend is deployed and accessible

$backendUrl = "https://zhuzen-services-api-server-ktfc8tdef.vercel.app"  # Change to your API URL
$password = "test123"

$users = @(
    "admin@zhuzen.com",
    "manager@zhuzen.com",
    "tech1@zhuzen.com",
    "tech2@zhuzen.com",
    "customer1@example.com"
)

Write-Host "🔐 Resetting test user passwords via API..." -ForegroundColor Cyan
Write-Host ""

function Reset-Password {
    param([string]$email)
    
    Write-Host "Resetting password for: $email" -ForegroundColor Yellow
    
    try {
        # Step 1: Request password reset (get development token)
        $forgotResponse = Invoke-RestMethod `
            -Uri "$backendUrl/api/auth/forgot-password" `
            -Method POST `
            -ContentType "application/json" `
            -Body (@{email = $email} | ConvertTo-Json)
        
        Write-Host "Response: $($forgotResponse | ConvertTo-Json)" -ForegroundColor Gray
        
        # Extract reset token (only available in DEBUG mode)
        $resetToken = $forgotResponse.development_reset_token
        
        if (-not $resetToken) {
            Write-Host "❌ Failed - no reset token. Make sure DEBUG=true" -ForegroundColor Red
            return $false
        }
        
        Write-Host "✅ Reset token received" -ForegroundColor Green
        
        # Step 2: Reset password with token
        $resetResponse = Invoke-RestMethod `
            -Uri "$backendUrl/api/auth/reset-password" `
            -Method POST `
            -ContentType "application/json" `
            -Body (@{
                token = $resetToken
                new_password = $password
            } | ConvertTo-Json)
        
        Write-Host "✅ Password reset successfully!" -ForegroundColor Green
        Write-Host ""
        return $true
    }
    catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# Reset passwords for all users
foreach ($user in $users) {
    Reset-Password $user
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ All test user passwords reset to: $password" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
