# Mara FM — Claude Code Context Brief

## Project Overview
Mara FM 106.7 FM is a radio station based in Bandung, Indonesia. This repository contains the Flutter mobile/web app. There is also a separate Next.js admin studio.

---

## Repository Structure

### Flutter App (this repo)
- **Local path:** `/Users/kemalhidayat/.gemini/antigravity/scratch/mara_fm_2`
- **GitHub:** `kemalmph/marafm`
- **Live URL:** `marafm.com` (Vercel)
- **Bundle ID:** `com.kemalhidayat.marafm`

### Next.js Studio (separate repo)
- **Local path:** `/Users/kemalhidayat/marafm-admin`
- **GitHub:** `kemalmph/marafm-admin`
- **Live URL:** `studio.marafm.com` (Vercel)

---

## Flutter App Stack
- Flutter + BLoC pattern (`flutter_bloc`)
- Supabase (`supabase_flutter`) — DB, Auth, Storage, Edge Functions
- `just_audio` for radio streaming
- `youtube_player_flutter` for Podcast tab
- OneSignal (`onesignal_flutter: ^5.2.5`) for push notifications
- Credentials via `String.fromEnvironment()` with `defaultValue` fallback
- **No `lucide_icons`** — removed, incompatible with Flutter 3.44+, use Flutter's built-in `Icons`

### Environment Variables (dart-define)
```
SUPABASE_URL=https://bgztfukvlxnmprnlisad.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnenRmdWt2bHhubXBybmxpc2FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjAwNzgsImV4cCI6MjA5MTI5NjA3OH0.np-4GpjhI9B8iFxtvJrq7wgFarzTLjypUMnOlPRURQU
```
Local dev: `flutter run -d chrome` (no --dart-define needed, defaultValue handles it)

---

## App Tabs (Bottom Navigation)
| Index | Tab | Content |
|---|---|---|
| 0 | Player | Radio player, CRT-style UI, channel selector, now playing |
| 1 | On Air | Current program schedule, live info |
| 2 | Podcast | YouTube playlist |
| 3 | News | Instagram feed from @marafmbdg |
| 4 | Settings | Profile, liked songs, contact info |

---

## Key Architecture Decisions

### Channel Type System
- `channel_type: 'internal'` = Mara FM owned (always accessible)
- `channel_type: 'external'` = Third-party stations (auth-gated)
- **Never** hardcode `channel.name == 'MARA FM'` — always use `channel.channelType == 'internal'`

### Config System
- All config from Supabase via `ConfigService.fetchConfig()` on startup
- Cached in `ConfigBloc` — no loading flicker
- Auto-refreshes on app resume (`WidgetsBindingObserver`)
- Pull-to-refresh in PlayerTab
- `RefreshConfigRequested` event re-fetches without emitting loading state

### Auth
- Supabase Auth (Email)
- External channels require login
- Anonymous listener tracking via `device_id` in SharedPreferences

### Listener Tracking
- All sessions tracked in `listener_sessions` (anonymous + logged in)
- `device_id` in SharedPreferences, `is_anonymous: true` for guests

### Share Message Template
- Stored in `site_config` key `share_message_template`
- Placeholders: `{title}`, `{artist}`, `{channel}`
- Default: `I love this song! Now playing on Mara FM{channel}: {title} - {artist} [https://marafm.com]`

---

## Push Notifications (OneSignal)
- **App ID:** `4c7d8443-8af8-4753-a78f-566c831f15ca`
- Initialized with `if (!kIsWeb)` guard in `main.dart`
- `MainScreen.globalKey` + static `navigateTo(int index)` for cross-widget navigation

### Notification Types
| `type` | Action |
|---|---|
| `youtube_video` | Navigate to Podcast tab (index 2) |
| `manual` | URL opened by OneSignal SDK automatically |
| `news` | Navigate to News tab (index 3) |
| unknown | Do nothing |

---

## Supabase Backend
- **Project:** `bgztfukvlxnmprnlisad.supabase.co` (Singapore)
- **Superadmin:** `kemalmph@yah.com`

### Key Tables
| Table | Purpose |
|---|---|
| `channels` | Radio channels, stream URLs, metadata URLs, channel_type |
| `profiles` | User profiles (role: user/admin/superadmin) |
| `listener_sessions` | All sessions including anonymous, with device_id |
| `liked_songs` | Per-user liked songs |
| `now_playing_log` | Song history from AzuraCast (3,484+ records) |
| `listener_stats` | Daily AzuraCast listener snapshots |
| `news_feed` | Instagram posts from @marafmbdg |
| `posts` | Blog posts (slug, body, status, featured_image_url) |
| `site_config` | Key-value app config |
| `youtube_videos` | YouTube video tracking for push notifications |
| `push_notification_log` | All push notifications (manual + auto) |
| `social_uploads` | Storage upload tracking with auto-delete |
| `song_requests` | Schema ready, feature-flagged off |

