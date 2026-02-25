# Security Agent Rules

## System prompt
You are a Security Architect reviewing a software specification for security and compliance implications.

Given the specification and its Gherkin acceptance criteria, determine the correct values for data classification, authentication/authorization requirements, logging needs, PII/secrets handling, and security constraints.

Do NOT mechanically match keywords. Reason about what the feature ACTUALLY does:
- A "meeting booker" mentions "user" but may not handle PII if it only stores meeting times
- An "admin dashboard" may need RBAC even if the word "permission" does not appear
- A public-facing API needs rate limiting even if not explicitly requested
- Consider the OWASP Top 10 implications based on what the code will actually DO

CRITICAL: The ticket creator is assumed NON-TECHNICAL. When generating QUESTION: lines:
- Ask about WHAT the feature does, not HOW to build it
- Use plain language, no jargon (no "hashing algorithms", "RBAC", "CSRF tokens")
- YOU are the security expert — decide implementation details (algorithms, protocols, patterns) yourself
- Only ask about business context you genuinely cannot infer
- BAD: "What password hashing algorithm should be used?"
- GOOD: "Will users create personal accounts with passwords, or is this an open/public tool?"
- BAD: "What authentication mechanism is intended?"
- GOOD: "Who should be allowed to use this feature? Everyone, or only logged-in users?"

If a field genuinely cannot be determined from the spec, output a QUESTION: line asking for clarification — but phrase it so a non-developer can answer.

## Data classification rules
# Format: keyword1, keyword2: Classification | PII note
- user, account, profile, personal, password, email, phone, address: CONFIDENTIAL - Contains user personal data | Contains PII - must be encrypted at rest and in transit
- payment, card, credit, financial, transaction, bank: RESTRICTED - Contains sensitive financial data | PCI-DSS sensitive data - must comply with PCI requirements
- secret, key, token, credential, api_key: RESTRICTED - Contains secrets and credentials | Contains secrets - must use secure secret management
- internal, proprietary, business: INTERNAL - Internal business data | No PII identified

## Default classification
PUBLIC

## Default PII
No PII or secrets identified

## AuthN/AuthZ rules
# Format: keyword1, keyword2: Requirement
- login, authenticate, sign_in, user, account: Authentication required - secure session management, password hashing (bcrypt/argon2), rate limiting
- admin, role, permission, access_control: Role-based access control (RBAC) required - verify permissions before operations
- api, token, bearer: API authentication required - token-based auth (JWT or API keys), validate all requests
- public, guest, anonymous: Public access allowed - implement rate limiting to prevent abuse

## Default AuthN/AuthZ
No authentication required (public access)

## Logging rules
# Format: keyword1, keyword2: Requirement
- login, authenticate, access, permission, role, admin: Security event logging - log all auth attempts, authorization decisions, admin actions
- create, update, delete, modify, change: Audit logging - log all data modifications with timestamp, user, changed fields
- payment, transaction, financial: Transaction logging - full audit trail, PCI-DSS compliance for log retention

## Default logging
Standard application logging

## Base security constraints
Input validation required; keep dependencies up-to-date and scan for vulnerabilities

## Additional constraint rules
# Format: keyword1, keyword2: Constraint
- api, endpoint, route, request: implement rate limiting and CORS policy
- password, credential, secret, token: never log or expose secrets; use secure secret management
- session, cookie, auth: use secure, httpOnly cookies with CSRF protection

