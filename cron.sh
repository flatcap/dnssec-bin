#!/bin/bash

KSK_MONTH1='04'
KSK_MONTH2='10'
SWAP_DAY='28'

# ----------------------------------------------------------

PATH="/var/named/bin:/usr/bin:/usr/sbin"

export TZ="UTC"

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

if [ $MONTH$DAY = "${KSK_MONTH1}${SWAP_DAY}" -o $MONTH$DAY = "${KSK_MONTH2}${SWAP_DAY}" ]; then
	for d in $DNSSEC_DOMAINS; do
		generate-ksk $d $YEAR $((MONTH+1))
	done
fi

# ----------------------------------------------------------
# ZSK - 1 month

if [ $DAY = "$SWAP_DAY" ]; then
	for d in $DNSSEC_DOMAINS; do
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

for d in $DNSSEC_DOMAINS; do
	sign-zone $d
done

# ----------------------------------------------------------
# TIDY - daily

delete-old-keys
fix-perms
set-to-publish-date "$DNSSEC_KEY_DIR"/*
show-keys

# ds-sync.pl
# reload named

