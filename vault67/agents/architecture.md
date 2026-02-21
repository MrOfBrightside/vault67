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

## Skip dirs
# Directories to exclude from repo structure scan (noise).
node_modules, vendor, __pycache__, .git, dist, build, .next, .nuxt, target, .tox, .mypy_cache, .pytest_cache, coverage, .cache

## Language detection
# Format: marker-file: language | package-manager
# Agent checks repo root for each marker. All matches are reported.
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
- Dockerfile: Docker | docker
- docker-compose.yml: Docker | docker-compose
- Makefile: Make | make

## Stop words
# Words to exclude when matching Gherkin keywords to filenames.
given, when, then, that, this, from, with, have, does, should, will, the, and, for, are, not, its, has, can, all, but, into, been, being, each, also, than, they, only, user, data, test
