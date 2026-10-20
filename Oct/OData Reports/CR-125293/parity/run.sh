#!/bin/bash
f="$(cygpath -w "$(realpath "$1")")"
cd /c/Hadaf_Work; set -a; . ./.env.local 2>/dev/null; set +a
SQLCMDPASSWORD="$ACCFLEX_DB_PASSWORD" sqlcmd -S db-all -U "$ACCFLEX_DB_USER" -d UNP-Ali -l 30 -W -s'|' -f 65001 -i "$f"
