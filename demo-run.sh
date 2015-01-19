#!/bin/bash

KEYDIR=keys
ZONE=russon.org

rm -fr 201[45]*/

START=$(date "+%s" -d "10 Sep 2014 10:00")
# date -d @$START

END=$(date "+%s" -d "20 Jan 2015")
# date -d @$END

for ((i = $START; i < $END; i += 86400)); do
	DIR=$(date -d @$i "+%Y%m%d")
	DATE=$(date "+%m%d%H%M%Y" -d @$i)
	date $DATE
	# echo $DIR $DATE
	# date -d @$i
	echo
	dnssec-signzone -S -o $ZONE -K $KEYDIR ${ZONE}.db
	mkdir $DIR
	dnssec-dsfromkey -K $DIR -f ${ZONE}.db.signed ${ZONE} >  dsset-${ZONE}.
	mv ${ZONE}.db.signed dsset-${ZONE}. $DIR
done


