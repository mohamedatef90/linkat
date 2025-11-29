#!/bin/bash

# Share Extension Setup Script
# This script will help you configure your Info.plist files

echo "🚀 Share Extension Setup Helper"
echo "================================"
echo ""

# Get bundle identifier
echo "Step 1: Find your Bundle Identifier"
echo "Open Xcode and go to: Runner target → General → Bundle Identifier"
echo ""
read -p "Enter your Bundle Identifier (e.g., com.example.linkat): " BUNDLE_ID

if [ -z "$BUNDLE_ID" ]; then
    echo "❌ Bundle ID is required!"
    exit 1
fi

APP_GROUP="group.$BUNDLE_ID"
URL_SCHEME="ShareMedia-$BUNDLE_ID"

echo ""
echo "✅ Configuration:"
echo "   Bundle ID:  $BUNDLE_ID"
echo "   App Group:  $APP_GROUP"
echo "   URL Scheme: $URL_SCHEME"
echo ""

# Create Info.plist additions
echo "Step 2: Creating Info.plist snippets..."
echo ""

# Runner Info.plist
cat > runner_infoplist_addition.xml << EOF
<!-- ADD THESE TO ios/Runner/Info.plist inside the main <dict> -->

<key>AppGroupId</key>
<string>$APP_GROUP</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>$URL_SCHEME</string>
        </array>
        <key>CFBundleURLName</key>
        <string>$BUNDLE_ID</string>
    </dict>
</array>
EOF

# ShareExtension Info.plist
cat > shareextension_infoplist_addition.xml << EOF
<!-- ADD THIS TO ios/ShareExtension/Info.plist inside the main <dict> -->

<key>AppGroupId</key>
<string>$APP_GROUP</string>
EOF

echo "✅ Created file: runner_infoplist_addition.xml"
echo "✅ Created file: shareextension_infoplist_addition.xml"
echo ""

# Create Flutter code snippet
cat > flutter_integration_snippet.dart << 'EOF'
// Add this to your lib/main.dart

import 'services/share_handler_service.dart';

class _MyAppState extends State<MyApp> {
  final ShareHandlerService _shareHandler = ShareHandlerService();

  @override
  void initState() {
    super.initState();
    _initializeShareHandler();
  }

  Future<void> _initializeShareHandler() async {
    await _shareHandler.initialize(
      onSharedMedia: (List<SharedMedia> mediaList) {
        for (var media in mediaList) {
          if (media.isUrl || media.isText) {
            print('📱 Received: ${media.path}');
            _saveToDatabase(media.path);
          }
        }
      },
    );
  }

  Future<void> _saveToDatabase(String url) async {
    // TODO: Implement your database save logic
    print('💾 Saving: $url');
  }

  @override
  void dispose() {
    _shareHandler.dispose();
    super.dispose();
  }
}
EOF

echo "✅ Created file: flutter_integration_snippet.dart"
echo ""

echo "📋 NEXT STEPS:"
echo ""
echo "1️⃣  Xcode - App Groups:"
echo "   • Open Xcode"
echo "   • Select Runner target → Signing & Capabilities"
echo "   • Add App Groups capability"
echo "   • Create new group: $APP_GROUP"
echo "   • Do the same for ShareExtension target (use SAME group)"
echo ""
echo "2️⃣  Update Info.plist files:"
echo "   • Copy content from: runner_infoplist_addition.xml"
echo "   • Paste into: ios/Runner/Info.plist (inside main <dict>)"
echo "   • Copy content from: shareextension_infoplist_addition.xml"
echo "   • Paste into: ios/ShareExtension/Info.plist (inside main <dict>)"
echo ""
echo "3️⃣  Integrate Flutter code:"
echo "   • Copy code from: flutter_integration_snippet.dart"
echo "   • Add to your lib/main.dart"
echo ""
echo "4️⃣  Build and test:"
echo "   • flutter clean"
echo "   • flutter build ios"
echo "   • Test: Safari → Share → Your App"
echo ""
echo "✅ Setup files created! Follow the steps above."
echo ""
EOF

chmod +x setup_helper.sh

