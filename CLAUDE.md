# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Linkat is the Flutter mobile client of **RefVault** (evolved from BentoLinks): an AI knowledge vault backed by Supabase. Links are saved through the `save-item` Edge Function, parsed and AI-enriched **server-side** (Gemini runs in Edge Functions, not on-device), and synced into a local Isar cache so the app works offline. The web client lives in the `bentolinks-ai` repo and shares the same backend and accounts.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Generate Isar database code (required after modifying link_model.dart)
flutter pub run build_runner build --delete-conflicting-outputs

# Run static analysis
flutter analyze

# Run tests (sync service unit tests + auth widget tests)
flutter test

# Run the app (debug mode)
flutter run

# Build for iOS simulator
flutter build ios --simulator
```

## iOS Release Build (Physical Device)

```bash
flutter clean && flutter pub get
flutter build ios --release
open ios/Runner.xcworkspace
```

**In Xcode:** select your iPhone, set the Team under Signing & Capabilities for both the "Runner" and "ShareExtension" targets (automatic signing), then Cmd+R. Or `flutter run --release` / `flutter install --release` with the phone connected.

## Backend (Supabase project `sjskpjgepbvblojohtlr`)

- **Auth:** email + password (same account as the web app). URL + anon key are hardcoded in `lib/main.dart` (the anon key is public by design; RLS enforces access).
- **Tables:** `content_items` (url, title, description, summary, key_points, tags[], topic, source_type, status, thumbnail_url, is_pinned, is_starred, read_status, …), `folders`, `item_folders`, `smart_collections`. RLS = `user_id = auth.uid()`. Realtime is enabled on `content_items`.
- **save-item Edge Function:** `POST /functions/v1/save-item` with user JWT, body `{url, folder_id?}` → 202 `{id, url, title, status:'pending', duplicate:false}`. The server then parses + enriches asynchronously (~1 min): `status` flips `pending → parsing → enriching → ready` (or `degraded`/`failed`).
- New saves must ALWAYS go through save-item — never insert into `content_items` directly.

## Architecture

Clean architecture, three layers:

### Domain Layer (`lib/domain/`)
- `entities/` — `Link` (now carries sync fields: `remoteId`, `updatedAt`, `pendingOp`, `summary`, `keyPoints`, `topicLabel`, `status`, `readStatus`, `isStarred`, `isPinned`, `folderRemoteIds`), `PlatformType`, `TopicType`, `ContentType`, `sync_types.dart` (`PendingOp`, `ItemStatus`)
- `repositories/` — `ILinkRepository`
- `usecases/` — `GetLinks`, `SaveLink`, `DeleteLink` (local reads; writes go through the sync service)

### Data Layer (`lib/data/`)
- `models/` — Isar models (`LinkModel` + generated `.g.dart`; regenerate after edits)
- `datasources/remote/supabase_datasource.dart` — content_items/folders CRUD, save-item invocation, content_text fetch, Realtime subscription, row → `Link` mapping
- `repositories/` — `LinkRepositoryImpl` (Isar reads), `IsarSyncLocalStore` (sync-side Isar access + `lastSyncAt` in SharedPreferences)
- `services/`
  - `sync_service.dart` — **the sync engine** (see below)
  - `MetadataService` — OpenGraph fetch, used ONLY for an instant local preview before the server result arrives
  - `PlatformDetectionService`, `ContentTypeDetectionService` — pure URL-based helpers
  - (All on-device AI services were removed — the server pipeline replaced them)

### Sync (deliberately simple, server wins)
`SyncService` operates on two small interfaces (`SyncRemoteStore` = SupabaseDatasource, `SyncLocalStore` = IsarSyncLocalStore) so it's unit-testable with fakes (`test/sync_service_test.dart`).

- **PULL** (app start/resume/Realtime/pull-to-refresh): `content_items` with `updated_at >= lastSyncAt` upserted into Isar by `remoteId`; local rows with a queued `pendingOp` are skipped (their push reconciles later); local synced rows whose id no longer exists server-side are pruned; `lastSyncAt` advances to the newest `updated_at`.
- **PUSH:** local writes apply optimistically with a `pendingOp` flag (`create`/`update`/`delete`); the flush sends create → save-item, update → PATCH of {title, is_pinned, is_starred, read_status}, delete → DELETE, then clears the flag. Failed ops (offline) stay queued and flush on reconnect (connectivity_plus listener).
- **Conflicts:** server wins — a re-pull overwrites local state.

### Presentation Layer (`lib/presentation/`)
- `screens/` — `HomeScreen` (platforms, folders, local search, sync start), `AddLinkScreen` (URL → save-item + folder picker + metadata preview), `AuthScreen`, `ReaderScreen` (summary/key points/tags/content_text), `LinkDetailScreen` (status chip, star/pin/read toggles), `FolderItemsScreen`, `ManageFoldersScreen`, `FolderDetailScreen` (per-platform), `TagsScreen`, `TopicsScreen`, `SplashScreen`
- `providers/` — `link_providers.dart` (local Isar reads), `auth_providers.dart`, `sync_providers.dart` (`SyncController`: orchestrates sync triggers + optimistic writes, Realtime + connectivity subscriptions, `foldersProvider`, `contentTextProvider`)
- `widgets/status_chip.dart` — pending/parsing/enriching spinner, degraded/failed badges, waiting-to-sync badge
- `theme/` — `NotionTheme`

### Services (`lib/services/`)
- `PendingLinksService` — reads links parked by the iOS Share Extension (shared UserDefaults); home screen forwards them to save-item
- `ShareHandlerService` — receive_sharing_intent plumbing

## State Management

Riverpod. Reads come from Isar via `link_providers.dart`; ALL writes (save/update/delete) go through `syncControllerProvider` so they're pushed to Supabase and providers get invalidated.

## Routing

go_router in `lib/main.dart` with an auth guard (`redirect` + `refreshListenable` on Supabase auth state):
- `/splash` — animated splash
- `/auth` — sign in / sign up (unauthenticated users are redirected here)
- `/` — home; `/add` (optional `url` query param); `/folder/:platform`
- Reader / folder-items / manage-folders are pushed with Navigator.

## iOS Share Extension

Located in `ios/ShareExtension/`; requires App Groups. Shared URLs are saved through save-item with the stored session JWT (one toast, no extra taps); when offline they park as pending creates and flush on reconnect. See `ios/ShareExtension/SHARE_EXTENSION_SETUP.md`.

## Environment Configuration

None required — no `.env`, no client-side AI keys. The Gemini key lives in Supabase Vault and is only used by Edge Functions.

## Database

Isar is a local **cache** of `content_items`, not the source of truth. After modifying `LinkModel`, regenerate with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
