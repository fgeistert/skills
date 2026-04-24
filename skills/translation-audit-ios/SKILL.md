---
name: translation-audit-ios
description: >
  Audits translations in an iOS project by comparing two .strings locale files directly
  from the filesystem — no external services required. Flags issues by severity and
  presents a full report before touching anything. Use this skill whenever the user wants
  to check, review, validate, or audit translations in an iOS app — even if phrased as
  "are the German strings ok?", "check my translations", "review the French locale", or
  "make sure nothing is wrong with the translations". Only applies to iOS projects with
  .lproj/Localizable.strings files on the local filesystem. Does not apply to web,
  Android, Flutter, or other platforms, and does not connect to any external service.
license: MIT
metadata:
  author: fgeistert
  version: "1.0.0"
---

# Translation Audit — iOS

Audit translations in an iOS project by reading `.lproj/Localizable.strings` files
directly from disk. No external tools or services required. **Do not change anything** —
present findings and wait for the user to decide what to fix.

## Parameters

- `base_language` — the source of truth (default: `en`)
- `compare_language` — the language to audit (required)

## Step 1 — Locate the strings files

Search the project for `Localizable.strings` files matching both languages:

```bash
find . -path "*/<base_language>.lproj/Localizable.strings" -not -path "*/.build/*"
find . -path "*/<compare_language>.lproj/Localizable.strings" -not -path "*/.build/*"
```

Exclude `.build/` and other derived/vendor directories so you only audit source files.

If multiple files are found per language (e.g. across multiple modules), audit each
pair separately and label results by module path. If no file is found for the compare
language, stop and tell the user.

## Step 2 — Parse both files

iOS `.strings` files use this format:

```
"key" = "value";
/* optional comment */
```

Parse each file into a `key → value` lookup using this Python snippet:

```bash
python3 -c "
import re, json, sys
text = open(sys.argv[1]).read()
pairs = re.findall(r'\"((?:[^\\\\\"]|\\\\.)+)\"\s*=\s*\"((?:[^\\\\\"]|\\\\.)*)\"\s*;', text)
print(json.dumps(dict(pairs), ensure_ascii=False))
" path/to/Localizable.strings
```

Run both files in parallel. This gives you:

```
base:    { key → base_value }
compare: { key → compare_value }
```

## Step 3 — Analyse every string

Work through all checks below. Think about what each key represents in the UI — a
button label, a body message, a toast, a section header — and whether the translation
fits that context and register.

### Severity 1 — Clear bugs (must fix)

**Format specifier mismatches**
Compare format specifiers in base vs. compare (`%1$@`, `%2$d`, `%@`, `%d`, etc.).
Flag if the count differs, if the types differ, or if they appear in a different order.
These cause crashes or garbled output at runtime.

**Untranslated strings**
Flag if `compare_value == base_value`. Exceptions: emoji-only strings, brand names,
technical terms that are intentionally identical by convention (e.g. "Debug", "–",
single-word proper nouns). Use judgement — "OK" being the same is fine; a full sentence
being identical is not.

**Trailing or leading whitespace**
Flag any compare value with leading or trailing whitespace that the base value does not
have.

**Duplicate translations for different keys**
Group compare keys by their translated value. If two *different* base strings share the
exact same compare translation, flag it — one was likely copy-pasted incorrectly.
Exception: very short shared strings ("OK", "–", single emoji) are expected to collide.

**Missing keys**
Flag any key present in base but absent from compare.

### Severity 2 — Grammar & consistency

**Inconsistent terminology**
Find all keys where the same concept appears in the base (e.g. "save", "delete",
"cancel", "item", "settings") and verify the compare language uses the same term
consistently throughout. A concept phrased three different ways across the app is
confusing even if each individual translation is acceptable.

**Grammar errors**
Check for case agreement, missing or wrong punctuation (commas before subordinate
clauses, sentence-final periods where the base has them), wrong article forms, wrong
inflections. Be specific: cite the exact error and the corrected form.

**Action/toast alignment**
Menu actions and their corresponding success toasts should use parallel terminology.
E.g. if the menu says "X aufheben", the confirmation toast should say "X aufgehoben",
not a different verb. Scan for these pairs across the file.

**Imperative vs. indicative consistency**
Helper/description texts (subtitles, footers, setting helpers) should consistently use
either imperative or indicative — not mix both within the same UI surface.

### Severity 3 — Style & naturalness

**Awkward phrasing**
Flag translations that are grammatically correct but read unnaturally — overly literal,
clunky word order, unusual register for a mobile app. Suggest a more natural alternative.

**UI anti-patterns**
Flag patterns that look wrong in a UI context: parenthetical plural forms like "(n)",
double pronouns (e.g. "uns, uns"), parenthetical notes that belong in prose but not
in a button label or section header.

**Length concerns**
Flag cases where the compare translation is dramatically longer than the base in a
context where length matters (button labels, menu items, short toasts). These can
cause truncation on device.

## Step 4 — Present the report

Group findings by severity. For each issue show:

| Key | Base text | Compare text | Issue | Suggested fix |
|-----|-----------|--------------|-------|---------------|

Use these section headers:
- `### 🔴 Clear bugs` — format mismatches, untranslated strings, whitespace, duplicates, missing keys
- `### 🟡 Grammar & consistency` — terminology, grammar, alignment, imperative/indicative
- `### 🔵 Style & naturalness` — phrasing, anti-patterns, length

If a severity level has no issues, write "✅ None found."

End the report with a one-sentence overall quality summary.

**Do not make any changes.** After presenting, ask the user which issues they want to fix.

## Step 5 — Wait

Stop after the report. The user will tell you which issues to fix.

When given permission, apply fixes by editing the compare `.strings` file directly
using the Edit tool. Then, if the project has a build script like `buildStrings` or
`swiftgen`, run it once to regenerate string accessors.
