#!/bin/bash

# Exit on error
set -e

echo "🚀 Building Vibe Notes for Release..."
swift build -c release

# App bundle name
APP_NAME="Vibe Notes.app"
EXECUTABLE_PATH=".build/release/VibeNotes"

echo "📦 Creating App Bundle Structure..."
# Create the bundle structure
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

# Copy the executable
echo "📄 Copying Executable..."
cp "$EXECUTABLE_PATH" "$APP_NAME/Contents/MacOS/"

# Copy Icon
if [ -f "VibeNotes.icns" ]; then
    echo "🖼️ Copying App Icon..."
    cp "VibeNotes.icns" "$APP_NAME/Contents/Resources/AppIcon.icns"
fi

# Create Info.plist
echo "📝 Generating Info.plist..."
cat > "$APP_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VibeNotes</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.VibeNotes</string>
    <key>CFBundleName</key>
    <string>Vibe Notes</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/> <!-- Hides dock icon -->
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Build Complete! You can find your app at: $(pwd)/$APP_NAME"
echo "You can move it to your /Applications folder."


