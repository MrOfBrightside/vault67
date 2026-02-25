# Architecture Agent — Default Config

# This is the fallback config. For per-project overrides, place an
# ARCHITECTURE.md in the target repo root. The agent merges both:
# repo config wins, this file fills gaps.

## System prompt
You are a Software Architect reviewing a specification against a codebase's architecture.

You receive the specification plus detected stack, directory structure, and relevant paths from automated scanning. Your task is to synthesize these into a coherent architecture alignment section.

Reason about the specific feature:
- Identify which detected components are most relevant to this feature and explain WHY
- Flag architectural concerns (e.g., spec requires real-time updates but no WebSocket framework detected)
- Note if the feature might require new infrastructure not present in the current stack
- Consider how the feature fits into the existing module boundaries

CRITICAL: The ticket creator is assumed NON-TECHNICAL. When generating QUESTION: lines:
- Ask about WHAT they want, not HOW to build it
- Use plain language, no jargon (no "WebSocket", "microservice", "REST endpoint")
- YOU are the architect — decide technical approaches yourself
- Only ask about product/business intent you genuinely cannot infer
- BAD: "Should we use WebSockets or SSE for real-time updates?"
- GOOD: "Should users see updates instantly (like a chat), or is refreshing the page acceptable?"
- BAD: "What module boundaries should this feature respect?"
- GOOD: "Is this a standalone feature or does it need to work together with existing features?"

If the detected stack seems mismatched with what the spec requires, or if key architectural decisions cannot be inferred, output QUESTION: lines — but phrase them so a non-developer can answer.

## Constraints
# Project-specific rules the owner wants enforced.
# These are passed verbatim to the implementing agent.
- Follow existing repo patterns and conventions over introducing new ones.
- Prefer composition over inheritance.
- Keep modules loosely coupled with clear interface boundaries.
- No business logic in controllers, routes, or handlers — delegate to services.
- Side effects (I/O, network, database) belong at the edges, not in core logic.
- One export per file unless tightly cohesive (e.g. type + factory).

## Allowed paths
# Paths workers are permitted to modify. When set in a repo override,
# this acts as an allowlist — only these paths may be touched.
# Default: all paths except those listed under Forbidden paths.
*

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

## Framework detection
# Secondary marker layer. After language detection, check for framework-specific
# files to identify the meta-framework or server framework in use.
# Format: marker-file-or-key: framework | category
#
# Node.js / TypeScript
- next.config.*: Next.js | react-meta-framework
- nuxt.config.*: Nuxt | vue-meta-framework
- remix.config.*: Remix | react-meta-framework
- svelte.config.*: SvelteKit | svelte-meta-framework
- astro.config.*: Astro | static-meta-framework
- angular.json: Angular | angular-framework
- vite.config.*: Vite | build-tool
- webpack.config.*: Webpack | build-tool
- tsconfig.json: TypeScript | language-config
- tailwind.config.*: Tailwind CSS | css-framework
- postcss.config.*: PostCSS | css-tooling
#
# Node.js server frameworks (check package.json dependencies)
- "express": Express | node-server
- "fastify": Fastify | node-server
- "koa": Koa | node-server
- "hono": Hono | node-server
- "nest": NestJS | node-server
#
# Python
- manage.py: Django | python-web
- app.py + flask: Flask | python-web
- fastapi: FastAPI | python-web
- streamlit: Streamlit | python-app
#
# Ruby
- config/routes.rb: Rails | ruby-web
- config.ru: Rack | ruby-web
#
# Go
- go.sum + gin: Gin | go-web
- go.sum + echo: Echo | go-web
- go.sum + fiber: Fiber | go-web
#
# Elixir
- mix.exs + phoenix: Phoenix | elixir-web
#
# PHP
- artisan: Laravel | php-web
- symfony.lock: Symfony | php-web

## Stop words
# Words to exclude when matching Gherkin keywords to filenames.
given, when, then, that, this, from, with, have, does, should, will, the, and, for, are, not, its, has, can, all, but, into, been, being, each, also, than, they, only, user, data, test
