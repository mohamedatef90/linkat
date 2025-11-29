# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Linkat is a Flutter mobile app for saving and organizing links with automatic platform detection, AI-generated descriptions (via Google Gemini), and iOS Share Extension support.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Generate Isar database code (required after modifying link_model.dart)
flutter pub run build_runner build --delete-conflicting-outputs

# Run static analysis
flutter analyze

# Run the app (debug mode)
flutter run

# Build for iOS simulator
flutter build ios --simulator

# Generate app icons
flutter pub run flutter_launcher_icons
```

## iOS Release Build (Physical Device)

```bash
# 1. Clean previous builds
flutter clean
flutter pub get

# 2. Build release IPA
flutter build ios --release

# 3. Open Xcode for signing and deployment
open ios/Runner.xcworkspace
```

**In Xcode:**
1. Select your physical iPhone from the device dropdown
2. Select "Runner" target → Signing & Capabilities
3. Select your Team (Apple Developer account)
4. Ensure "Automatically manage signing" is checked
5. Do the same for "ShareExtension" target
6. Press `Cmd + R` or click Play to build and run on device

**Alternative: Direct install via command line**
```bash
# Build and run on connected iPhone
flutter run --release

# Or install without running
flutter install --release
```

**Requirements:**
- Apple Developer account (free or paid)
- iPhone connected via USB and trusted
- Xcode with valid signing certificates

## Architecture

The app follows a clean architecture pattern with three layers:

### Domain Layer (`lib/domain/`)
- `entities/` - Core business objects: `Link`, `PlatformType` (social platforms), `TopicType` (content categories)
- `repositories/` - Repository interfaces (`ILinkRepository`)
- `usecases/` - Business logic operations (`GetLinks`, `SaveLink`, `DeleteLink`)

### Data Layer (`lib/data/`)
- `models/` - Isar database models (`LinkModel` with `.g.dart` generated file)
- `repositories/` - Repository implementations using Isar
- `services/` - External integrations:
  - `MetadataService` - Fetches OpenGraph/meta tags from URLs
  - `PlatformDetectionService` - Identifies platform from URL (Facebook, Instagram, X, YouTube, LinkedIn)
  - `TopicClassificationService` - Classifies content topic
  - `AiDescriptionService` - Generates descriptions via Gemini API

### Presentation Layer (`lib/presentation/`)
- `screens/` - Main screens: `HomeScreen`, `AddLinkScreen`, `FolderDetailScreen`, `LinkDetailScreen`
- `providers/` - Riverpod providers for state management
- `theme/` - App theming (`NotionTheme`)
- `widgets/` - Reusable UI components

### Services (`lib/services/`)
- `ShareHandlerService` - Handles iOS Share Extension integration via platform channels

## State Management

Uses Riverpod. Key providers in `lib/presentation/providers/link_providers.dart`:
- `linksProvider` - Fetches links, optionally filtered by platform
- `searchLinksProvider` - Searches links by query
- Service providers for DI

## Database

Uses Isar for local persistence. After modifying `LinkModel`, regenerate with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## iOS Share Extension

Located in `ios/ShareExtension/`. Requires App Groups configuration for data sharing between extension and main app. See `ios/ShareExtension/SHARE_EXTENSION_SETUP.md` for setup instructions.

## Environment Configuration

Create `.env` file in project root with:
```
GEMINI_API_KEY=your_api_key_here
```
AI descriptions work without this, but will be disabled.

## Routing

Uses go_router. Routes defined in `lib/main.dart`:
- `/` - Home screen
- `/add` - Add link screen (optional `url` query param)
- `/folder/:platform` - Platform-specific folder view

