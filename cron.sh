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

function matching_ksk()
{
	[ $# = 2 ] || return 1

	local ZONE=$1
	local TIMESTAMP=$2
	local FILE
	local k

	for k in "$DNSSEC_KEY_DIR"/K$ZONE*.key; do
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

function matching_zsk()
{
	[ $# = 2 ] || return 1

	local ZONE=$1
	local TIMESTAMP=$2
	local FILE
	local k

	for k in "$DNSSEC_KEY_DIR"/K$ZONE*.key; do
		FILE=$(cat $k)
		if [[ ! "$FILE" =~ zone-signing.*Activate:\ *([0-9]{14}).*Inactive:\ ([0-9]{14}) ]]; then
			continue
		fi

		local ACTIVATE=${BASH_REMATCH[1]}
		local INACTIVE=${BASH_REMATCH[2]}
		if [ $TIMESTAMP -lt $ACTIVATE -o $TIMESTAMP -gt $INACTIVE ]; then
			continue
		fi

		echo Matching ZSK: ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} $k
		return 0
	done
	return 1
}


function current_ksk()
{
	[ $# = 1 ] || return 1

	local ZONE=$1

	# KSK - 6 months

	if ! matching_ksk $ZONE $YEAR$MONTH$DAY$H$M$S; then
		echo Need to backdate a KSK
		echo Now: $YEAR $MONTH
		local M2
		local Y2
		if [ $MONTH -le $KSK_MONTH1 ]; then
			M2=$KSK_MONTH2
			Y2=$((YEAR-1))
		else
			M2=$KSK_MONTH1
			Y2=$YEAR
		fi
		echo Gen KSK for: $ZONE $Y2 $M2
		generate-ksk $ZONE $Y2 $M2
	else
		echo We can use an existing KSK for zone $ZONE
	fi

	if [ $MONTH$DAY = "${KSK_MONTH1}${SWAP_DAY}" -o $MONTH$DAY = "${KSK_MONTH2}${SWAP_DAY}" ]; then
		echo Time for a new KSK
		generate-ksk $ZONE $YEAR $((MONTH+1))
	fi
}

function current_zsk()
{
	[ $# = 1 ] || return 1

	local ZONE=$1

	# ZSK - 1 month

	if ! matching_zsk $ZONE $YEAR$MONTH$DAY$H$M$S; then
		echo Need to backdate a ZSK
		echo Gen ZSK for: $ZONE $YEAR $MONTH
		generate-zsk $ZONE $YEAR $MONTH
	else
		echo We can use an existing ZSK for zone $ZONE
	fi

	if [ $DAY = "$SWAP_DAY" ]; then
		echo Time for a new ZSK
		generate-zsk $ZONE $YEAR $((MONTH+1))
	fi
}


function daily_prep()
{
	generate-dns-glue
	generate-root-certs
	generate-ssh-fingerprint
	generate-tlsa

	update-serials
}

function daily_signing()
{
	[ $# = 1 ] || return 1

	local ZONE=$1

	rm -f $ZONE.db.signed
	sign-zone $ZONE
}

function daily_tidy()
{
	delete-old-keys
	fix-perms
	set-to-publish-date "$DNSSEC_KEY_DIR"/*
}


# ----------------------------------------------------------

X=${1:-$(date "+%Y%m%d%H%M%S")}

if [[ ! "$X" =~ ^[0-9]{14}$ ]]; then
	echo "Invalid date: $X"
	exit 1
fi

YEAR=${X:0:4}
MONTH=${X:4:2}
DAY=${X:6:2}
H=${X:8:2}
M=${X:10:2}
S=${X:12:2}

echo "Cron: for $YEAR-$MONTH-$DAY $H:$M:$S"

daily_prep

for d in $DNSSEC_DOMAINS; do
	current_ksk $d
	current_zsk $d
	daily_signing $d
done

daily_tidy
echo
show-keys
show-signed

# ds-sync.pl
# reload named

