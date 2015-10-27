#!/bin/bash

# Copyright 2015 Richard Russon (FlatCap)
# Licensed under the GPLv3

FILE="${GPG_DOMAIN}.gpg.inc"
KEY="$GPG_KEY_ID"
PATH="/var/named/bin:/usr/bin:/usr/sbin"
source log.sh

set -o errexit	# set -e
set -o nounset	# set -u

renice --priority 19 --pid $$ > /dev/null
ionice --class 3     --pid $$ > /dev/null

function finish()
{
	local RETVAL=$?
	[ $RETVAL = 0 ] || log_error "${0##*/} failed: $RETVAL"
}

trap finish EXIT

log_info "Generate PKA/DANE Records for GPG"

(
	gpg2 --list-keys --print-pka-records  "$KEY"
	gpg2 --list-keys --print-dane-records "$KEY"
) > "$FILE"

exit 0

