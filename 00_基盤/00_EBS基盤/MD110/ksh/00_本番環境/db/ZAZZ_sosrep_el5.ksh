#!/bin/ksh
##############################################################################
##                                                                          ##
## Progrem Name : sosrep_el5.ksh
##
## Parameter    :
##    $1  Output Directory Name
##
##
##############################################################################


RET=0

check_parameter_num()
{

    case $1 in
        1 )
            RET=0
        ;;

        0 | * )
            /bin/echo "parameter num error : $1 " >&2
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



#
# check output directory
#
OUT_DIR=$1

if [ ! -d ${OUT_DIR} ]
then
    RET=3
    /bin/echo "Directory [$OUT_DIR] not found : $RET" >&2
    exit ${RET}

fi


#
# Execute sosreport
#
# sosreport for RHEL5
#sosreport -n cluster,openswan,smartcard,printing -k rpm.rpmva=off --batch --tmp-dir=$OUT_DIR &> /dev/null

RET=$?

if [ ${RET} != 0 ]
then
    /bin/echo "sosreport command error : $RET" >&2
    RET=2
fi

exit ${RET}

