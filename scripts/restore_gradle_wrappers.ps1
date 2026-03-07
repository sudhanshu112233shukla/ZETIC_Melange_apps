# ZETIC Gradle Wrapper Restoration Script (PowerShell)
$androidProjects = Get-ChildItem -Path apps -Filter "gradlew" -Recurse

Write-Host "Scanning for Android projects needing Gradle wrapper restoration..."

foreach ($gradlew in $androidProjects) {
    $androidDir = $gradlew.Directory.FullName
    $wrapperJarPath = Join-Path $androidDir "gradle\wrapper\gradle-wrapper.jar"
    $propertiesPath = Join-Path $androidDir "gradle\wrapper\gradle-wrapper.properties"
    
    if (-not (Test-Path $wrapperJarPath)) {
        Write-Host "--> Restoring wrapper for: $androidDir"
        
        $version = "8.7" # Default
        if (Test-Path $propertiesPath) {
            $content = Get-Content $propertiesPath
            if ($content -match "gradle-([0-9.]+)-") {
                $version = $Matches[1]
            }
        }
        
        $jarUrl = "https://raw.githubusercontent.com/gradle/gradle/v$version/gradle/wrapper/gradle-wrapper.jar"
        $destDir = Split-Path $wrapperJarPath
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force }
        
        Write-Host "    Downloading v$version..."
        try {
            Invoke-WebRequest -Uri $jarUrl -OutFile $wrapperJarPath -UseBasicParsing
            Write-Host "    [SUCCESS] Restored gradle-wrapper.jar"
        } catch {
            Write-Warning "    [ERROR] Failed to download v$version from $jarUrl"
        }
    } else {
        Write-Host "--> ${androidDir}: Wrapper already exists."
    }
}

Write-Host "Restoration complete."
