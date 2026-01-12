# YPM Language Strategy

**Last Updated**: 2026-01-10

This document explains YPM's bilingual strategy and how the three-level language configuration system works together.

---

## Overview

YPM is an **English-first international open-source project** with a strategic bilingual approach:

- **Public-facing**: English (README, guides, commands, CLAUDE.md)
- **Internal development**: Japanese (design docs, research notes)

This strategy balances **international accessibility** with **design precision**.

---

## Philosophy: "English for Reach, Japanese for Depth"

### English for Reach

**Why English for public docs?**

1. **International accessibility**: Contributors worldwide can participate
2. **Claude Code compatibility**: Avoids UTF-8/CJK character crashes
3. **Better AI understanding**: Claude's English training is more extensive
4. **Industry standard**: Most OSS projects use English

### Japanese for Depth

**Why Japanese for internal docs?**

1. **Design precision**: Complex architectural discussions benefit from native language
2. **Development efficiency**: Core team works faster in Japanese
3. **Nuanced communication**: Subtle technical decisions easier to express
4. **Knowledge preservation**: Deep technical context retained accurately

This is a **strategic choice**, not a limitation. The `language` setting in Claude Code 2.1.0+ enables dynamic translation, allowing contributors to work in their preferred language.

---

## Three-Level Language Configuration

YPM implements three independent language settings that work together:

### 1. Claude Code Response Language

**Purpose**: Controls what language Claude uses when responding

**Location**: `.claude/settings.json` (user setting, not in repository)

**Example**:
```json
{
  "language": "japanese"
}
```

**Scope**: All Claude responses in the session

**Feature**: Available since Claude Code 2.1.0+ (January 2026)

### 2. YPM Command Output Language

**Purpose**: Controls the language of YPM-generated content

**Location**: `~/.ypm/config.yml`

**Example**:
```yaml
settings:
  language: ja  # or en
```

**Mechanism**: When set to non-English, Claude dynamically translates output

**Affects**: PROJECT_STATUS.md, command outputs, status messages

### 3. Documentation Language

**Purpose**: Language of instructions to Claude and user-facing docs

**YPM Strategy**:
- **Public docs**: English (README.md, guide-en.md, CLAUDE.md, commands/\*.md)
- **Internal dev docs**: Japanese (docs/development/\*, docs/research/\*)

**Rationale**: See "English for Reach, Japanese for Depth" above

---

## How They Work Together

### Example: Japanese Developer Workflow

A Japanese developer can work with:

```
.claude/settings.json:  "language": "japanese"  → Claude responds in Japanese
~/.ypm/config.yml:      language: ja            → YPM outputs in Japanese
CLAUDE.md:              Written in English      → Instructions for Claude
```

**Result**:
- Claude reads English instructions (better understanding)
- Claude responds in Japanese (natural communication)
- YPM outputs in Japanese (localized content)

### Why English CLAUDE.md with Japanese Responses?

This combination is **recommended** by the Japanese Claude Code community:

1. **Avoids crashes**: UTF-8/CJK characters cause Rust panics (known bug in some Claude Code versions)
   - Error: `byte index X is not a char boundary`

2. **Better performance**: Claude's English training is more comprehensive

3. **Guaranteed responses**: `language` setting ensures Japanese output

4. **Community consensus**: Multiple developers confirm this as best practice

---

## File Organization

### English Files (Public)

```
ypm/
├── README.md              # Project overview
├── CLAUDE.md              # Claude Code instructions
├── config.example.yml     # Configuration template
├── docs/
│   ├── guide-en.md       # Primary user guide
│   └── LANGUAGE_STRATEGY.md  # This document
└── commands/
    └── *.md              # All command files
```

### Japanese Files (Internal)

```
ypm/
└── docs/
    ├── INDEX.md          # Documentation index
    ├── guide-ja.md       # Deprecated Japanese guide
    ├── development/      # Internal design docs
    │   ├── architecture.md
    │   ├── onboarding-script-spec.md
    │   ├── ypm-open-spec.md
    │   └── global-export-system.md
    └── research/         # Research notes
        ├── claude-md-loading-guarantee.md
        └── private-to-public-strategy.md
```

---

## Contributor Guidelines

### Contributing to YPM

1. **Public contributions**: Use English
   - README updates
   - Command development
   - User-facing documentation
   - GitHub issues/PRs (title in English, body can be Japanese)

2. **Internal contributions**: Japanese is acceptable
   - Design documents (docs/development/)
   - Research notes (docs/research/)
   - Inline code comments (prefer English, but Japanese OK)

3. **Git conventions**:
   - Branch names: Always English (`feature/add-export-command`)
   - Commit messages: English title, Japanese body OK
   - PR titles: English
   - PR descriptions: Bilingual acceptable

### Working with the Language System

If you're a Japanese developer:

1. **Set your Claude Code language**:
   ```json
   // .claude/settings.json (create if not exists)
   {
     "language": "japanese"
   }
   ```

2. **Set YPM output language**:
   ```yaml
   # ~/.ypm/config.yml
   settings:
     language: ja
   ```

3. **Read English CLAUDE.md**: Claude will understand it better and respond in Japanese

4. **Write internal docs in Japanese**: For detailed design discussions

---

## Why This Strategy Works

### Technical Benefits

1. **Stability**: Avoids UTF-8 crashes in Claude Code
2. **Performance**: Leverages Claude's optimal training data
3. **Maintainability**: Clear separation between public and internal docs

### Community Benefits

1. **Inclusivity**: International contributors can participate
2. **Efficiency**: Core team works in native language for complex design
3. **Flexibility**: Contributors choose their preferred language via settings

### Long-term Benefits

1. **Scalability**: Easy to add more languages (e.g., Chinese, Korean)
2. **Documentation quality**: Each language serves its purpose optimally
3. **Knowledge transfer**: Complex designs preserved accurately in Japanese

---

## Migration Path

### From Old YPM (Japanese-first)

The previous YPM iteration was Japanese-first. This new version:

1. **Preserves Japanese docs**: Internal design docs remain Japanese
2. **Adds English interface**: Public docs now in English
3. **Maintains compatibility**: Japanese users can configure for Japanese output
4. **Improves stability**: Avoids crashes from CJK characters

### Future Enhancements

Potential additions:

1. **More languages**: Chinese, Korean, etc. via dynamic translation
2. **Localized guides**: guide-zh.md, guide-ko.md, etc.
3. **Translation validation**: Automated checks for translation quality
4. **Community translations**: Crowdsourced documentation translations

---

## Related Documentation

- [CLAUDE.md](../CLAUDE.md): Project instructions for Claude Code
- [guide-en.md](guide-en.md): User guide with language configuration details
- [config.example.yml](../config.example.yml): Configuration template with language settings

---

## Questions?

If you have questions about the language strategy:

1. **For users**: See [guide-en.md](guide-en.md) Language Settings section
2. **For contributors**: Open a GitHub Discussion
3. **For design decisions**: Reference this document

---

**This strategy enables YPM to be both globally accessible and locally optimized.**
