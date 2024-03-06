#!/usr/bin/ksh
##############################################################################
##                                                                          ##
## Progrem Name : monts.ksh
##
## syntax : monts.ksh outputfile-pathname
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
OUT_DIR="$1"
if [ ! -d ${OUT_DIR} ]
then
    RET=3
    /bin/echo "Directory [$OUT_DIR] not found : $RET" >&2
    exit ${RET}

fi

#
# create output file path
#

NDATE=`date +%Y%m%d%H%M%S`
TARFILE="$OUT_DIR/monts_$NDATE.tar"


#
# Execute monts
#

MONTS_CMD="/opt/hitachi/HAmon/bin/monts"
echo "${TARFILE}" | ${MONTS_CMD} > /dev/null

RET=$?

if [ ${RET} != 0 ]
then
    /bin/echo "monts command error : $RET" >&2
    RET=2
    exit ${RET}
fi

sleep 5

gzip -f ${TARFILE}

RET=$?

if [ ${RET} != 0 ]
then
    /bin/echo "gzip command error : $RET" >&2
    RET=2
fi

    exit ${RET}

