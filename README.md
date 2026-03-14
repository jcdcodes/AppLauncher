# AppLauncher

A minimal macOS app launcher. Press **⌥A** anywhere, type part of an app name, hit **Return**.

## Install

Download the latest DMG from [Releases](https://github.com/jcdcodes/AppLauncher/releases), or build from source:

1. Open `AppLauncher.xcodeproj` in Xcode
2. Select your Mac as the run destination
3. Product → Run (or ⌘R)

The app has no dock icon (`LSUIElement = true`). It runs in the background with a small magnifying glass icon in the menu bar.

## First Launch: Accessibility Permission

macOS requires Accessibility permission for the global hotkey.

- On first launch, go to **System Settings → Privacy & Security → Accessibility**
- Enable **AppLauncher**

If the hotkey doesn't work, this is almost always why.

## Usage

| Key | Action |
|-----|--------|
| `⌥A` | Show launcher |
| Type | Filter by prefix or substring |
| `↑` / `↓` | Move selection |
| `Return` | Launch selected app |
| `Esc` | Dismiss |
| `⌘Q` | Quit AppLauncher |
| Click outside | Dismiss |

## Smart Search

- **Prefix matching**: "saf" → Safari
- **Substring matching**: "booth" → Photo Booth
- **Aliases**: "pref" opens System Settings, "term" opens Ghostty
- **Learning**: the launcher remembers which app you picked for each prefix and boosts it to the top next time

## Menu Bar

Click the magnifying glass icon in the menu bar to:

- View **About** info
- **Hide** the icon for 1 day or 1 week
- **Quit** AppLauncher

## Auto-start on Login

1. System Settings → General → Login Items
2. Click `+` and add AppLauncher

## Notes

- Scans `/Applications`, `/System/Applications`, `/System/Library/CoreServices/Applications`, and `~/Applications` (recursively)
- Also includes any currently running apps visible in ⌘Tab
- App list is cached at launch and auto-refreshes when apps are installed or removed
- No file search, web search, or anything else — apps only
