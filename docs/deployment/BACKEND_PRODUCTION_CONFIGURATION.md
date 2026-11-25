# Backend production configuration contract

This is a local readiness aid, not a deployment recipe. No AWS architecture,
resource identifier, hostname, certificate, or credential has been selected.
Do not use the development Compose file or this incomplete environment template
as a production deployment by itself.

## Production-only application behavior

Set `APP_ENV=production` explicitly. The backend then:

- Fails before database startup if required database, CA, Redis, JWT, or SMTP
  configuration is missing or invalid. Errors name variables only; values are
  not included.
- Requires PostgreSQL `verify-full` TLS and a readable `DB_SSLROOTCERT` file.
- Requires Redis authentication and TLS and refuses to start if the shared
  Redis session store is unavailable; it does not fall back to process memory.
  If Redis fails at runtime, session revocation checks and logout fail closed
  with HTTP 503 rather than silently accepting or ignoring revocations.
- Requires a JWT signing key of at least 32 bytes. There is no separate session
  signing key: refresh tokens are random and stored by hash in Redis.
- Uses only exact HTTPS values in `CORS_ALLOWED_ORIGINS`. An empty list denies
  browser requests that carry an `Origin` header; native mobile requests without
  that header continue to work. The approved web origin is not known yet.
- Requires SMTP host, port, and sender identity; SMTP username/password must be
  supplied together. STARTTLS is mandatory in production.
- Skips GORM `AutoMigrate` and verifies that the expected tables already exist.
  The repository has no versioned migration runner, so an approved migration
  process is a deployment prerequisite.
- Exposes `/api/health` as process liveness and `/api/ready` as database and
  Redis dependency readiness. Neither endpoint proves that an external AWS
  deployment or full schema migration has succeeded.
- Does not register Swagger in production.

The development and staging behavior is kept as-is: development Compose still
uses its local environment, migration-on-startup, wildcard CORS, and optional
in-memory session fallback.

## Environment template

[`docker/.env.production.example`](../../docker/.env.production.example) lists
the production variable names and secure transport requirements without
containing real values. It is intentionally incomplete and must not be used as
a Compose `--env-file`. Provide values using the deployment platform's protected
configuration mechanism. The CA file must be mounted/readable at the configured
path inside the backend runtime.

The development [`docker/.env`](../../docker/.env) is local-only and ignored by
Git. Its permission was restricted to owner read/write (`0600`); its content
was not changed.

## Deployment blockers and owner decisions

- Choose and document the AWS topology (for example EC2 or ECS, and whether the
  database/cache are managed services) before adding production Compose or
  reverse-proxy configuration.
- Keep backend ingress private to the selected TLS-terminating proxy/load
  balancer; the application listener is HTTP on port 8080 and binds all
  container interfaces.
- Supply the approved API/web origins, database hostname and trusted CA file,
  Redis endpoint/auth credentials, SMTP provider, secret-manager mapping, and
  health-check wiring.
- Provide a versioned migration process and a tested backup/restore procedure
  before production startup. The current `/api/ready` check is not a migration
  or backup verification.
- Review access-token and refresh-token lifetimes; their current fallbacks are
  24 hours and 7 days.
- The seeder is restricted to `APP_ENV=development` and requires both
  `SEED_ALLOW_DESTRUCTIVE=true` and `SEED_TARGET_DISPOSABLE=true`, plus explicit
  database connection settings. Hostname or database name alone do not qualify
  a target as disposable. The development Compose service sets `APP_ENV` but
  does not enable either destructive opt-in. The seeder permits unencrypted
  database transport only in development; production and other modes are
  rejected before a database connection is attempted.
- Only set the disposable declaration after independently confirming that the
  configured database is a disposable fixture. Never run the seeder against
  production or a persistent/shared development database.
- Review image tag pinning, resource limits, logging/monitoring, and network
  policy in the selected AWS architecture.

No AWS, production endpoint, database, container, migration, or deployment
operation was performed for this configuration work.
