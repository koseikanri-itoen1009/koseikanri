#!/usr/bin/bash
##############################################################################
##                                                                          ##
## Progrem Name : BlockVolumeBackup.ksh
##
## Parameter    :
##    $1  Select volume (PAASIF,JP1,USPG1,USPG2,BACKUP1,BACKUP2)
##    $2  Directory Name of Flag file
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
BACKUP1_OCID="ocid1.volume.oc1.ap-tokyo-1.abxhiljrf7lddea5e4ex6i2ad5zksgpm72ntwtzu56ayx6arxkaq4ltqto3a"
BACKUP2_OCID="ocid1.volume.oc1.ap-tokyo-1.abxhiljrvgj2lwuvf36il3vhtlwvsgidhtioqt3nkx7hzx2l66474mdmic5a"



# Create Backup Name
DATETIME=`date +%Y%m%d%H%M%S`
# For tokyo
BKUP_PAASIF_TNAME=`echo "bkup_paasif_tokyo_$DATETIME"`
BKUP_JP1_TNAME=`echo "bkup_jp1_tokyo_$DATETIME"`
BKUP_USPG1_TNAME=`echo "bkup_uspg1_tokyo_$DATETIME"`
BKUP_USPG2_TNAME=`echo "bkup_uspg2_tokyo_$DATETIME"`
BKUP_BACKUP1_TNAME=`echo "bkup_backup1_tokyo_$DATETIME"`
BKUP_BACKUP2_TNAME=`echo "bkup_backup2_tokyo_$DATETIME"`
# For osaka
BKUP_PAASIF_ONAME=`echo "bkup_paasif_osaka_$DATETIME"`
BKUP_JP1_ONAME=`echo "bkup_jp1_osaka_$DATETIME"`
BKUP_USPG1_ONAME=`echo "bkup_uspg1_osaka_$DATETIME"`
BKUP_USPG2_ONAME=`echo "bkup_uspg2_osaka_$DATETIME"`
BKUP_BACKUP1_ONAME=`echo "bkup_backup1_osaka_$DATETIME"`
BKUP_BACKUP2_ONAME=`echo "bkup_backup2_osaka_$DATETIME"`


RET=0

check_parameter_num()
{

    case $1 in
        2 )
            RET=0
        ;;

        0 | * )
            /bin/echo "parameter num error : $1 " >&2
	    /bin/echo "Usage: ZAZZ_BlockVol_Backup.ksh [Volname] [Dirname]"
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


VOL=$1
TG_DIR=$2
#TG_DIR=$FLG_PATH

#
# check flagfile directory
#

if [ ! -d ${TG_DIR} ]
then
    RET=3
    /bin/echo "Directory [$TG_DIR] not found : $RET" >&2
    exit ${RET}

fi


case $VOL in
PAASIF | paasif )
  #echo "Execute paasif"
  VOL_OCID=$PAASIF_OCID
  BKUP_TNAME=$BKUP_PAASIF_TNAME
  BKUP_ONAME=$BKUP_PAASIF_ONAME

  ;;
JP1 | jp1 )
  #echo "Execute jp1"
  VOL_OCID=$JP1_OCID
  BKUP_TNAME=$BKUP_JP1_TNAME
  BKUP_ONAME=$BKUP_JP1_ONAME

  ;;
USPG1 | uspg1 )
  #echo "Execute uspg1"
  VOL_OCID=$USPG1_OCID
  BKUP_TNAME=$BKUP_USPG1_TNAME
  BKUP_ONAME=$BKUP_USPG1_ONAME

  ;;
USPG2 | uspg2 )
  #echo "Execute uspg2"
  VOL_OCID=$USPG2_OCID
  BKUP_TNAME=$BKUP_USPG2_TNAME
  BKUP_ONAME=$BKUP_USPG2_ONAME

  ;;
BACKUP1 | backup1 )
  #echo "Execute backup1"
  VOL_OCID=$BACKUP1_OCID
  BKUP_TNAME=$BKUP_BACKUP1_TNAME
  BKUP_ONAME=$BKUP_BACKUP1_ONAME

  ;;
BACKUP2 | backup2 )
  #echo "Execute backup2"
  VOL_OCID=$BACKUP2_OCID
  BKUP_TNAME=$BKUP_BACKUP2_TNAME
  BKUP_ONAME=$BKUP_BACKUP2_ONAME

  ;;
* )
  echo "Bad select name.(name= [PAASIF],[JP1],[USPG1],[USPG2],[BACKUP1],[BACKUP2]) exit. "
  RET=2
  ;;

esac

##For Debug
#echo BKUP_TNAME=$BKUP_TNAME
#echo BKUP_ONAME=$BKUP_ONAME


if [ ${RET} != 0 ]
then
    exit ${RET}
fi



###
### Execute Main Backup
###

oci bv backup create --volume-id $VOL_OCID --display-name $BKUP_TNAME --wait-for-state AVAILABLE

if [ $? != 0 ]
then
    echo "Error: oci bv backup create. NAME="$BKUP_TNAME
    exit ${RET}
fi

###
### Make Flag of Main Backup
###

sleep 5
BKUP_TOCID=$(oci bv backup list -c $PROD_COMP_OCID --display-name $BKUP_TNAME | jq -r '.data[].id')

echo $BKUP_TOCID > $TG_DIR/$BKUP_TNAME

if [ $? != 0 ]
then
    echo "Error: Make Flag of Main Backup. NAME="$TG_DIR/BKUP_TNAME
    exit ${RET}
fi


###
### Execute Sub Backup(copy)
###

oci bv backup copy --destination-region ap-osaka-1 --volume-backup-id $BKUP_TOCID --display-name $BKUP_ONAME --wait-for-state AVAILABLE

if [ $? != 0 ]
then
    echo "Error: oci bv backup copy. NAME="$BKUP_ONAME
    exit ${RET}
fi

###
### Make Flag of Sub Backup
###

sleep 5
BKUP_OOCID=$(oci bv backup list -c $PROD_COMP_OCID --display-name $BKUP_ONAME --region ap-osaka-1| jq -r '.data[].id')


echo $BKUP_OOCID > $TG_DIR/$BKUP_ONAME

if [ $? != 0 ]
then
    echo "Error: Make Flag of Sub Backup. NAME="$TG_DIR/BKUP_ONAME
    exit ${RET}
fi


exit 0

