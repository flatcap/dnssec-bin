#!/bin/bash

shopt -s nullglob

DATE_NOW=$(date +%Y%m%d%H%M%S)

for f in "$@"; do
	FILE_DATE=$(awk '/Delete/{ print $3 ? $3 : $2 }' $f)
	if [ -z "$f" ]; then
		echo Ignoring: $f
		continue
	fi

	if [ $DATE_NOW -gt $FILE_DATE ]; then
		echo Delete: $f
		# rm -f "$f"
	else
		echo Safe: $f
	fi
done

