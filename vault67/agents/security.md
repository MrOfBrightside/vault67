# Security Agent Rules

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
