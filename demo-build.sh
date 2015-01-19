#!/bin/bash

KEYDIR=keys
ZONE=russon.org

rm -fr $KEYDIR
mkdir -p $KEYDIR

P=$(date -d "Jul 14 2014" "+%Y%m%d%H%M%S")
A=$(date -d "Jul 16 2014" "+%Y%m%d%H%M%S")
I=$(date -d "Dec 16 2014" "+%Y%m%d%H%M%S")
D=$(date -d "Dec 18 2014" "+%Y%m%d%H%M%S")

# Create a Key Signing Key (KSK)
/usr/sbin/dnssec-keygen -P $P -A $A -I $I -D $D -a NSEC3RSASHA1 -b 4096 -n ZONE -K $KEYDIR -f KSK $ZONE

P=$(date -d "Dec 14 2014" "+%Y%m%d%H%M%S")
A=$(date -d "Dec 16 2014" "+%Y%m%d%H%M%S")
I=$(date -d "Jun 16 2015" "+%Y%m%d%H%M%S")
D=$(date -d "Jun 18 2015" "+%Y%m%d%H%M%S")

# Create a Key Signing Key (KSK)
/usr/sbin/dnssec-keygen -P $P -A $A -I $I -D $D -a NSEC3RSASHA1 -b 4096 -n ZONE -K $KEYDIR -f KSK $ZONE

bin/dnssec-keygen russon.org 2014 09
bin/dnssec-keygen russon.org 2014 10
bin/dnssec-keygen russon.org 2014 11
bin/dnssec-keygen russon.org 2014 12
bin/dnssec-keygen russon.org 2015 01

ls -l $KEYDIR

