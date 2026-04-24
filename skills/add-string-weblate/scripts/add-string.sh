#!/bin/zsh
set -e

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a git repository." >&2
  exit 1
}
cd "$PROJECT_ROOT"

KEY="$1"
ENGLISH="$2"
shift 2

if [[ -z "$KEY" || -z "$ENGLISH" ]]; then
  echo "Usage: add-string.sh <key> <english_translation> [lang:translation ...]" >&2
  echo "  e.g. add-string.sh common_save \"Save\" de:\"Speichern\" fr:\"Enregistrer\"" >&2
  exit 1
fi

if ! command -v wlc &>/dev/null; then
  echo "Error: wlc CLI not found. Install with: pip install wlc" >&2
  exit 1
fi

if [[ ! -f ".weblate" ]]; then
  echo "Error: .weblate config file not found in project root ($PROJECT_ROOT)." >&2
  exit 1
fi

COMPONENT=$(awk -F'=' '/^translation *=/{gsub(/ /,"",$2); print $2}' .weblate)

echo "Adding string to Weblate: $KEY = \"$ENGLISH\""

python3 - "$KEY" "$ENGLISH" "$COMPONENT" "$@" <<'PYEOF'
import urllib.request, json, sys

key = sys.argv[1]
english = sys.argv[2]
component = sys.argv[3]
translations = {}
for arg in sys.argv[4:]:
    lang, _, text = arg.partition(":")
    translations[lang.strip()] = text.strip()

config_path = f"{__import__('os').path.expanduser('~')}/.config/weblate"
token = None
api_url = None
try:
    in_keys = False
    with open(config_path) as f:
        for line in f:
            line = line.strip()
            if line == "[keys]":
                in_keys = True
            elif line.startswith("["):
                in_keys = False
            elif in_keys and "=" in line:
                token = line.split("=", 1)[1].strip()
            elif line.startswith("url") and "=" in line and not in_keys:
                api_url = line.split("=", 1)[1].strip().rstrip("/")
except Exception as e:
    print(f"Error reading wlc config: {e}", file=sys.stderr)
    sys.exit(1)

if not token or not api_url:
    print("Error: could not read Weblate URL or token from ~/.config/weblate", file=sys.stderr)
    sys.exit(1)

project, comp = component.split("/")

def api(path, method="GET", body=None):
    url = f"{api_url}/{path.lstrip('/')}"
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Token {token}")
    if data:
        req.add_header("Content-Type", "application/json")
    try:
        return json.loads(urllib.request.urlopen(req).read())
    except urllib.error.HTTPError as e:
        body_txt = e.read().decode()
        print(f"API error {e.code} on {method} {url}: {body_txt}", file=sys.stderr)
        sys.exit(1)

# Add English source unit
result = api(f"translations/{project}/{comp}/en/units/", "POST", {"key": key, "value": [english]})
print(f"  source added (id: {result.get('id', '?')})")

# Patch target language units
for lang, text in translations.items():
    units = api(f"translations/{project}/{comp}/{lang}/units/?q=key:{key}")
    if not units["results"]:
        print(f"  warning: no unit found for lang={lang}, key={key}", file=sys.stderr)
        continue
    unit_id = units["results"][0]["id"]
    api(f"units/{unit_id}/", "PATCH", {"target": [text], "state": 20})
    print(f"  {lang}: \"{text}\"")
PYEOF
