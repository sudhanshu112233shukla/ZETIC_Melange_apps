#!/bin/bash

# Script to restore all API keys back to YOUR_MLANGE_KEY placeholder
# This reverses the changes made by adapt_mlange_key.sh

PLACEHOLDER="YOUR_MLANGE_KEY"

echo "Restoring all API keys to placeholder: $PLACEHOLDER"
echo ""

# Update iOS files (Swift) - restore keys to YOUR_MLANGE_KEY
find apps -name "*.swift" -print0 | xargs -0 perl -i -pe 's/((tokenKey|privateTokenKey|projectKey|personalKey|accessToken|mlangeKey)\s*(?::|=|\?\?)\s*)"[^"]*"/${1}"'"$PLACEHOLDER"'"/g'

# Update iOS Xcode scheme files (xcscheme) - restore ZETIC_ACCESS_TOKEN
find apps -name "*.xcscheme" -print0 | xargs -0 perl -i -pe 's/(key = "ZETIC_ACCESS_TOKEN"[^>]*value = ")[^"]*"/${1}"'"$PLACEHOLDER"'"/g'

# Update Android files (Kotlin/Java)
# Pattern 1: ZeticMLangeModel(context, "KEY", ...)
find apps -name "*.kt" -print0 | xargs -0 perl -0777 -i -pe 's/(ZeticMLangeModel\(\s*[^,]+,\s*)"[^"]*"/${1}"'"$PLACEHOLDER"'"/g'
find apps -name "*.java" -print0 | xargs -0 perl -0777 -i -pe 's/(ZeticMLangeModel\(\s*[^,]+,\s*)"[^"]*"/${1}"'"$PLACEHOLDER"'"/g'

# Pattern 2: Constants/Variables (PERSONAL_KEY, tokenKey, etc.)
find apps -name "*.kt" -print0 | xargs -0 perl -i -pe 's/((PERSONAL_KEY|MLANGE_PERSONAL_ACCESS_TOKEN|tokenKey|token|token_key|projectKey)\s*=\s*)"[^"]*"/${1}"'"$PLACEHOLDER"'"/g'

echo "✅ All API keys have been restored to placeholder: $PLACEHOLDER"
echo ""
echo "Note: Git filter will automatically protect these keys on commit."