echo "#!/bin/bash" > setup_helper.sh
cat >> setup_helper.sh << 'SCRIPT_END'

# Share Extension Setup Script
# This script will help you configure your Info.plist files

echo "🚀 Share Extension Setup Helper"
echo "================================"
echo ""

# Get bundle identifier
echo "Step 1: Find your Bundle Identifier"
echo "Open Xcode and go to: Runner target → General → Bundle Identifier"
echo ""
read -p "Enter your Bundle Identifier (e.g., com.example.linkat): " BUNDLE_ID

if [ -z "$BUNDLE_ID" ]; then
    echo "❌ Bundle ID is required!"
    exit 1
fi

APP_GROUP="group.$BUNDLE_ID"
URL_SCHEME="ShareMedia-$BUNDLE_ID"

echo ""
echo "✅ Configuration:"
echo "   Bundle ID:  $BUNDLE_ID"
echo "   App Group:  $APP_GROUP"
echo "   URL Scheme: $URL_SCHEME"
echo ""

# Create Info.plist additions
echo "Step 2: Creating Info.plist snippets..."
echo ""

# Runner Info.plist
cat > runner_infoplist_addition.xml << EOF
<!-- ADD THESE TO ios/Runner/Info.plist inside the main <dict> -->

<key>AppGroupId</key>
<string>$APP_GROUP</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>$URL_SCHEME</string>
        </array>
        <key>CFBundleURLName</key>
        <string>$BUNDLE_ID</string>
    </dict>
</array>
EOF

# ShareExtension Info.plist
cat > shareextension_infoplist_addition.xml << EOF
<!-- ADD THIS TO ios/ShareExtension/Info.plist inside the main <dict> -->

<key>AppGroupId</key>
<string>$APP_GROUP</string>
EOF

echo "✅ Created file: runner_infoplist_addition.xml"
echo "✅ Created file: shareextension_infoplist_addition.xml"
echo ""

# Create Flutter code snippet
cat > flutter_integration_snippet.dart << 'EOF'
// Add this to your lib/main.dart

import 'services/share_handler_service.dart';

class _MyAppState extends State<MyApp> {
  final ShareHandlerService _shareHandler = ShareHandlerService();

  @override
  void initState() {
    super.initState();
    _initializeShareHandler();
  }

  Future<void> _initializeShareHandler() async {
    await _shareHandler.initialize(
      onSharedMedia: (List<SharedMedia> mediaList) {
        for (var media in mediaList) {
          if (media.isUrl || media.isText) {
            print('📱 Received: ${media.path}');
            _saveToDatabase(media.path);
          }
        }
      },
    );
  }

  Future<void> _saveToDatabase(String url) async {
    // TODO: Implement your database save logic
    print('💾 Saving: $url');
  }

  @override
  void dispose() {
    _shareHandler.dispose();
    super.dispose();
  }
}
EOF

echo "✅ Created file: flutter_integration_snippet.dart"
echo ""

echo "📋 NEXT STEPS:"
echo ""
echo "1️⃣  Xcode - App Groups:"
echo "   • Open Xcode"
echo "   • Select Runner target → Signing & Capabilities"
echo "   • Add App Groups capability"
echo "   • Create new group: $APP_GROUP"
echo "   • Do the same for ShareExtension target (use SAME group)"
echo ""
echo "2️⃣  Update Info.plist files:"
echo "   • Copy content from: runner_infoplist_addition.xml"
echo "   • Paste into: ios/Runner/Info.plist (inside main <dict>)"
echo "   • Copy content from: shareextension_infoplist_addition.xml"
echo "   • Paste into: ios/ShareExtension/Info.plist (inside main <dict>)"
echo ""
echo "3️⃣  Integrate Flutter code:"
echo "   • Copy code from: flutter_integration_snippet.dart"
echo "   • Add to your lib/main.dart"
echo ""
echo "4️⃣  Build and test:"
echo "   • flutter clean"
echo "   • flutter build ios"
echo "   • Test: Safari → Share → Your App"
echo ""
echo "✅ Setup files created! Follow the steps above."
echo ""

SCRIPT_END

chmod +x setup_helper.sh
