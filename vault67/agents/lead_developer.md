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
- composer.json: psr4-autoload | PSR-4 autoloading (src/Domain/Entity.php, src/Service/Handler.php)
- mix.exs: contexts | Phoenix contexts pattern (lib/app/accounts, lib/app/catalog)
- Package.swift: module-based | Swift modules (Sources/ModuleName/, Tests/ModuleNameTests/)
- "*.csproj": namespace-based | .NET namespaces (src/Domain/, src/Application/, src/Infrastructure/)

## File naming
# Format: language-marker: convention | example
- package.json: kebab-case | user-profile.ts, api-client.ts
- pyproject.toml: snake_case | user_profile.py, api_client.py
- setup.py: snake_case | user_profile.py, api_client.py
- Cargo.toml: snake_case | user_profile.rs, api_client.rs
- go.mod: snake_case | user_profile.go, api_client.go
- Gemfile: snake_case | user_profile.rb, api_client.rb
- pom.xml: PascalCase | UserProfile.java, ApiClient.java
- build.gradle: PascalCase | UserProfile.java, ApiClient.java
- composer.json: PascalCase | UserProfile.php, ApiClient.php
- mix.exs: snake_case | user_profile.ex, api_client.ex
- Package.swift: PascalCase | UserProfile.swift, ApiClient.swift
- "*.csproj": PascalCase | UserProfile.cs, ApiClient.cs

## Import rules
# Format: language-marker: rule
- package.json: Use path aliases (@/), prefer named exports, no circular imports
- pyproject.toml: Use absolute imports from package root, no star imports
- setup.py: Use absolute imports from package root, no star imports
- Cargo.toml: Use pub(crate) for internal APIs, minimize pub surface
- go.mod: Import by package path, keep internal/ for private packages
- Gemfile: Use explicit require, avoid require_all in production code
- pom.xml: Use package imports, no wildcard imports, organize by domain
- build.gradle: Use package imports, no wildcard imports, organize by domain
- composer.json: Use use statements with full namespace, follow PSR-4 mapping
- mix.exs: Use alias/import/use at module top, prefer alias over import for readability
- Package.swift: Use import for modules, access control via internal/public/private
- "*.csproj": Use using statements, organize by namespace, avoid global usings unless shared

## Max file length
# Format: language-marker: lines
- package.json: 300
- pyproject.toml: 400
- Cargo.toml: 500
- go.mod: 500
- Makefile: 300
- Gemfile: 300
- pom.xml: 400
- build.gradle: 400
- composer.json: 400
- mix.exs: 300
- Package.swift: 400
- "*.csproj": 400

## Error handling
# Format: language-marker: convention
- package.json: Prefer async/await with try/catch, use typed error classes, never swallow errors silently
- pyproject.toml: Use specific exception types, avoid bare except, use contextlib for resource cleanup
- setup.py: Use specific exception types, avoid bare except, use contextlib for resource cleanup
- Cargo.toml: Use Result<T, E> and the ? operator, define domain error enums, avoid unwrap in library code
- go.mod: Return (value, error) tuples, wrap errors with fmt.Errorf %w, check errors immediately
- Gemfile: Use specific rescue clauses, avoid rescue Exception, use ensure for cleanup
- pom.xml: Use checked exceptions for recoverable errors, unchecked for programming errors, never catch Throwable
- build.gradle: Use checked exceptions for recoverable errors, unchecked for programming errors, never catch Throwable
- composer.json: Use SPL exception classes, throw domain-specific exceptions, use try/catch/finally
- mix.exs: Use {:ok, value}/{:error, reason} tuples, reserve raise/rescue for truly exceptional cases, use with for chained matches
- Package.swift: Use throws/try/catch, define Error-conforming enums, prefer Result type for async operations
- "*.csproj": Use specific exception types, avoid catching System.Exception broadly, use finally for cleanup
- Makefile: Use set -e in shell recipes, check command exit codes, use || for fallback handling
