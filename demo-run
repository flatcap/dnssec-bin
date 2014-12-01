#!/bin/bash

KEYDIR=keys
ZONE=russon.org

rm -fr 201[45]*/

START=$(date "+%s" -d "10 Sep 2014 10:00")
END=$(date "+%s" -d "20 Jan 2015")

for ((i = $START; i < $END; i += 86400)); do
	DIR=$(date -d @$i "+%Y%m%d")
	DATE=$(date "+%m%d%H%M%Y" -d @$i)
	echo
	date $DATE
	SALT=$(head -c 1000 /dev/random | sha1sum | cut -b 1-16)
	dnssec-signzone -3 $SALT -S -o $ZONE -K $KEYDIR ${ZONE}.db
	dnssec-dsfromkey -K $DIR -f ${ZONE}.db.signed ${ZONE} > dsset-${ZONE}.
	mkdir $DIR
	mv ${ZONE}.db.signed dsset-${ZONE}. $DIR
done

hwclock --hctosys

