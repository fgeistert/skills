---
name: add-string-texterify
description: >
  Adds a new localized string to an iOS project using the Texterify CLI, then rebuilds
  string accessor files so the key is immediately usable in code. Use when adding any
  user-facing text: labels, titles, messages, button text, alerts, toasts, or any other
  string that needs to be localized. Relevant keywords: string, localization, Texterify,
  i18n, Localizable.strings, translation key.
license: MIT
compatibility: Requires the Texterify CLI (brew install texterify/texterify/texterify) and git.
metadata:
  author: fgeistert
  version: "1.0.0"
---

# Add Localized String

This skill adds a new localized string to your iOS app via the Texterify CLI,
then syncs the generated string accessor so you can use it immediately in code.

## Prerequisites

Before using this skill, ensure the following are in place:

1. **Texterify CLI** — must be installed and authenticated.
   Install via Homebrew: `brew install texterify/texterify/texterify`
   Authenticate: `texterify login`

2. **`buildStrings` script** — must exist and be executable in the project root.
   This script downloads the latest strings from Texterify and regenerates your
   string accessor files (e.g. via SwiftGen or a custom codegen step).
   It is project-specific and not bundled with this skill — you need to create
   and maintain it yourself. A minimal example:
   ```bash
   #!/bin/zsh
   texterify export
   swiftgen  # or your codegen tool of choice
   ```
   Make it executable: `chmod +x buildStrings`

   You can also run `./buildStrings` manually at any time to refresh local string
   files without adding a new key (e.g. after pulling changes from teammates).

## Naming Convention

Keys use `lowercased_snake_case`. Always start with the **feature name**, followed by
enough context to make the key self-documenting:

- `onboarding_welcome_title` — title on the welcome screen during onboarding
- `settings_notifications_toggle_label` — label for the notifications toggle in settings
- `checkout_alert_discard_action_confirm` — confirm button in a discard-changes alert
- `common_cancel` — a shared/reusable string (use `common_` prefix for cross-feature strings)
- `profile_edit_save_button` — save button label in the profile editing flow

The pattern is: `<feature>_<context…>_<description>`. Be specific — the key should read
like documentation. Avoid generic keys like `button_ok` or `error`.

**Project-specific conventions:** Check your project's `CLAUDE.md` (or equivalent AI
instructions file) for team-agreed naming conventions and examples specific to your
app's feature structure. Look for a section titled **String Naming Conventions**.

## Steps

### 1. Add the string and rebuild string files

Run the bundled script, passing the key and translation as arguments:

```bash
bash "$HOME/.claude/skills/add-string-texterify/scripts/add-string.sh" "<key>" "<english_translation>"
```

- The key must be `lowercased_snake_case`.
- The translation is the English text exactly as it should appear to the user.
- The script handles PATH setup, Texterify, and `buildStrings` in one step.
- **If this command fails or returns a non-zero exit code, stop immediately** and tell
  the user what failed. Do not attempt to continue or retry.

### 2. Inform the user

Tell the user the string is ready and show how to access it in code. The exact accessor
depends on your project's codegen setup — check your project's `CLAUDE.md` for the
correct pattern. A common example using SwiftGen:

```swift
Strings.<camelCaseKey>
```

Convert the snake_case key to camelCase for the accessor:
- `onboarding_welcome_title` → `Strings.onboardingWelcomeTitle`
- `settings_notifications_toggle_label` → `Strings.settingsNotificationsToggleLabel`
- `common_cancel` → `Strings.commonCancel`

> **Note:** The `Strings.<camelCaseKey>` pattern assumes SwiftGen (or similar codegen)
> is configured to generate a `Strings` enum. Your project may use a different accessor
> pattern — always verify against your project's codegen setup.

## Example

**User:** "Add a save button label for the profile editing screen"

**Reasoning:** Feature is `profile`, context is `edit`, description is `save_button`.

**Command:**
```bash
bash "$HOME/.claude/skills/add-string-texterify/scripts/add-string.sh" "profile_edit_save_button" "Save"
```

**Response to user:**
> Done! The string has been added. Access it in Swift with:
> ```swift
> Strings.profileEditSaveButton
> ```
