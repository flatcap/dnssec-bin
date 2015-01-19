#!/bin/bash

KEYDIR=keys
ZONE=russon.org

rm -fr $KEYDIR
mkdir -p $KEYDIR

bin/dnssec-keygen russon.org 2014 09
bin/dnssec-keygen russon.org 2014 10
bin/dnssec-keygen russon.org 2014 11
bin/dnssec-keygen russon.org 2014 12
bin/dnssec-keygen russon.org 2015 01

P=$(date -d "jul 4 2014" "+%Y%m%d%H%M%S")
A=$(date -d "jul 6 2014" "+%Y%m%d%H%M%S")
I=$(date -d "dec 6 2014" "+%Y%m%d%H%M%S")
D=$(date -d "dec 8 2014" "+%Y%m%d%H%M%S")

# Create a Key Signing Key (KSK)
/usr/sbin/dnssec-keygen -P $P -A $A -I $I -D $D -a NSEC3RSASHA1 -b 4096 -n ZONE -K $KEYDIR -f KSK $ZONE

P=$(date -d "dec 4 2014" "+%Y%m%d%H%M%S")
A=$(date -d "dec 6 2014" "+%Y%m%d%H%M%S")
I=$(date -d "jun 6 2015" "+%Y%m%d%H%M%S")
D=$(date -d "jun 8 2015" "+%Y%m%d%H%M%S")

# Create a Key Signing Key (KSK)
/usr/sbin/dnssec-keygen -P $P -A $A -I $I -D $D -a NSEC3RSASHA1 -b 4096 -n ZONE -K $KEYDIR -f KSK $ZONE

ls -l $KEYDIR

