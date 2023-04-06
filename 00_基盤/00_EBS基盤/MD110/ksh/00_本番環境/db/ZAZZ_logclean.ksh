#!/bin/ksh
##############################################################################
##                                                                          ##
## Progrem Name : logclean.ksh
##
## Parameter    :
##    $1  Target Directory Name
##    $2  Number of days to save
##
##
##############################################################################


RET=0

check_parameter_num()
{

    case $1 in
        2 )
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



TG_DIR=$1
NUM=$2


#
# check output directory
#

if [ ! -d ${TG_DIR} ]
then
    RET=3
    /bin/echo "Directory [$TG_DIR] not found : $RET" >&2
    exit ${RET}

fi


#
# Execute File cleaning
#
find $TG_DIR -noleaf -type f -mtime +$NUM -exec rm -f {} \; 1>&2

RET=$?

if [ ${RET} != 0 ]
then
    /bin/echo "find command error : $RET" >&2
    RET=2
fi

exit ${RET}

