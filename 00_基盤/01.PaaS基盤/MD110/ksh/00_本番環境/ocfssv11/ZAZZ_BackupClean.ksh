#!/usr/bin/bash
##############################################################################
##                                                                          ##
## Progrem Name : backupClean.ksh
##
## Parameter    :
##    $1  Target Directory Name
##    $2  Number of days to save
##
##
##############################################################################

###
### DATA Division
###

# OCID of compartment
PROD_COMP_OCID="ocid1.compartment.oc1..aaaaaaaaj6m7oba4twuplg7xnxnntwgyhjmnvkdlygkxpif4dpyl5snhlfnq"
STG_COMP_OCID="ocid1.compartment.oc1..aaaaaaaakchjo2t5f4anwkkesovljsqes6dqzu7akquiujvy5vgdbbw2foyq"

# OCID of PROD Block volume
PAASIF_OCID="ocid1.volume.oc1.ap-tokyo-1.abxhiljrp2gtrpwceibxdokgtk2w24lcqr56ohanknivnluetdgygmhu6m2q"
JP1_OCID="ocid1.volume.oc1.ap-tokyo-1.abxhiljrw7rlvym77e5rjds3gmqvbbtbnygnir3n4pt4oy4tfe65bu6jupua"
USPG1_OCID="ocid1.volume.oc1.ap-tokyo-1.abxhiljr3zuixfnywxyrlhrgef36q5qheifeuud665l4bv4rw3k2shxlaoha"
USPG2_OCID="ocid1.volume.oc1.ap-tokyo-1.abxhiljrj5twr5npvxnfgx4sp4nfnz4cf5ayn7esuqrtqiqqfehnmjnev5ja"




RET=0

check_parameter_num()
{

    case $1 in
        2 )
            RET=0
        ;;

        0 | * )
            /bin/echo "parameter num error : $1 " >&2
	    /bin/echo "Usage: ZAZZ_BackupClean.ksh [Dirname] [Num of day]"
            RET=1
        ;;
    esac

    return ${RET}

}

#
# check parameter
#
PARAM=$@
PARAM_NUM=$#

check_parameter_num ${PARAM_NUM}

RET=$?

if [ ${RET} != 0 ]
then
    exit ${RET}
fi


TG_DIR=$1
NUM=$2



#
# check flagfile directory
#

if [ ! -d ${TG_DIR} ]
then
    RET=3
    /bin/echo "Directory [$TG_DIR] not found : $RET" >&2
    exit ${RET}

fi


### For debug
#echo "TG_DIR="$TG_DIR
#echo "NUM="$NUM

#
# Execute File cleaning
#

for FILENAME in `find $TG_DIR -type f -mtime +$NUM ` ; do
  echo "Clean Target FILENAME"=$FILENAME

  OCID=`cat $FILENAME`
  ### For debug
  #echo "OCID="$OCID
  if echo $FILENAME | grep "bkup_" > /dev/null; then
    ### For debug
    #echo "Clean Target backup FILENAME"=$FILENAME
    #Remove backup of Tokyo region
    if echo $FILENAME | grep tokyo > /dev/null; then
      ### For debug
      #echo "bkup_tokyo_file"
      #echo "Execute clean tokyo_FILENAME="$FILENAME
      oci bv backup delete --volume-backup-id $OCID --force --wait-for-state TERMINATED
      rm -f $FILENAME

    #Remove backup of Osaka region
    elif echo $FILENAME | grep osaka > /dev/null; then
      ### For debug
      #echo "bkup_osaka_file"
      #echo "Execute clean osaka_FILENAME="$FILENAME
      oci bv backup delete --volume-backup-id $OCID --force --wait-for-state TERMINATED --region ap-osaka-1
      rm -f $FILENAME

    fi

  else
    echo "other file"
#    RET=99
  fi

done 
    


exit ${RET}

