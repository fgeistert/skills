# add-string-texterify

An AI agent skill that adds a new localized string to an iOS project via the [Texterify](https://texterify.com) CLI, then rebuilds the string accessor files so the key is immediately usable in code.

## How it works

1. The agent calls `scripts/add-string.sh` with the key and translation.
2. The script adds the key to Texterify via the CLI.
3. The script runs your project's `./buildStrings` script to export updated translations and regenerate accessor files (e.g. via SwiftGen).
4. The agent reports the new key and how to access it in code.

## Prerequisites

### 1. Texterify CLI

Install and authenticate:

```bash
brew install texterify/texterify/texterify
texterify login
```

### 2. `buildStrings` script

Create a script named `buildStrings` in the root of your project. This script should download the latest translations from Texterify and regenerate any string accessor files your project uses (e.g. via SwiftGen or a custom codegen step).

Minimal example:

```bash
#!/bin/zsh
texterify export
swiftgen  # or your codegen tool of choice
```

Make it executable:

```bash
chmod +x buildStrings
```

You can also run `./buildStrings` manually at any time to refresh string files without adding a new key.

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

Avoid generic keys like `button_ok` or `error` — the key should read like documentation.

**Add project-specific naming examples and conventions to your project's AI instructions file** (e.g. `CLAUDE.md`, `AGENTS.md`) under a section titled **String Naming Conventions**. The agent will refer to that section when choosing a key name.

## String accessor pattern

The exact way you access a string in code depends on your project's codegen setup. A common example using SwiftGen generates a `Strings` enum:

```swift
Strings.profileEditSaveButton  // snake_case key converted to camelCase
```

Your project may use a different pattern (e.g. `L10n.key`, `NSLocalizedString`, etc.). Document the correct pattern in your project's AI instructions file so the agent can report it accurately.

## AI agent integration

### Claude Code

Place this skill in `~/.claude/skills/add-string-texterify/`. Claude Code will automatically load `SKILL.md` and trigger the skill whenever you ask to add a string or localization key.

### Codex / other agents

The shell script in `scripts/add-string.sh` is agent-agnostic. To use it with any other AI agent:

1. Point the agent to `scripts/add-string.sh` in your project instructions (e.g. `AGENTS.md`).
2. Paste the relevant sections of this README (naming conventions, accessor pattern) into your agent instructions.
3. Instruct the agent to call the script with `<key>` and `<english_translation>` arguments and report the result.

Example instruction for `AGENTS.md`:

```markdown
## Adding localized strings

To add a new string, run:
  bash path/to/add-string-texterify/scripts/add-string.sh "<key>" "<translation>"

Keys use lowercased_snake_case, starting with the feature name: `profile_edit_save_button`.
After the script completes, report the key and its Swift accessor: `Strings.<camelCaseKey>`.
```
