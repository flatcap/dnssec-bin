#!/bin/bash

DOMAINS="russon.org flatcap.org"
KEYDIR="keys"

PATH="/var/named/bin:/usr/bin:/usr/sbin"

export TZ=UTC

set -o errexit	# set -e
set -o nounset	# set -u

shopt -s nullglob

renice --priority 19 --pid $$ > /dev/null
ionice --class 3     --pid $$ > /dev/null

cd /var/named

# ----------------------------------------------------------

X=$(date "+%Y%m%d")

YEAR=${X:0:4}
MONTH=${X:4:2}
DAY=${X:6}

echo "Cron: for $YEAR-$MONTH-$DAY"

# ----------------------------------------------------------
# KSK - 6 months
# April 28th, October 28th

if [ $MONTH$DAY = '0428' -o $MONTH$DAY = '1028' ]; then
	for d in $DOMAINS; do
		generate-ksk $d $YEAR $((MONTH+1))
	done
fi

# ----------------------------------------------------------
# ZSK - 1 month
# 28th of each month

if [ $DAY = '28' ]; then
	for d in $DOMAINS; do
		generate-zsk $d $YEAR $((MONTH+1))
	done
fi

# ----------------------------------------------------------
# SIGNING - daily

generate-dns-glue
generate-root-certs
generate-ssh-fingerprint
generate-tlsa

update-serials

for d in $DOMAINS; do
	sign-zone $d
done

# ----------------------------------------------------------
# TIDY - daily

delete-old-keys
fix-perms
set-to-publish-date "$KEYDIR"/*
show-keys

# ds-sync.pl
# reload named

