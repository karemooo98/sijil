#!/bin/bash

# Script to set up release keystore for Play Store submission
# Run this from the project root: bash android/setup_keystore.sh

echo "=========================================="
echo "Play Store Keystore Setup"
echo "=========================================="
echo ""

# Check if keystore already exists
if [ -f "android/upload-keystore.jks" ]; then
    echo "⚠️  WARNING: upload-keystore.jks already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    rm android/upload-keystore.jks
fi

# Check if key.properties already exists
if [ -f "android/key.properties" ]; then
    echo "⚠️  WARNING: key.properties already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "Generating keystore..."
echo "You will be prompted for:"
echo "  - Keystore password (save this securely!)"
echo "  - Key password (can be same as keystore password)"
echo "  - Your name/organization details"
echo ""

keytool -genkey -v -keystore android/upload-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload

if [ $? -ne 0 ]; then
    echo "❌ Keystore generation failed!"
    exit 1
fi

echo ""
echo "✅ Keystore generated successfully!"
echo ""

# Create key.properties file
echo "Creating key.properties file..."
echo "You'll need to enter your passwords again:"
echo ""

read -sp "Enter keystore password: " STORE_PASSWORD
echo ""
read -sp "Enter key password (or press Enter to use same as keystore): " KEY_PASSWORD
echo ""

if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD=$STORE_PASSWORD
fi

cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
EOF

echo ""
echo "✅ key.properties created!"
echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT:"
echo "  1. Backup android/upload-keystore.jks securely"
echo "  2. Save your passwords in a secure location"
echo "  3. If you lose the keystore, you cannot update your app!"
echo ""
echo "Next steps:"
echo "  1. Review android/key.properties (already created)"
echo "  2. Build your app: flutter build appbundle --release"
echo "  3. Follow PLAY_STORE_SUBMISSION_GUIDE.md"
echo ""

