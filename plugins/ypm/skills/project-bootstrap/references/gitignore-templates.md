# .gitignore Templates by Language

Always include `.serena` in any project's .gitignore (required for development projects using Serena MCP).

## Common (all projects)

```gitignore
# Serena MCP
.serena

# Editor
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.*
!.env.example
```

## Node.js / TypeScript

```gitignore
node_modules/
dist/
build/
coverage/
*.tsbuildinfo
.next/
.nuxt/
.output/
```

## Python

```gitignore
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
dist/
build/
.eggs/
venv/
.venv/
*.egg
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
```

## Rust

```gitignore
target/
Cargo.lock  # Only for libraries; keep for binaries
```

## Go

```gitignore
bin/
vendor/
*.exe
*.test
*.out
```

## Java / Kotlin

```gitignore
*.class
*.jar
*.war
*.ear
build/
.gradle/
out/
```

## Ruby

```gitignore
*.gem
*.rbc
/.config
/coverage/
/InstalledFiles
/pkg/
/spec/reports/
/tmp/
vendor/bundle
```

## Usage

Combine the **Common** section with the relevant language section(s) for the project. Add any framework-specific patterns as needed.
