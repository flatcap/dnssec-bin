#!/bin/bash

KSK_MONTH1='06'
KSK_MONTH2='12'
SWAP_DAY='28'
export DNSSEC_DOMAINS="russon.org"

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

function month_plus()
{
	[ $# = 2 ] || return

	local M=$(( ( (10#$1-1)+(10#$2) ) %12 + 1))
	printf "%02d" $M
}


function matching_ksk()
{
	[ $# = 2 ] || return 1

	local ZONE=$1
	local TIMESTAMP=$2
	local FILE
	local k
	local RESULT=1

	for k in "$DNSSEC_KEY_DIR"/K$ZONE*.key; do
		FILE=$(cat $k)
		if [[ ! "$FILE" =~ key-signing.*Activate:\ *([0-9]{14}).*Inactive:\ ([0-9]{14}) ]]; then
			# log bad file
			continue
		fi

		local ACTIVATE=${BASH_REMATCH[1]}
		local INACTIVE=${BASH_REMATCH[2]}
		if [ $TIMESTAMP -lt $ACTIVATE -o $TIMESTAMP -gt $INACTIVE ]; then
			continue
		fi

		echo -e "\t\e[1;33mExisting KSK: $k ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}\e[0m"
		RESULT=0
	done
	return $RESULT
}

function matching_zsk()
{
	[ $# = 2 ] || return 1

	local ZONE=$1
	local TIMESTAMP=$2
	local FILE
	local k
	local RESULT=1

	for k in "$DNSSEC_KEY_DIR"/K$ZONE*.key; do
		FILE=$(cat $k)
		if [[ ! "$FILE" =~ zone-signing.*Activate:\ *([0-9]{14}).*Inactive:\ ([0-9]{14}) ]]; then
			# log bad file
			continue
		fi

		local ACTIVATE=${BASH_REMATCH[1]}
		local INACTIVE=${BASH_REMATCH[2]}
		if [ $TIMESTAMP -lt $ACTIVATE -o $TIMESTAMP -gt $INACTIVE ]; then
			continue
		fi

		echo -e "\t\e[1;33mExisting ZSK: $k ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}\e[0m"
		RESULT=0
	done
	return $RESULT
}


function current_ksk()
{
	[ $# = 1 ] || return 1

	local ZONE=$1

	# KSK - 6 months

	echo -e "\e[1;32mGenerate KSK for $ZONE\e[0m"
	if ! matching_ksk $ZONE $YEAR$MONTH$DAY$H$M$S; then
		local M2
		local Y2
		if [ $MONTH -lt $KSK_MONTH1 ]; then
			M2=$KSK_MONTH2
			Y2=$((YEAR-1))
		elif [ $MONTH -lt $KSK_MONTH2 ]; then
			M2=$KSK_MONTH1
			Y2=$YEAR
		else
			M2=$KSK_MONTH2
			Y2=$YEAR
		fi
		echo Need to backdate a KSK: $ZONE $Y2 $M2
		generate-ksk $ZONE $Y2 $M2
		show-keys
		matching_ksk $ZONE $YEAR$MONTH$DAY$H$M$S
	fi

	local K1=$(month_plus $KSK_MONTH1 11)
	local K2=$(month_plus $KSK_MONTH2 11)

	REGEX=$(printf "(%02d|%02d)%02d" $K1 $K2 $SWAP_DAY)
	if [[ $MONTH$DAY =~ $REGEX ]]; then
		local M2=$(month_plus $MONTH 1)
		local Y2=$YEAR
		[ $MONTH = 12 ] && Y2=$((Y2+1))
		echo Time for a new KSK: $ZONE $Y2 $M2
		generate-ksk $ZONE $Y2 $M2
		show-keys
	fi
}

function current_zsk()
{
	[ $# = 1 ] || return 1

	local ZONE=$1

	# ZSK - 1 month

	echo -e "\e[1;32mGenerate ZSK for $ZONE\e[0m"
	if ! matching_zsk $ZONE $YEAR$MONTH$DAY$H$M$S; then
		echo Need to backdate a ZSK: $ZONE $YEAR $MONTH
		generate-zsk $ZONE $YEAR $MONTH
		show-keys
		matching_zsk $ZONE $YEAR$MONTH$DAY$H$M$S
	fi

	if [ $DAY = "$SWAP_DAY" ]; then
		local M2=$(month_plus $MONTH 1)
		local Y2=$YEAR
		[ $MONTH = 12 ] && Y2=$((Y2+1))
		echo Time for a new ZSK: $ZONE $Y2 $M2
		generate-zsk $ZONE $Y2 $M2
		show-keys
	fi
}


function daily_prep()
{
	generate-dns-glue
	generate-root-certs
	generate-ssh-fingerprint
}

function daily_signing()
{
	[ $# = 1 ] || return 1

	local ZONE=$1

	generate-tlsa $ZONE
	update-serials -d $YEAR$MONTH$DAY $ZONE.db
	# date $MONTH$DAY$H$M$YEAR.$S
	sign-zone $ZONE $YEAR$MONTH$DAY$H$M$S
	# hwclock --hctosys
}

function daily_tidy()
{
	delete-old-keys $TIMESTAMP
	fix-perms
	set-to-publish-date "$DNSSEC_KEY_DIR"/*
}


# ----------------------------------------------------------

TIMESTAMP=${1:-$(date "+%Y%m%d%H%M%S")}

if [[ "$TIMESTAMP" =~ ^[0-9]{8}$ ]]; then
	TIMESTAMP="${TIMESTAMP}043000"
fi

if [[ ! "$TIMESTAMP" =~ ^[0-9]{14}$ ]]; then
	echo "Invalid date: $TIMESTAMP"
	exit 1
fi

YEAR=${TIMESTAMP:0:4}
MONTH=${TIMESTAMP:4:2}
DAY=${TIMESTAMP:6:2}
H=${TIMESTAMP:8:2}
M=${TIMESTAMP:10:2}
S=${TIMESTAMP:12:2}

echo -e "\e[1;32mCron: for $YEAR-$MONTH-$DAY $H:$M:$S\e[0m -- $TIMESTAMP"

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
# systemctl reload named
# systemctl status named

