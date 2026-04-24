# add-string-weblate

An AI agent skill that adds a new localized string to an iOS project via the [Weblate](https://weblate.org) REST API, then rebuilds the string accessor files so the key is immediately usable in code.

## How it works

1. The agent determines all translations upfront, then calls `scripts/add-string.sh` once per string (in parallel for batches).
2. The script adds the unit to Weblate's source (English) translation via the REST API and patches all target languages.
3. The agent runs `./buildStrings` once after all strings are added, to pull updated translations and regenerate accessor files (e.g. via SwiftGen).
4. The agent reports each new key and how to access it in code.

## Prerequisites

### 1. `wlc` CLI

Install and configure:

```bash
pip install wlc
```

Create `~/.config/weblate`:

```ini
[weblate]
url = https://your-weblate-instance/api/

[keys]
https://your-weblate-instance/api/ = your_api_token
```

### 2. `.weblate` project config

Create a `.weblate` file in the root of your project:

```ini
[weblate]
translation = your-project/your-component
```

### 3. `buildStrings` script

Create a script named `buildStrings` in the root of your project. It should pull the latest translations from Weblate and regenerate any string accessor files (e.g. via SwiftGen).

Minimal example:

```bash
#!/bin/zsh
wlc download your-project/your-component
swiftgen
```

Make it executable:

```bash
chmod +x buildStrings
```

## Key naming convention

Keys use `lowercased_snake_case`. Start with the **feature name**, followed by enough context to make the key self-documenting:

```
<feature>_<context…>_<description>
```

Examples:

- `onboarding_welcome_title` — title on the welcome screen during onboarding
- `settings_notifications_toggle_label` — label for the notifications toggle in settings
- `checkout_alert_discard_action_confirm` — confirm button in a discard-changes alert
- `common_cancel` — shared/reusable string (use `common_` prefix for cross-feature strings)
- `profile_edit_save_button` — save button label in the profile editing flow

## String accessor pattern

A common example using SwiftGen generates a `Strings` enum:

```swift
Strings.profileEditSaveButton  // snake_case key converted to camelCase
```

Document the correct pattern in your project's AI instructions file (`CLAUDE.md`) so the agent reports it accurately.
