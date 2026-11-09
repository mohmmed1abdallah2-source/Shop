# Iteration 01 — Architecture

## Layered design
```mermaid
flowchart TB
 UI[Flutter Presentation] --> UC[Application Use Cases]
 UC --> DOM[Domain Ports]
 API[Dart Shelf API] --> UC
 PG[PostgreSQL Adapter] -.implements.-> DOM
 AUTH[Firebase Token Verifier] -.implements.-> SEC[Auth Port]
 UI --> CACHE[SQLite or browser cache] --> QUEUE[Sync Queue] --> API
```

## PostgreSQL ERD
```mermaid
erDiagram
 BRANCHES ||--o{ USERS : contains
 ROLES ||--o{ USERS : assigns
 ROLES ||--o{ ROLE_PERMISSIONS : grants
 USERS ||--o{ DEVICES : owns
 BRANCHES ||--o{ PRODUCTS : scopes
 PRODUCT_CATEGORIES ||--o{ PRODUCTS : groups
 PRODUCTS ||--o{ PRODUCT_UNITS_BARCODES : sells_as
 BRANCHES ||--o{ IDEMPOTENCY_KEYS : scopes
 USERS ||--o{ AUDIT_LOGS : acts
```

## Request sequence
```mermaid
sequenceDiagram
 participant Client
 participant Queue as Local Queue
 participant API
 participant Firebase
 participant DB as PostgreSQL
 Client->>Queue: Save locally
 Queue-->>Client: Pending status
 Client->>API: POST + Bearer + Idempotency-Key
 API->>Firebase: Verify token signature and claims
 Firebase-->>API: Verified UID
 API->>DB: Atomic idempotency and product transaction
 DB-->>API: Persisted product
 API-->>Client: Standard response envelope
 Client->>Queue: Mark synced
```

## Hosting
Flutter Web on Firebase Hosting; Dart API on an HTTPS container host; PostgreSQL on Supabase or Neon. Secrets belong in host secret managers. Production CORS must use explicit origins. Android and Windows share the same API.

## Boundaries
Presentation calls use cases only. Application depends on domain ports. Infrastructure implements ports. Firebase token verification is fail-closed. Idempotency reservation and product writes share a transaction. Browser builds must not invoke sqflite or dart:io.

## Scope limits
This iteration establishes authentication/catalog foundation, not POS, purchasing, stock valuation or full accounting.

## Acceptance
- [ ] Dart analyze and tests
- [ ] Flutter analyze, widget tests, APK and Web builds
- [ ] PostgreSQL migration on clean database
- [ ] Firebase emulator verification
- [ ] Two-client retry/idempotency test
