# AppLauncher

A minimal macOS app launcher. Press **⌥A** anywhere, type the start of an app name, hit **Return**.

## Build

1. Open `AppLauncher.xcodeproj` in Xcode
2. Select your Mac as the run destination
3. Product → Run (or ⌘R)

The app has no dock icon (`LSUIElement = true`). It runs in the background.

## First Launch: Accessibility Permission

macOS requires Accessibility permission to register a global hotkey.

- On first launch, go to **System Settings → Privacy & Security → Accessibility**
- Enable **AppLauncher**

If the hotkey doesn't work, this is almost always why.

## Usage

| Key | Action |
|-----|--------|
| `⌥A` | Show launcher |
| Type | Filter by prefix |
| `↑` / `↓` | Move selection |
| `Return` | Launch selected app |
| `Esc` | Dismiss |
| Click outside | Dismiss |

## Auto-start on Login

1. System Settings → General → Login Items
2. Click `+` and add AppLauncher

## Notes

- Scans `/Applications`, `/System/Applications`, and `~/Applications`
- App list is loaded fresh each time the hotkey is pressed (catches newly installed apps)
- No file search, web search, or anything else — apps only
