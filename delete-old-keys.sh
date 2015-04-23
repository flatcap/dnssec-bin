#!/bin/bash

PATH="/var/named/bin:/usr/bin:/usr/sbin"

set -o errexit	# set -e
set -o nounset	# set -u

shopt -s nullglob

renice --priority 19 --pid $$ > /dev/null
ionice --class 3     --pid $$ > /dev/null

cd /var/named

KEYDIR="keys"

[ -d "$KEYDIR" ] || exit 0

FILES="$(find $KEYDIR -type f)"

DATE_NOW=$(date "+%Y%m%d%H%M%S")
for f in $FILES; do
	EXPIRY=$(awk '/Delete/{ print $3 ? $3 : $2 }' $f)
	if [ -z "$EXPIRY" ]; then
		echo Ignore: $f
		continue
	fi

	if [ $DATE_NOW -gt $EXPIRY ]; then
		echo Delete: $f
		rm -f "$f"
	else
		echo Safe: $f
	fi
done

