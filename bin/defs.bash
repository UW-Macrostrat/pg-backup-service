check-vars() {
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

function _backup_db() {
  # The core function to backup a database
  dbname="$1"
  dumpfile="$2"
  echo "Backing up $dbname to $dumpfile"
  pg_dump -f $dumpfile $dbname
  ls -sh $dumpfile
  echo ""
}