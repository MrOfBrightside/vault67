# Engineering Principles Agent Rules

## Principle categories
# Categories to evaluate for each ticket. Agent generates specific guidance per category.
# Format: category: description
- code_quality: Code quality guardrails specific to implementation
- performance: Performance considerations
- error_handling: Error handling requirements
- observability: Logging/observability needs
- edge_cases: Edge cases to handle
- anti_patterns: Anti-patterns to avoid
- integration: Integration points to be careful with
- data_validation: Data validation rules
- backward_compatibility: Backward compatibility considerations

## DoD addition categories
# Extra Definition of Done items to consider. Agent selects relevant ones.
# Format: category: description
- verification: Extra verification steps
- tests: Specific tests that must pass
- documentation: Documentation that must be updated
- performance_benchmarks: Performance benchmarks
- security_checks: Security checks to complete
- migration: Migration steps
- rollback: Rollback considerations

## Output rules
# Rules for generating principles
- Each principle: 1-2 sentences, specific to the ticket
- Reference actual components/patterns from spec
- Skip if not applicable (simple tickets need fewer principles)
- Focus on risks: what could go wrong, what mistakes are easy to make

## Language-specific principles
# Format: language-marker: principle
# Applied when the detected stack matches
- package.json: Prefer TypeScript strict mode; avoid any type; use ESM imports
- pyproject.toml: Use type hints on public APIs; prefer dataclasses/pydantic for data objects
- Cargo.toml: Handle all Result/Option values explicitly; avoid unwrap() in production code
- go.mod: Check all returned errors; use structured logging (slog); avoid goroutine leaks
- Gemfile: Follow Rails conventions; use strong parameters; avoid N+1 queries
- composer.json: Use strict types declaration; follow PSR-12; use dependency injection
- mix.exs: Use pattern matching over conditionals; leverage supervision trees for fault tolerance
