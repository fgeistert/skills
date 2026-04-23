# skills

Reusable agent skills for iOS development.

Compatible with [Claude Code](https://claude.ai/code), [OpenAI Codex](https://developers.openai.com/codex), [Cursor](https://cursor.com), and [other agents](https://skills.sh) that support the open [Agent Skills](https://agentskills.io) standard.

## Install

### Via skills CLI (recommended)

```sh
npx skills add fgeistert/skills
```

### Claude Code (plugin marketplace)

```sh
/plugin marketplace add fgeistert/skills
/plugin install add-string-texterify@skills
```

## Skills

| Skill | What it covers |
|-------|---------------|
| [add-string-texterify](skills/add-string-texterify/) | Add a new localized string to an iOS project via the Texterify CLI |

## Structure

Each skill follows the open [Agent Skills](https://agentskills.io) standard:

```
skills/
  skill-name/
    SKILL.md       # Required — instructions and metadata
    README.md      # Human-readable documentation
    scripts/       # Optional — helper scripts
```

## License

[MIT](LICENSE)
