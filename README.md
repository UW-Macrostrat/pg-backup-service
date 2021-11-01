Macrostrat's database backup service enables on-demand and periodic backups of
PostgreSQL databases to local directories and remote S3 buckets. The service
is designed to be run in a standalone Docker container, and is thus configured
with environment variables.

It is based on [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)
and [Rclone](https://rclone.org) and was initially created as
a built-in backup service for the [Sparrow](https://sparrow-data.org) data system.

Local backup to a directory and/or backup to a remote S3 bucket
are supported, depending on which environment variables are set.

By default, the image runs the `backup-service` command. A
`backup-db` command that runs a one-off backup is also provided;
this can be run using
```
docker run pg-backup-service backup-db
```
with the appropriate environment variables.

## Environment variables
### Database connection

- `DB_NAME`: The name of the database to back up (**Required**).

Other common [PostgreSQL connection variables](https://www.postgresql.org/docs/current/libpq-envars.html)
are also supported, such as:

- `PGHOST` (default: `localhost`)
- `PGPORT` (default: `5432`)
- `PGUSER` (default: `postgres`)
- `PGPASSWORD` (no default)

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

### Cloud backup

- `S3_ENDPOINT`: the S3 endpoint (**Required** for cloud backup)
- `S3_ACCESS_KEY`: the S3 access key (**Required** for cloud backup)
- `S3_SECRET_KEY`: the S3 secret key (**Required** for cloud backup)
- `S3_BACKUP_BUCKET`: the S3 bucket to back up to (**Required** for cloud backup)

### Miscellaneous

- `DB_BACKUP_PREFIX`: Prefix for database backups. If provided, the prefix will be prepended to the database name and a date string.
- `DB_BACKUP_MAX_N`: the maximum number of backups to keep (default: `10`)
- `DB_BACKUP_INTERVAL`: the interval in seconds between database backups (default: `604800`, or 1 week)

## Restoring a backup

The backup service creates custom-format PostgreSQL dump files.
These can be restored with a command like
```
pg_restore -d $DB_NAME "$backup_file_name"
```
A built-in restore command may be provided in a future
version of this image.


## Limitations

- Currently you can only back up a single database at a time.
- There is no allowance for backups scheduled at specific
  times of the day.

## Future possibilities

- A built-in command to restore from a backup (possibly with an interactive prompt).
- A schema-only restoration option.
- Option to back up multiple databases at a time
- Option to omit certain tables from the backup
- Possibly shift to Python from shell scripts.
