function check-vars() {
  # Check whether an environment variable exists
  reason="$1"
  shift
  var_names=("$@")
  var_unset=""
  for var_name in "${var_names[@]}"; do
    [ -z "${!var_name}" ] && echo "$var_name is required $reason." && var_unset=true
  done
  [ -n "$var_unset" ] && return 1
  return 0
}

function run-backup() {
  # The core function to back up a database
  dbname="$1"
  dirname="$2"
  >&2 echo "Backing up $dbname to $dirname"
  mkdir -p "$dirname"

  dumpfile="/tmp/dumpfile.db-dump"
  if command -v "dump-$dbname" &> /dev/null ; then
    >&2 echo "Found a provided 'dump-$dbname' command"
    >&2 dump-$dbname "$dbname" "$dumpfile"
  elif command -v dump-database &> /dev/null ; then
    >&2 echo "Found a provided 'dump-database' command"
    >&2 dump-database "$dbname" "$dumpfile"
  else
    if [ -z $PGDUMP_OPTIONS ]; then
      >&2 echo "No 'dump-$dbname' or 'dump-database' command found, using pg_dump -Fc"
      >&2 pg_dump -Fc "$dbname" > "$dumpfile"
    else
      >&2 echo "No 'dump-$dbname' or 'dump-database' command found, using pg_dump -Fc with options $PGDUMP_OPTIONS"
      >&2 pg_dump -Fc $PGDUMP_OPTIONS "$dbname" > "$dumpfile"
    fi
  fi

  if [ ! -f "$dumpfile" ]; then
    >&2 echo "Failed to create dumpfile"
    exit 1
  fi

  hash=$(md5sum $dumpfile | head -c 10)
  now="$(date +%Y-%m-%dT%H:%M:%S)"
  outfile="$dirname/${dbname}-${hash}-${now}.pg-dump"

  >&2 mv $dumpfile $outfile
  >&2 echo "Created $outfile"
  echo "$outfile"
}
