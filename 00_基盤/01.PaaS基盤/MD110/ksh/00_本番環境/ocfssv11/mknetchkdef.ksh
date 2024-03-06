#!/bin/ksh


LOCALHOSTNAME=`hostname`

echo "### netchk.def - "$LOCALHOSTNAME

for ELEMENT in `ifconfig -a | awk 'BEGIN {group=0; interface=""; adr="";}
#                      /eth[0-9]/ {group=1; interface=$1;}
                      /ens[0-9]/ {group=1; interface=$1;}
#                      /inet/ {if(group==1) {adr=$2; gsub("addr:","",adr); printf("%s,%s\n", interface, adr);};}
                      /inet/ {if(group==1) {adr=$2; gsub("addr:","",adr); printf("%s\n", adr);};}
                      /lo/ {group=0; internace="";}'`
do
#     echo ELEMENT:[$LOCALHOSTNAME:$ELEMENT]
     echo $LOCALHOSTNAME:$ELEMENT
done
