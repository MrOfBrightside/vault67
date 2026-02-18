# Architecture Agent — Default Config

# This is the fallback config. For per-project overrides, place an
# ARCHITECTURE.md in the target repo root. The agent merges both:
# repo config wins, this file fills gaps.

## Constraints
# Project-specific rules the owner wants enforced.
# These are passed verbatim to the implementing agent.

## Forbidden paths
# Paths workers must never modify.
.git/, node_modules/, .env, secrets.*, vendor/, __pycache__/, dist/, build/

## Language detection
# Format: marker-file: language | package-manager
- package.json: Node.js/TypeScript | npm/yarn/pnpm
- pyproject.toml: Python | pip/poetry
- setup.py: Python | pip
- Cargo.toml: Rust | cargo
- go.mod: Go | go
- Gemfile: Ruby | bundler
- pom.xml: Java | maven
- build.gradle: Java/Kotlin | gradle
- composer.json: PHP | composer
- mix.exs: Elixir | mix
- Package.swift: Swift | spm
- *.csproj: C#/.NET | dotnet
