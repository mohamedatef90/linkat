# Linkat

<p align="center">
  <img src="assets/linkat.png" alt="Linkat Logo" width="200"/>
</p>

<p align="center">
  <strong>Save, organize, and rediscover your links with AI-powered intelligence</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#architecture">Architecture</a>
</p>

---

## Overview

Linkat is a Flutter mobile app designed to help you save and organize links from various platforms. It automatically detects the platform (Facebook, Instagram, X/Twitter, YouTube, LinkedIn), categorizes content using AI, and generates smart descriptions to help you find your saved links later.

## Features

### Core Features
- **Save Links Instantly** - Quick link saving with automatic metadata extraction
- **iOS Share Extension** - Save links directly from any app using the iOS share sheet
- **Platform Detection** - Automatic detection of social media platforms (Facebook, Instagram, X, YouTube, LinkedIn)
- **Smart Thumbnails** - Automatically fetches and displays link previews with images

### AI-Powered Intelligence
- **Auto-Categorization** - AI classifies links into 8 topic categories:
  - AI & Tech
  - Development
  - Product & UX
  - Design
  - Business
  - Science
  - Entertainment
  - Other
- **Smart Tags** - AI generates relevant tags for easy searching
- **AI Descriptions** - Generates concise summaries of linked content using Google Gemini
- **AI Search** - Natural language search to find links semantically

### Organization
- **Platform Folders** - View links organized by social platform
- **Topic Filtering** - Filter links by category/topic
- **Tag System** - Browse and filter by auto-generated or custom tags
- **Bulk Actions** - Assign topics to multiple links at once

### Advanced Features
- **Manual Override** - Add custom titles, descriptions, and tags
- **Duplicate Detection** - Warns when saving duplicate links with replace/discard options
- **Translation** - Translate AI summaries to 10+ languages
- **Dark Mode Support** - Beautiful UI that respects system preferences

## Screenshots

<!-- Add your screenshots here -->
<!--
<p align="center">
  <img src="screenshots/home.png" width="200" />
  <img src="screenshots/add_link.png" width="200" />
  <img src="screenshots/folder.png" width="200" />
  <img src="screenshots/detail.png" width="200" />
</p>
-->

## Installation

### Prerequisites
- Flutter SDK ^3.10.1
- Xcode (for iOS development)
- CocoaPods

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/linkat.git
   cd linkat
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Isar database code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure environment variables**

   Create a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your_google_gemini_api_key_here
   ```

   > Note: The app works without the API key, but AI features will be disabled.

5. **Generate app icons**
   ```bash
   flutter pub run flutter_launcher_icons
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### iOS Release Build

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build for release
flutter build ios --release

# Open in Xcode for signing
open ios/Runner.xcworkspace
```

In Xcode:
1. Select your physical iPhone from the device dropdown
2. Configure signing for both "Runner" and "ShareExtension" targets
3. Press `Cmd + R` to build and run

## Usage

### Saving a Link

**Method 1: In-App**
1. Open Linkat
2. Tap the "+" button
3. Paste or type the URL
4. (Optional) Expand "Advanced Options" to add custom title, description, or tags
5. (Optional) Select a topic category
6. Tap "Save Link"

**Method 2: Share Extension**
1. In any app (Safari, social media, etc.), find a link you want to save
2. Tap the Share button
3. Select "Linkat" from the share sheet
4. The link will be saved automatically with AI processing

### Browsing Links

- **Home Screen** - See all platforms as folders with link counts
- **Platform Folders** - Tap a platform to see all links from that source
- **Topics** - Browse links by category
- **Tags** - Search and filter by tags

### Managing Links

- **View Details** - Tap any link to see full details, AI summary, and translation options
- **Change Topic** - In link details, tap the topic badge to reassign
- **Delete** - Swipe or use the delete option in link details
- **Share** - Share links directly from the app

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Local Database**: Isar
- **Routing**: go_router
- **AI/ML**: Google Gemini API
- **HTTP**: http package
- **HTML Parsing**: html package

## Architecture

The app follows Clean Architecture principles with three main layers:

```
lib/
├── data/
│   ├── models/          # Isar database models
│   ├── repositories/    # Repository implementations
│   └── services/        # External services (metadata, AI, etc.)
├── domain/
│   ├── entities/        # Core business objects
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Business logic operations
├── presentation/
│   ├── providers/       # Riverpod providers
│   ├── screens/         # UI screens
│   ├── theme/           # App theming
│   └── widgets/         # Reusable components
└── services/
    └── share_handler/   # iOS Share Extension handling
```

### Key Components

| Component | Description |
|-----------|-------------|
| `MetadataService` | Fetches OpenGraph metadata from URLs |
| `PlatformDetectionService` | Identifies social platforms from URLs |
| `AiClassificationService` | AI-powered topic and tag generation |
| `AiDescriptionService` | Generates link summaries |
| `LinkRepository` | Isar database operations |

## iOS Share Extension

The app includes an iOS Share Extension for saving links from any app. Setup instructions are in `ios/ShareExtension/SHARE_EXTENSION_SETUP.md`.

Key points:
- Requires App Groups configuration
- Both main app and extension must share the same App Group
- Links shared via extension are processed when the main app opens

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GEMINI_API_KEY` | Google Gemini API key for AI features | Optional |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Riverpod](https://riverpod.dev/) - State management
- [Isar](https://isar.dev/) - Local database
- [Google Gemini](https://ai.google.dev/) - AI capabilities
- [Font Awesome](https://fontawesome.com/) - Icons

---

<p align="center">
  Made with ❤️ using Flutter
</p>
