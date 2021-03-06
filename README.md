# Macrostrat database backup service

Macrostrat's database backup service enables on-demand and periodic backups of
PostgreSQL databases to local directories and remote S3 buckets. The service
is designed to be run in a standalone Docker container, and is typically configured
with environment variables.

It is based on [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)
and [Rclone](https://rclone.org) and was initially created as
a built-in backup service for the [Sparrow](https://sparrow-data.org) data system.

Local backup to a directory and/or backup to a remote S3 bucket
are supported, depending on which environment variables are set.

By default, the image runs the `backup-service` command for periodic backups. A
`backup-db` command that runs a one-off backup is also provided;
this can be run using
```
docker run pg-backup-service backup-db
```
with the appropriate environment variables.

Backups are named using an optional prefix, the database name, a 10-character file hash, and a timestamp, as such:
```
$DB_BACKUP_PREFIX/$dbname-5e753082e5-2021-11-01T20:51:55.pg-dump
```

## Prior art and useful links

- [Sparrow](https://sparrow-data.org)
- [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)
- [Rclone](https://rclone.org)
- [`postgres-backup-s3`](https://github.com/schickling/dockerfiles/tree/master/postgres-backup-s3)

This project is useful for low-intensity applications, but for
larger-scale systems, using an incremental/streaming backup system like [Barman](https://pgbarman.org/) or [PGBackRest](https://pgbackrest.org/) is recommended.

# Usage

## Environment variables

The application is configured with environment variables, allowing easy integration into Docker-centric workflows.
### Database connection

#### `DB_NAME` or `PGDATABASE` (**Required**)
The name of the database to back up to (`DB_NAME` takes precedence)
With `DB_NAME`, a comma-separated string can be provided to back up multiple databases.

Other common [PostgreSQL connection variables](https://www.postgresql.org/docs/current/libpq-envars.html)
are also supported, such as:

- `PGHOST` (default: `localhost`)
- `PGPORT` (default: `5432`)
- `PGUSER` (default: `postgres`)
- `PGPASSWORD` (no default)

### Cloud backup

This service is primarily designed to support backup to an S3-compatible storage bucket. S3 buckets are provided
by most storage providers including many university IT systems. Macrostrat's backup services are typically used with
[`s3.drive.wisc.edu`](https://s3.drive.wisc.edu).

- `S3_ENDPOINT`: the S3 endpoint (**Required** for cloud backup)
- `S3_ACCESS_KEY`: the S3 access key (**Required** for cloud backup)
- `S3_SECRET_KEY`: the S3 secret key (**Required** for cloud backup)
- `S3_BACKUP_BUCKET`: the S3 bucket (**Required** for cloud backup)

### Local backup

- `DB_BACKUP_DIR`: the directory to back up to (**Required** for local backup).

In order to back up the database outside of the docker container, you will need to mount this directory on the host
machine:
```
docker run \
  --env DB_BACKUP_DIR=/db-backups \
  --volume /local-backups:/db-backups \
  pg-backup-service
```

### Scheduling backups

Backups are scheduled using the go-cron library; the schedule
is set by the `SCHEDULE` environment variable. Schedules can be
set to a crontab-style format, or more appealingly, a simple format: `@daily`, `@hourly`, `@weekly`, `@every 100s` etc.
See the [`go-cron` documentation](https://pkg.go.dev/github.com/robfig/cron?utm_source=godoc#hdr-Predefined_schedules) for more information. 

By default, no schedule is applied, and a single backup is
performed on startup.

### Miscellaneous

- `DB_BACKUP_PREFIX`: A prefix for database backups. If provided, all backups will be put within
  a specific namespace or folder. This is useful for sharing a bucket between many different database backup jobs.
- `DB_BACKUP_MAX_N`: the maximum number of backups to keep (default: `10`)
- `PGDUMP_OPTIONS`: additional options to pass to `pg_dump` for all backup jobs.

## Further customization

If more customization of the backup process beyond `$PGDUMP_OPTIONS` is desired, any `dump-$dbname` or `dump-database` 
commands added to the container's `PATH` will override the normal `pg_dump -Fc` command.
These have a signature `dump-database <dbname> <out-dir>` and must output only the filename of the dump file created.
See [`bin/defs.bash`](bin/defs.bash#L14) for more details.

## Restoring backups

The backup service creates custom-format PostgreSQL dump files.
These can be restored with a command like
```
pg_restore -d $DB_NAME "$backup_file_name"
```
A built-in restore command may be provided in a future
version of this image.

## Integrating into an application

This container can be easily included in `docker compose`
container stacks.

```yaml
services:
  db_server:
    image: postgis:13-3.1
    ...
  db_backup:
    image: ghcr.io/macrostrat/pg-backup-service:main
    environment:
      # Back up every weekend
      - SCHEDULE=@weekly
      - PGHOST=db_server
      - PGPASSWORD=<your-password>
      - DB_BACKUP_PREFIX=strata-v1
      # Can set multiple databases for backup!!
      - DB_NAME=strata-main,strata-dev
      # S3 configuration parameters
      - S3_ENDPOINT=s3.drive.wisc.edu
      - S3_ACCESS_KEY
      - S3_SECRET_KEY
      - S3_BACKUP_BUCKET=database-backups
```
# Contributing

Basic backup functionality is fully tested. Tests can be run locally using `make test`.
All pull requests and commits to the `main` branch
are automatically tested, and updates to the Docker image are automatically pushed to the Github container registry.
Any contributions should add appropriate tests and documentation.

## Future possibilities

- A built-in command to restore from a backup (possibly with an interactive prompt).
- Possibly shift to Python from shell scripts.
