---
name: add-string-weblate
description: >
  Adds a new localized string to an iOS project using the Weblate REST API, translates it
  to all configured languages, then rebuilds string accessor files so the key is immediately
  usable in code. Use when adding any user-facing text: labels, titles, messages, button
  text, alerts, toasts, or any other string that needs to be localized. Relevant keywords:
  string, localization, Weblate, i18n, Localizable.strings, translation key.
license: MIT
compatibility: Requires wlc (pip install wlc), a ~/.config/weblate config, and a .weblate file in the project root.
metadata:
  author: fgeistert
  version: "3.0.0"
---

# Add Localized String

This skill adds one or more localized strings to your iOS app. It is designed to minimize
tool calls: Claude determines all translations upfront, then makes one script call per
string (in parallel for batches), then runs `buildStrings` exactly once.

**Tool call budget:**
- 1 string → 2 calls (script + buildStrings)
- N strings → N+1 calls (N parallel scripts + buildStrings)

## Prerequisites

1. **`wlc` CLI** — `pip install wlc`. Config at `~/.config/weblate`.
2. **`.weblate`** — project root config file with the component slug.
3. **`buildStrings`** — executable script in the project root.

## Naming Convention

Keys use `lowercased_snake_case`, starting with the feature name:
`<feature>_<context…>_<description>`

Examples: `common_cancel`, `profile_edit_save_button`, `onboarding_welcome_title`

Check your project's `CLAUDE.md` for project-specific naming conventions.

## Steps

### 1. Determine all keys, English values, and translations

Before making any tool calls:
- Choose the key(s) following the naming convention
- Write the English text
- Translate each string to every non-English language using your own translation ability.
  Produce natural, idiomatic translations appropriate for a mobile app UI — concise,
  matching the register and length of the English original.

To find what languages are configured, read `.weblate` for the component slug, then call:
```
GET /api/components/{project}/{component}/translations/
```
using the URL and token from `~/.config/weblate`. Filter out the source language (`en`).

### 2. Run the script (once per string, in parallel for batches)

```bash
bash "$HOME/.claude/skills/add-string-weblate/scripts/add-string.sh" \
  "<key>" "<english>" \
  de:"<german>" \
  fr:"<french>"
```

Pass every non-English translation as `lang:"text"` arguments. The script adds the
English source to Weblate and patches all target languages in one call.

**If any call fails or returns a non-zero exit code, stop immediately** and report the error.

### 3. Run buildStrings once

```bash
./buildStrings
```

Run this once after all script calls complete, regardless of how many strings were added.

### 4. Inform the user

For each string, show the translations and the Swift accessor:

```swift
Strings.<camelCaseKey>   // snake_case → camelCase
```

## Example — single string

**User:** "Add a save button label for the profile editing screen"

Languages configured: `de`

Translations determined upfront: `de` → "Speichern"

```bash
bash "$HOME/.claude/skills/add-string-weblate/scripts/add-string.sh" \
  "profile_edit_save_button" "Save" \
  de:"Speichern"
```

```bash
./buildStrings
```

> Done! Added `profile_edit_save_button`:
> - 🇬🇧 en: "Save" · 🇩🇪 de: "Speichern"
>
> ```swift
> Strings.profileEditSaveButton
> ```

## Example — multiple strings

**User:** "Add a title and subtitle for the onboarding welcome screen"

Languages configured: `de`

Translations determined upfront before any tool calls.

```bash
# run in parallel:
bash "$HOME/.claude/skills/add-string-weblate/scripts/add-string.sh" \
  "onboarding_welcome_title" "Welcome to MyApp" \
  de:"Willkommen bei MyApp"

bash "$HOME/.claude/skills/add-string-weblate/scripts/add-string.sh" \
  "onboarding_welcome_subtitle" "Get started in seconds." \
  de:"Leg sofort los."
```

```bash
./buildStrings
```
