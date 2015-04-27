#!/bin/bash

KSK_MONTH1='06'
KSK_MONTH2='12'
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

X=${1:-$(date "+%Y%m%d%H%M%S")}

if [[ ! "$X" =~ ^[0-9]{14}$ ]]; then
	echo "Invalid argument: $X"
	exit 1
fi

YEAR=${X:0:4}
MONTH=${X:4:2}
DAY=${X:6:2}
H=${X:8:2}
M=${X:10:2}
S=${X:12:2}

echo "Cron: for $YEAR-$MONTH-$DAY $H:$M:$S"

function matching_ksk
{
	[ $# = 1 ] || return 1

	local TIMESTAMP=$1
	local FILE
	local k

	for k in "$DNSSEC_KEY_DIR"/*.key; do
		FILE=$(cat $k)
		if [[ ! "$FILE" =~ key-signing.*Activate:\ *([0-9]{14}).*Inactive:\ ([0-9]{14}) ]]; then
			continue
		fi

		local ACTIVATE=${BASH_REMATCH[1]}
		local INACTIVE=${BASH_REMATCH[2]}
		if [ $TIMESTAMP -lt $ACTIVATE -o $TIMESTAMP -gt $INACTIVE ]; then
			continue
		fi

		echo Matching KSK: ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} $k
		return 0
	done
	return 1
}


if ! matching_ksk $YEAR$MONTH$DAY$H$M$S; then
	echo no match
	echo Need to backdate a KSK
	echo Now: $YEAR $MONTH
	if [ $MONTH -lt $KSK_MONTH1 ]; then
		M2=$KSK_MONTH2
		Y2=$((YEAR-1))
	else
		M2=$KSK_MONTH1
		Y2=$YEAR
	fi
	echo Gen KSK for: $Y2 $M2
	generate-ksk russon.org $Y2 $M2
	exit 0
else
	echo match
fi

exit 0

# ----------------------------------------------------------
# KSK - 6 months

if [ $MONTH$DAY = "${KSK_MONTH1}${SWAP_DAY}" -o $MONTH$DAY = "${KSK_MONTH2}${SWAP_DAY}" ]; then
	echo Time for a new KSK
	for d in $DNSSEC_DOMAINS; do
		generate-ksk $d $YEAR $((MONTH+1))
	done
fi

# ----------------------------------------------------------
# ZSK - 1 month

if [ $DAY = "$SWAP_DAY" ]; then
	echo Time for a new ZSK
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

