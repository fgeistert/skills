#!/bin/zsh
# Adds a string to Texterify and rebuilds local string files.
# Usage: add-string.sh "<key>" "<english_translation>"

set -e

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a git repository." >&2
  exit 1
}
cd "$PROJECT_ROOT"

KEY="$1"
TRANSLATION="$2"

if [[ -z "$KEY" || -z "$TRANSLATION" ]]; then
  echo "Usage: add-string.sh <key> <english_translation>" >&2
  exit 1
fi

if ! command -v texterify &>/dev/null; then
  echo "Error: texterify CLI not found." >&2
  echo "Install it with: brew install texterify/texterify/texterify" >&2
  echo "Then authenticate with: texterify login" >&2
  exit 1
fi

if [[ ! -x "./buildStrings" ]]; then
  echo "Error: ./buildStrings script not found or not executable in project root ($PROJECT_ROOT)." >&2
  echo "Create a buildStrings script that exports from Texterify and regenerates your string accessor files." >&2
  echo "Example:" >&2
  echo "  #!/bin/zsh" >&2
  echo "  texterify export" >&2
  echo "  swiftgen" >&2
  echo "Make it executable with: chmod +x buildStrings" >&2
  exit 1
fi

echo "Adding string to Texterify: $KEY = \"$TRANSLATION\""
texterify add "$KEY" "$TRANSLATION"

echo "Rebuilding local string files..."
./buildStrings