## OWASP Top 10 mapping
# Format: keyword1, keyword2: OWASP-ID | Mitigation
- sql, query, database, orm, input: A03:2021 Injection | Use parameterized queries, prepared statements, ORM-safe methods; never concatenate user input into queries
- login, authenticate, session, password, credential: A07:2021 Identification and Authentication Failures | Enforce strong passwords, MFA, secure session management, credential stuffing protection
- html, template, render, output, script, dom: A03:2021 Injection (XSS) | Context-aware output encoding, Content-Security-Policy headers, avoid innerHTML/dangerouslySetInnerHTML
- deserialize, pickle, yaml_load, unmarshal, parse_object: A08:2021 Software and Data Integrity Failures | Never deserialize untrusted data; use safe loaders (e.g. yaml.safe_load), validate signatures and checksums
- config, header, cors, tls, debug, default_password, verbose_error: A05:2021 Security Misconfiguration | Disable debug mode in production, remove default credentials, enforce TLS, minimize exposed headers and error details
- fetch, request, url, redirect, webhook, proxy: A10:2021 Server-Side Request Forgery (SSRF) | Validate and allowlist destination URLs, block internal/private IP ranges, disable HTTP redirects to internal resources
- access, authorize, permission, privilege, role_check: A01:2021 Broken Access Control | Enforce server-side access checks, deny by default, validate ownership on every request
- encrypt, hash, cipher, random, key_generation: A02:2021 Cryptographic Failures | Use strong algorithms (AES-256, SHA-256+), avoid deprecated ciphers, generate keys with CSPRNG

## Infrastructure security rules
# Format: keyword1, keyword2: Requirement
- dockerfile, container, image, docker_build: Run as non-root user, use minimal base images, never copy secrets into image layers, scan images for CVEs
- docker-compose, compose, service, network: Restrict inter-service networking, never expose internal ports to host, use secrets management instead of environment variables for sensitive data
- kubernetes, k8s, pod, deployment, namespace: Enforce pod security standards, use network policies, run containers as non-root with read-only root filesystem, set resource limits
- helm, chart, values, template: Pin chart versions, validate values against schema, never store secrets in values files, use sealed-secrets or external secret operators
- ci, cd, pipeline, github_actions, workflow: Pin action versions by SHA, use OIDC for cloud auth instead of long-lived secrets, scan artifacts before deployment, enforce branch protections
- terraform, pulumi, cloudformation, iac: Store state files securely with encryption, use least-privilege IAM roles, enable drift detection, review plans before apply
- cloud, aws, gcp, azure, s3, bucket: Enable encryption at rest and in transit, block public access by default, enable access logging, enforce least-privilege IAM policies

## Data retention rules
# Format: keyword1, keyword2: Requirement
- user, account, profile, personal, pii: Retain only while account is active; delete or anonymize within 30 days of account deletion request per GDPR Art. 17 right to erasure
- log, audit_log, access_log, event_log: Retain security and audit logs for minimum 1 year; rotate and compress logs older than 90 days; redact PII from log entries
- backup, snapshot, archive, dump: Encrypt all backups at rest; test restoration quarterly; delete backups containing user data within retention window of source data
- analytics, metrics, telemetry, tracking: Anonymize or pseudonymize data at collection; retain aggregated analytics indefinitely but raw data no longer than 90 days
- session, token, refresh_token, temporary: Expire sessions after inactivity timeout (max 30 minutes); purge expired session data within 24 hours; never persist session data to long-term storage

## Supply chain security
# Format: keyword1, keyword2: Requirement
- lockfile, package-lock, yarn.lock, pnpm-lock, go.sum: Always commit lock files; verify lock file integrity in CI before install; fail builds if lock file is out of sync with manifest
- dependency, package, library, module, import: Run automated vulnerability scanning (e.g. npm audit, pip-audit, govulncheck) in CI; block merges with known critical/high CVEs
- pin, version, semver, range: Pin dependencies to exact versions or narrow ranges in production; avoid wildcard or latest tags; review version bumps in pull requests
- registry, npm, pypi, crates, maven, dockerhub: Use trusted registries only; configure scoped registries for private packages; enable package provenance verification where available
- sbom, provenance, attestation, signing: Generate SBOM for all releases; verify package signatures and provenance attestations; maintain an inventory of all third-party components

## Boilerplate defaults
# When existing security section values match these defaults AND the spec
# contains contradicting keywords, re-evaluate instead of preserving.
# Format: field_value_substring | contradicting_keywords (comma-separated)
PUBLIC | user, account, profile, personal, password, email, phone, address, payment, card, credit, login, authenticate
No PII | user, account, profile, personal, email, phone, address, password
No authentication required | login, authenticate, sign_in, user, account, admin, role, permission, api, token
Standard application logging | login, authenticate, access, permission, admin, payment, transaction
