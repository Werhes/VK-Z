param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("android", "ios", "both")]
    [string]$Platform,

    [Parameter(Mandatory = $true)]
    [string]$VersionName,

    [Parameter(Mandatory = $true)]
    [int]$VersionCode,

    [Parameter(Mandatory = $false)]
    [string]$ReleaseNotes = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("release", "prerelease")]
    [string]$ReleaseType = "prerelease",

    [Parameter(Mandatory = $false)]
    [string]$Configuration = "Release",

    [Parameter(Mandatory = $false)]
    [string]$MsBuildPath = "",

    [Parameter(Mandatory = $false)]
    [string]$TelegramBotToken = "",

    [Parameter(Mandatory = $false)]
    [string]$TelegramChatId = ""
)

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Send-TelegramNotification {
    param(
        [string]$Status,
        [string]$Platform,
        [string]$VersionName,
        [string]$VersionCode,
        [string]$ReleaseType,
        [string]$ReleaseNotes,
        [string]$BotToken,
        [string]$ChatId
    )

    if ([string]::IsNullOrEmpty($BotToken) -or [string]::IsNullOrEmpty($ChatId)) {
        Write-Color "[WARN] Telegram bot token or chat ID not provided. Skipping notification." -Color Yellow
        return
    }

    $emoji = if ($Status -eq "success") { "✅" } else { "❌" }
    $statusText = if ($Status -eq "success") { "SUCCESS" } else { "FAILED" }
    $platformUpper = $Platform.ToUpper()
    $notesBlock = if ([string]::IsNullOrEmpty($ReleaseNotes)) { "" } else { "`n*Notes:* ${ReleaseNotes}" }

    $message = @"
${emoji} *Local Build VK Z (${platformUpper})* ${emoji}

*Status:* ${statusText}
*Platform:* ${Platform}
*Version:* ${VersionName} (code: ${VersionCode})
*Type:* ${ReleaseType}
*Configuration:* ${Configuration}${notesBlock}
"@

    $body = @{
        chat_id = $ChatId
        text = $message
        parse_mode = "Markdown"
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri "https://api.telegram.org/bot${BotToken}/sendMessage" -Method Post -ContentType "application/json" -Body $body
        Write-Color "[OK] Telegram notification sent" -Color Green
    }
    catch {
        Write-Color "[ERROR] Failed to send Telegram notification: $_" -Color Red
    }
}

function Find-MsBuild {
    $possiblePaths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe",
        "/Library/Frameworks/Mono.framework/Versions/Current/Commands/msbuild",
        "/usr/local/bin/msbuild",
        "/usr/bin/msbuild"
    )

    # If user provided a path, use it
    if ($MsBuildPath -and (Test-Path $MsBuildPath)) {
        return $MsBuildPath
    }

    # Search common paths
    foreach ($p in $possiblePaths) {
        if (Test-Path $p) {
            return $p
        }
    }

    # Try to find via Get-Command
    try {
        $cmd = Get-Command msbuild -ErrorAction Stop
        return $cmd.Source
    } catch {
        # Last resort
        return "msbuild"
    }
}

function Build-Android {
    Write-Color "`n========================================" -Color Cyan
    Write-Color "  Building Android APK/AAB" -Color Cyan
    Write-Color "  Version: $VersionName ($VersionCode)" -Color Cyan
    Write-Color "  Configuration: $Configuration" -Color Cyan
    Write-Color "========================================" -Color Cyan

    $projectPath = "Werhes.Vkz.AndroidApp\Werhes.Vkz.AndroidApp.csproj"
    $msbuild = Find-MsBuild

    # Restore NuGet packages
    Write-Color "[1/3] Restoring NuGet packages..." -Color Yellow
    dotnet restore Werhes.Vkz.sln
    if ($LASTEXITCODE -ne 0) {
        Write-Color "[ERROR] dotnet restore failed!" -Color Red
        return $false
    }

    # Build project
    Write-Color "[2/3] Building Android project..." -Color Yellow
    Write-Color "  MSBuild: $msbuild" -Color Gray
    & $msbuild $projectPath /t:PackageForAndroid /p:Configuration=$Configuration /p:AndroidPackageFormat=aab "/p:VersionName=$VersionName" /p:VersionCode=$VersionCode
    if ($LASTEXITCODE -ne 0) {
        Write-Color "[ERROR] Android build failed!" -Color Red
        return $false
    }

    # Find output file
    Write-Color "[3/3] Locating output file..." -Color Yellow
    $outputDir = "Werhes.Vkz.AndroidApp\bin\$Configuration"
    $aab = Get-ChildItem -Path $outputDir -Recurse -Filter "*.aab" | Select-Object -First 1
    $apk = Get-ChildItem -Path $outputDir -Recurse -Filter "*.apk" | Select-Object -First 1

    if ($aab) {
        Write-Color "[OK] Build successful! AAB: $($aab.FullName)" -Color Green
    }
    elseif ($apk) {
        Write-Color "[OK] Build successful! APK: $($apk.FullName)" -Color Green
    }
    else {
        Write-Color "[WARN] Build completed but output file not found in $outputDir" -Color Yellow
    }

    return $true
}

