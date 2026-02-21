# Lead Developer Agent Rules

## Monolith detection
# If a single file exceeds this line count, flag it
- threshold: 500

## Module patterns
# Format: language-marker: pattern | description
- package.json: feature-modules | Group by feature (src/feature-name/{component,service,types})
- pyproject.toml: package-modules | Python packages with __init__.py (src/package/module.py)
- setup.py: package-modules | Python packages with __init__.py (src/package/module.py)
- Cargo.toml: mod-files | Rust modules (src/module_name/mod.rs or src/module_name.rs)
- go.mod: package-dirs | Go packages by directory (internal/, pkg/, cmd/)
- Makefile: directory-based | Organize by function (src/, lib/, bin/, tests/)
- Gemfile: rails-conventions | Rails conventions (app/models, app/controllers, app/services)
- pom.xml: maven-layout | Maven standard (src/main/java, src/test/java, package per domain)
- build.gradle: maven-layout | Gradle/Maven standard layout

## File naming
# Format: language-marker: convention | example
- package.json: kebab-case | user-profile.ts, api-client.ts
- pyproject.toml: snake_case | user_profile.py, api_client.py
- setup.py: snake_case | user_profile.py, api_client.py
- Cargo.toml: snake_case | user_profile.rs, api_client.rs
- go.mod: snake_case | user_profile.go, api_client.go
- Gemfile: snake_case | user_profile.rb, api_client.rb

## Import rules
# Format: language-marker: rule
- package.json: Use path aliases (@/), prefer named exports, no circular imports
- pyproject.toml: Use absolute imports from package root, no star imports
- setup.py: Use absolute imports from package root, no star imports
- Cargo.toml: Use pub(crate) for internal APIs, minimize pub surface
- go.mod: Import by package path, keep internal/ for private packages

## Max file length
# Format: language-marker: lines
- package.json: 300
- pyproject.toml: 400
- Cargo.toml: 500
- go.mod: 500
- Makefile: 300