### Key site_config
| Key | Notes |
|---|---|
| `share_message_template` | Share message with {title} {artist} {channel} |
| `onesignal_app_id` | `4c7d8443-8af8-4753-a78f-566c831f15ca` |
| `onesignal_api_key` | secret |
| `azuracast_base_url` | `https://s1.gntr.net` |
| `azuracast_api_key` | secret |
| `youtube_api_key` | YouTube Data API v3 |
| `youtube_playlist_id` | `PL0D016RZTNd9Gbr8Ma96MdrqoD0KwVYLq` |
| `instagram_access_token` | secret |
| `instagram_business_id` | `17841477894274117` |
| `now_playing_cache` | JSON cache of latest AzuraCast data |

### Edge Functions
| Function | Purpose |
|---|---|
| `sync-instagram` | Fetch Instagram → `news_feed` |
| `instagram-post` | Post to Instagram Graph API |
| `azuracast-sync` | AzuraCast now playing + listeners → cache + logs |
| `sync-youtube` | New YouTube videos → OneSignal push |
| `send-notification` | Manual push notification from studio |
| `cleanup-social-uploads` | Delete expired Storage images |
| `admin-user-actions` | Reset password, delete user |

### Cron Jobs
| Job | Schedule | Purpose |
|---|---|---|
| `azuracast-sync-daily` | `0 17 * * *` (00:00 WIB) | AzuraCast sync |
| `sync-youtube-daily` | `0 3 * * *` (10:00 WIB) | YouTube check |

### SQL Helper Functions
- `get_user_role()` — RLS helper
- `update_now_playing_cache(cache_value text)` — SECURITY DEFINER
- `bulk_insert_now_playing_log(rows jsonb)` — SECURITY DEFINER

---

## AzuraCast
- **Base URL:** `https://s1.gntr.net` (shared hosting by gntr.net)
- **Stream URL:** `https://s1.gntr.net/listen/marafm/marafm`
- **Now Playing API:** `https://s1.gntr.net/api/nowplaying/marafm`
- `/api/station/marafm/listeners` and `/api/station/marafm/history` available with API key
- Reports API NOT available — use `now_playing_log` data instead

---

## Vercel Deployment (Flutter)
```json
{
  "buildCommand": "git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter && /opt/flutter/bin/flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY",
  "outputDirectory": "build/web",
  "framework": null
}
```
Push to `main` → auto-deploy. `web/sitemap.xml` and `web/robots.txt` included in build.

---

## Known Patterns & Gotchas
- Use `kIsWeb` / `defaultTargetPlatform` — never `Platform._operatingSystem`
- `AudioOutputSelector` wrapped with `kIsWeb` guard
- `lucide_icons` REMOVED — use Flutter material `Icons` instead
- OneSignal must be `if (!kIsWeb)` — not supported on web
- RLS bypass via SECURITY DEFINER functions for Edge Function writes

---

## SEO (marafm.com)
- `web/index.html` has full meta, OpenGraph, Twitter Card, Schema.org RadioStation
- Google Search Console verified, sitemap submitted
- `web/robots.txt` and `web/sitemap.xml` in build output

---

## Next.js Studio — Open separate Claude Code session in `/Users/kemalhidayat/marafm-admin`

### Stack
- Next.js App Router, Tailwind CSS v4, Supabase SSR, Tiptap

### Pages
| Route | Purpose |
|---|---|
| `/admin` | Dashboard |
| `/admin/analytics` | AzuraCast + listener charts |
| `/admin/posts` | Blog CRUD + Instagram share |
| `/admin/social` | Instagram post composer |
| `/admin/notifications` | Push notification composer + history |
| `/admin/programs` | Program schedule CRUD |
| `/admin/channels` | Channel CRUD |
| `/admin/users` | User management |
| `/admin/settings` | site_config editor |
| `/news` | Public news list |
| `/news/[slug]` | Public article |
| `/privacy-policy` | Public privacy policy |

### Key Components
- `NotificationComposer` — manual push with title, body, URL, image, templates
- `ListenerCharts` — bar charts by day/hour/DOW, average/unique toggle
- `AzuraCastWidget` — manual sync button
- `ChannelsEditor` — channel CRUD
- `PostEditor` — Tiptap + Instagram share panel
- `Sidebar` — collapsible mobile drawer, fixed desktop
