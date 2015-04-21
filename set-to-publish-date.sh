#!/bin/bash

shopt -s nullglob

for f in "$@"; do
	FILE_DATE=$(awk '/Publish/{ print $3 ? $3 : $2 }' $f)
	if [ -z "$f" ]; then
		echo Ignoring: $f
		continue
	fi

	touch -d "${FILE_DATE:0:8}" "$f"
done

