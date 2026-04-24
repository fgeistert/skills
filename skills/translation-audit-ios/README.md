# translation-audit-ios

An AI agent skill that audits translations in an iOS project by comparing `.lproj/Localizable.strings` files directly from the filesystem — no external services required. Flags issues by severity and presents a full report before touching anything.

## How it works

1. The agent locates both `.strings` files (base language and compare language) on disk.
2. It parses both files and compares every key across three severity levels:
   - **Clear bugs** — format specifier mismatches, untranslated strings, missing keys, duplicate translations, stray whitespace
   - **Grammar & consistency** — inconsistent terminology, grammar errors, action/toast alignment, imperative vs. indicative mixing
   - **Style & naturalness** — awkward phrasing, UI anti-patterns, length concerns
3. A full report is presented in a table grouped by severity.
4. **Nothing is changed** until the user explicitly approves fixes.
5. When fixes are applied, the agent edits the `.strings` file directly and optionally runs your project's `buildStrings` script to regenerate string accessors.

## Prerequisites

### `buildStrings` script (optional)

If your project uses a string accessor codegen tool (e.g. [SwiftGen](https://github.com/SwiftGen/SwiftGen)), create a script named `buildStrings` in the root of your project. The agent will run it automatically after applying fixes to keep generated files in sync.

Minimal example:

```bash
#!/bin/zsh
swiftgen  # or your codegen tool of choice
```

Make it executable:

```bash
chmod +x buildStrings
```

If no `buildStrings` script exists, the agent skips this step and only edits the `.strings` file.

## Usage

Invoke the skill by describing what you want to audit:

```
audit the German translations
check my French locale
are the Spanish strings ok?
review the Japanese translations
```

The agent resolves the language to the correct `.lproj` directory and runs the full audit. By default it treats `en.lproj` as the source of truth; you can specify a different base language explicitly.

## Supported project layouts

Any project structure with standard Apple `.lproj` directories works:

```
MyApp/
├── en.lproj/
│   └── Localizable.strings
├── de.lproj/
│   └── Localizable.strings
└── fr.lproj/
    └── Localizable.strings
```

Multiple `Localizable.strings` files across modules (e.g. in separate frameworks) are supported — each pair is audited separately and results are grouped by module path.

## AI agent integration

### Claude Code

Place this skill in `~/.claude/skills/translation-audit-ios/`. Claude Code will automatically load `SKILL.md` and trigger the skill whenever you ask to audit, check, or review translations.

### Codex / other agents

Paste the relevant sections of `SKILL.md` (Steps 1–4) into your agent instructions (e.g. `AGENTS.md`) and point the agent to the `.lproj` directories in your project.
