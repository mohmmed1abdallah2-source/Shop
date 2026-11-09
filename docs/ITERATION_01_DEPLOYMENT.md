# Iteration 01 — Deployment and local setup

## Server environment
Set these variables in the API host secret/configuration panel:
- `DATABASE_URL`: PostgreSQL connection URL with TLS enabled.
- `FIREBASE_PROJECT_ID`: Firebase project ID used as the ID-token audience and issuer.
- `CORS_ALLOWED_ORIGINS`: comma-separated exact origins, for example `https://shop.example.com,https://<project>.web.app`. Do not use `*` in production.
- `PORT`: optional HTTP port; defaults to `8080`.

The server fails closed if `FIREBASE_PROJECT_ID` is missing. Catalog access fails closed without PostgreSQL-backed role permissions.

## Database initialization
Apply migrations in order:
1. `server/migrations/20261108_001_init_auth_and_catalog.sql`
2. `server/migrations/20261108_002_seed_catalog_permissions.sql`

Create a branch and assign a Firebase UID to a provisioned user. Example (replace values):

```sql
INSERT INTO branches(name, code) VALUES ('الفرع الرئيسي', 'MAIN') RETURNING id;
INSERT INTO users(branch_id, role_id, firebase_uid, display_name)
SELECT '<BRANCH_UUID>', r.id, '<FIREBASE_UID>', 'مدير المتجر'
FROM roles r WHERE r.name = 'owner';
```

The Firebase UID must be obtained from the authenticated Firebase user. Never place passwords or service-account private keys in this repository.

## Flutter configuration
Use Flutter stable with Dart SDK 3.12 or newer. The Windows SQLite adapter uses `sqflite_common_ffi` 2.4.x with SQLite 3 native assets and stores its database under the Windows application-support directory. Use the same Firebase project for client sign-in and server verification:

```sh
flutter create --platforms=android,web,windows --project-name shop_app .
flutter pub get
flutter run --dart-define=FIREBASE_API_KEY=<WEB_API_KEY> --dart-define=API_BASE_URL=https://<API_HOST>
```

For release builds pass the same defines:

```sh
flutter build apk --release --dart-define=FIREBASE_API_KEY=<WEB_API_KEY> --dart-define=API_BASE_URL=https://<API_HOST>
flutter build web --release --dart-define=FIREBASE_API_KEY=<WEB_API_KEY> --dart-define=API_BASE_URL=https://<API_HOST>
flutter build windows --release --dart-define=FIREBASE_API_KEY=<WEB_API_KEY> --dart-define=API_BASE_URL=https://<API_HOST>
```

Firebase Email/Password sign-in must be enabled in Firebase Authentication. The client stores the refresh token using platform secure storage. The server verifies ID-token signatures against Google's rotating Secure Token certificates.

## CI outputs
The pull-request workflow generates platform runner scaffolding and publishes three artifacts when all jobs pass: Android release APK, Flutter Web bundle and Windows release directory. Workflow results must be inspected before treating any artifact as successful.

## Free-tier hosting plan
- Firebase Hosting: Flutter Web static bundle.
- Supabase or Neon: managed PostgreSQL.
- API container host: a provider with HTTPS, environment secrets and persistent process support (for example Cloud Run).
- Keep database access restricted to the API host; mobile/web clients must never connect directly to PostgreSQL.
