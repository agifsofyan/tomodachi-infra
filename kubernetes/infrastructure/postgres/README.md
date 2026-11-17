
# PostgreSQL Infrastructure

PostgreSQL 17 for Tomodachi microservices.

## Architecture

- Namespace: tomodachi
- StatefulSet: postgres
- Database: tomodachi_db
- Application role: tomodachi_app
- Service: postgres
- Port: 5432
- Storage: local-path PVC, 5Gi

## Internal connection

postgres.tomodachi.svc.cluster.local:5432

## Database

- Database: tomodachi_db
- Schema: public
- Role: tomodachi_app

## Deployment

Managed by ArgoCD Application `postgres`.

## Secret

Credentials are managed using Sealed Secrets.

Never commit plaintext database credentials.

## Storage warning

The PVC uses local-path storage.

Deleting the PVC may permanently delete database data.

Always create and verify backups before destructive operations.

## Backup

Use pg_dump to create logical backups.

Store backups outside the PostgreSQL PVC and preferably outside the VPS.
