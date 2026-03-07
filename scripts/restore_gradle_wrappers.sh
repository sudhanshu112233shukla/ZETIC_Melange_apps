#!/bin/bash
# ZETIC Gradle Wrapper Restoration Script
# This script ensures that the gradle-wrapper.jar exists in all Android projects.

echo "Scanning for Android projects needing Gradle wrapper restoration..."

# Find all directories containing gradlew but missing gradle-wrapper.jar
find apps -name "gradlew" | while read -r gradlew_path; do
    android_dir=$(dirname "$gradlew_path")
    wrapper_jar="$android_dir/gradle/wrapper/gradle-wrapper.jar"
    
    if [ ! -f "$wrapper_jar" ]; then
        echo "--> Restoring wrapper for: $android_dir"
        
        # We use a temporary gradle instance or just 'gradle wrapper' if available on system
        # In CI, we can download it directly from a trusted source (e.g., services.gradle.org)
        # For now, we will use a logic that the CI will use:
        
        mkdir -p "$android_dir/gradle/wrapper"
        
        # Download the jar if missing (using curl)
        # Note: In a real CI, we might stick to one version. 
        # We extract the version from gradle-wrapper.properties
        VERSION=$(grep "distributionUrl" "$android_dir/gradle/wrapper/gradle-wrapper.properties" | sed -n 's/.*\/gradle-\([0-9.]*\)-.*/\1/p')
        
        if [ -z "$VERSION" ]; then
            VERSION="8.7" # Fallback
        fi
        
        JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v$VERSION/gradle/wrapper/gradle-wrapper.jar"
        
        curl -sL "$JAR_URL" -o "$wrapper_jar"
        
        if [ $? -eq 0 ]; then
            echo "    [SUCCESS] Restored v$VERSION"
        else
            echo "    [ERROR] Failed to download v$VERSION"
        fi
    else
        echo "--> $android_dir: Wrapper already exists."
    fi
done

echo "Restoration complete."
