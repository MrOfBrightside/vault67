# Test Strategy Agent Rules

## Default commands
- Golden build command: docker compose build
- Golden test command: docker compose run --rm app pytest

## Language-specific commands
# Format: keyword: build_command | test_command
- pyproject.toml: pip install -e . | pytest
- setup.py: pip install -e . | pytest
- package.json: npm run build | npm test
- Cargo.toml: cargo build | cargo test
- go.mod: go build ./... | go test ./...
- Makefile: make | make test
- pom.xml: mvn compile | mvn test
- build.gradle: ./gradlew build | ./gradlew test
- Gemfile: bundle install | bundle exec rspec
- Dockerfile: docker compose build | docker compose run --rm app pytest

## Test layers
# Note: e2e layer requires frontend presence (React/Vue/Angular/Svelte or frontend/ dir).
# If no frontend detected, e2e keywords are downgraded to integration.
# Format: keyword: layer | framework | description
- api,endpoint,route,REST,GraphQL: integration | httpx/supertest | Test API endpoints with request/response validation
- login,auth,session,JWT,OAuth: integration | httpx/supertest | Test auth flows end-to-end
- database,query,model,migration,ORM: integration | testcontainers/fixtures | Test data layer with real DB
- UI,page,form,button,dashboard,click,display,render: e2e | Playwright | Write browser tests, open pages, click through flows
- component,widget,card,modal: unit | vitest/jest + testing-library | Render component in isolation, assert DOM
- calculate,parse,transform,validate,convert,format: unit | pytest/jest/go-test | Pure function tests, edge cases
- CLI,command,flag,argument: integration | subprocess/exec | Invoke CLI commands, verify stdout/stderr/exit codes
- email,notification,webhook,event: integration | mock-server | Test external service interactions with mocks
- file,upload,download,export,import: integration | tmp-fixtures | Test file I/O with temp directories

## Default test layer
unit | pytest/jest | Test business logic functions in isolation

## Quality gates
- All tests pass (zero failures)
- No new lint warnings (`eslint`/`ruff`/`clippy` depending on stack)
- Type check passes (`tsc --noEmit`/`mypy`/`pyright` if applicable)
- Test coverage does not decrease (report but don't block)
- No hardcoded secrets or credentials in test code

## UI testing rules
# When Gherkin mentions UI elements (page, form, button, dashboard, click, display, render)
- Framework: Playwright (preferred) or Cypress
- Write one spec file per Feature
- Each Scenario becomes a test case
- Use page object pattern for reusable selectors
- Test in headless mode for CI, headed for local dev
- Screenshot on failure

## Framework mapping
# Format: language-marker: unit-framework | integration-framework | e2e-framework | lint-cmd | typecheck-cmd
- package.json: jest/vitest | supertest | Playwright | eslint . | tsc --noEmit
- pyproject.toml: pytest | httpx/pytest | Playwright | ruff check . | mypy .
- setup.py: pytest | httpx/pytest | Playwright | ruff check . | mypy .
- Cargo.toml: cargo-test | cargo-test | - | cargo clippy | (built-in)
- go.mod: go-test | go-test | - | golangci-lint run | (built-in)
- Gemfile: rspec | rspec-rails | Capybara | rubocop | sorbet