function Build-iOS {
    Write-Color "`n========================================" -Color Cyan
    Write-Color "  Building iOS IPA" -Color Cyan
    Write-Color "  Version: $VersionName ($VersionCode)" -Color Cyan
    Write-Color "  Configuration: $Configuration" -Color Cyan
    Write-Color "========================================" -Color Cyan

    $projectPath = "Werhes.Vkz.iOS\Werhes.Vkz.iOS.csproj"
    $msbuild = Find-MsBuild

    # Restore NuGet packages
    Write-Color "[1/3] Restoring NuGet packages..." -Color Yellow
    dotnet restore Werhes.Vkz.sln
    if ($LASTEXITCODE -ne 0) {
        Write-Color "[ERROR] dotnet restore failed!" -Color Red
        return $false
    }

    # Build project
    Write-Color "[2/3] Building iOS project..." -Color Yellow
    Write-Color "  MSBuild: $msbuild" -Color Gray
    & $msbuild $projectPath /p:Configuration=$Configuration /p:Platform=iPhone /p:BuildIpa=true "/p:VersionNumber=$VersionName" /p:VersionCode=$VersionCode
    if ($LASTEXITCODE -ne 0) {
        Write-Color "[ERROR] iOS build failed!" -Color Red
        return $false
    }

    # Find output file
    Write-Color "[3/3] Locating output file..." -Color Yellow
    $outputDir = "Werhes.Vkz.iOS\bin\iPhone\$Configuration"
    $ipa = Get-ChildItem -Path $outputDir -Recurse -Filter "*.ipa" | Select-Object -First 1

    if ($ipa) {
        Write-Color "[OK] Build successful! IPA: $($ipa.FullName)" -Color Green
    }
    else {
        Write-Color "[WARN] Build completed but IPA not found in $outputDir" -Color Yellow
    }

    return $true
}

# ===== MAIN =====
Write-Color "==========================================" -Color Magenta
Write-Color "  VK Z Build Script" -Color Magenta
Write-Color "  Platform: $Platform" -Color Magenta
Write-Color "  Version: $VersionName (code: $VersionCode)" -Color Magenta
Write-Color "  Type: $ReleaseType" -Color Magenta
Write-Color "  Configuration: $Configuration" -Color Magenta
if ($ReleaseNotes) {
    Write-Color "  Notes: $ReleaseNotes" -Color Magenta
}
Write-Color "==========================================" -Color Magenta

$androidSuccess = $true
$iosSuccess = $true

if ($Platform -eq "android" -or $Platform -eq "both") {
    $androidSuccess = Build-Android
}

if ($Platform -eq "ios" -or $Platform -eq "both") {
    $iosSuccess = Build-iOS
}

$overallStatus = if ($androidSuccess -and $iosSuccess) { "success" } else { "failed" }

Write-Color "`n==========================================" -Color Magenta
if ($overallStatus -eq "success") {
    Write-Color "  BUILD COMPLETED SUCCESSFULLY!" -Color Green
} else {
    Write-Color "  BUILD FAILED!" -Color Red
}
Write-Color "==========================================" -Color Magenta

# Send Telegram notification
Send-TelegramNotification -Status $overallStatus -Platform $Platform -VersionName $VersionName -VersionCode $VersionCode -ReleaseType $ReleaseType -ReleaseNotes $ReleaseNotes -BotToken $TelegramBotToken -ChatId $TelegramChatId

exit $(if ($overallStatus -eq "success") { 0 } else { 1 })