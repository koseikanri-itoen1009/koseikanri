#! /usr/bin/ksh -f

################################################################
# ProgramName: ZCZZ_VP4300_FILTER.sh
# ProgramId:
# 
# Parameter
#
# Description
# temporary file --> /var/tmp
################################################################

YMD_HMS=`date '+%Y%m%d_%H%M%S'`

homeDir=/uspg/zc
headDir=${homeDir}/ZCZZ_VP4300_header
tempDir=${COMMON_TOP}/temp
logDir=/var/EBS/ZCZZ_VP4300

ConvProg=${homeDir}/ZCZZ_VP4300_sjis2escp

logFile=${logDir}/ZCZZ_VP4300_FILTER_${YMD_HMS}.$1.log
date '+%Y/%m/%d %H:%M:%S' >> ${logFile}

if [ $? -ne 0 ]
then
    echo "ERROR: Logfile '${logFile}' cannot create" >&2 
    exit 4;
fi

echo "Start $0" >> ${logFile}

###########################
# 0. Parameter Check
###########################

# $1: $PROFILES$.CONC_REQUEST_ID
reqId=$1
# $2: $PROFILES$.CONC_PROGRAM_ID
progId=$2
# $3: $PROFILES$.PRINTER
Printer=$3
# $4: $PROFILES$.FILENAME
flName=$4

echo "param1:"${reqId} >> ${logFile}
echo "param2:"${progId} >> ${logFile}
echo "param3:"${Printer} >> ${logFile}
echo "param4:"${flName} >> ${logFile}

if [ -z "${reqId}" -o -z "${progId}" -o -z "${Printer}" -o -z "${flName}" ]
then
    echo "ERROR: Invalid parameters" >> ${logFile}
    exit 4
fi

if [ ! -f ${flName} ]
then
    echo "ERROR: '${flName}' can not access" >> ${logFile}
    exit 4
fi

###########################
# Set Temporay Filenames
###########################
SQLPLUS_LOG=${tempDir}/${reqId}_sqlplus.txt
ESCP_FILE=${tempDir}/${reqId}_escp.out
MERGE_FILE=${tempDir}/${reqId}_cat.out

# Temporary File write test
echo "Write test" > ${SQLPLUS_LOG} 2>> ${logFile}
if [ $? -ne 0 ]
then
    echo "ERROR: Temporary File '${SQLPLUS_LOG}' cannot create" >> ${logFile}
    exit 4;
fi


CONC_PROGRAM_NAME=


###########################
# 1. SQL*Plus
###########################
date '+%Y/%m/%d %H:%M:%S' >> ${logFile}
echo "SQL*Plus Start" >> ${logFile}
which sqlplus >> ${logFile} 2>&1
echo "TWO_TASK="$TWO_TASK >> ${logFile}


sqlplus -s /nolog << EOF > ${SQLPLUS_LOG} 2>> ${logFile}
whenever sqlerror exit 1
set feedback off
set echo off
set trims on
set pages 0
-- 
CONNECT apps/apps

SELECT
    'PROGRAM_NAME '||B.CONCURRENT_PROGRAM_NAME
FROM 
    FND_CONCURRENT_PROGRAMS B
WHERE   
    B.CONCURRENT_PROGRAM_ID = '$progId';

EOF


if [ $? -ne 0 ]
then
    cat ${SQLPLUS_LOG} >> ${logFile}
    echo "ERROR: SQL*Plus abnormaly terminated" >> ${logFile}
    exit 4;
fi;

CONC_PROGRAM_NAME=`grep "PROGRAM_NAME " ${SQLPLUS_LOG} \
  | sed "s/PROGRAM_NAME *\(............\).*/\1/g"`
#--------------------------123456789012 (12Œ…Žæ‚èo‚·)

echo "getVal:"${CONC_PROGRAM_NAME} >> ${logFile}

if [ -z "${CONC_PROGRAM_NAME}" ]
then
    echo "ERROR: CONC_PROGRAM_NAME can not look-up" >> ${logFile}
    exit 4
fi

HEAD_FILE=${headDir}/head_${CONC_PROGRAM_NAME}.out

if [ ! -f ${HEAD_FILE} ]
then
    echo "ERROR: Header file '${HEAD_FILE}' can not access" >> ${logFile}
    exit 4
fi

echo "SQL*Plus Successfuly terminated" >> ${logFile}

###########################
# 2. code convert SJIS to ESCP
###########################
date '+%Y/%m/%d %H:%M:%S' >> ${logFile}
echo "Convert program '${ConvProg}' Start" >> ${logFile}

(${ConvProg} < ${flName} > ${ESCP_FILE}) 2>> ${logFile}

if [ $? -ne 0 ]
then
    echo "ERROR: Convert program '${ConvProg}' abnormaly terminated" >> ${logFile};
    exit 4;
fi;

echo "Convert program '${ConvProg}' Successfuly terminated" >> ${logFile}

###########################
# 3. Header Data merge 
###########################
date '+%Y/%m/%d %H:%M:%S' >> ${logFile}
echo "Header Data merge Start" >> ${logFile}

(cat ${HEAD_FILE} ${ESCP_FILE} > ${MERGE_FILE}) 2>> ${logFile}

if [ $? -ne 0 ]
then
    echo "ERROR: Header Data merge abnormaly terminated" >> ${logFile};
    exit 4;
fi;

(printf "\f" >>  ${MERGE_FILE}) 2>> ${logFile}

if [ $? -ne 0 ]
then
    echo "ERROR: Header Data merge (add Form feed) abnormaly terminated" >> ${logFile};
    exit 4;
fi;



echo "Header Data merge Successfuly terminated" >> ${logFile}


###########################
# 4. Print(imct printer) 
###########################
date '+%Y/%m/%d %H:%M:%S' >> ${logFile}
echo "Print-out Start" >> ${logFile}

enq -U -P${Printer} >> ${logFile} 2>&1
lp -c -d${Printer} ${MERGE_FILE} >> ${logFile} 2>&1

if [ $? -ne 0 ]
then
    echo "ERROR: Print-out abnormaly terminated" >> ${logFile};
    exit 4;
fi;

echo "Print-out SuccessFuly terminated" >> ${logFile}

#Normal end

###########################
# Remove Temporary Files
###########################
rm -f ${SQLPLUS_LOG}
rm -f ${ESCP_FILE}
rm -f ${MERGE_FILE}

date '+%Y/%m/%d %H:%M:%S' >> ${logFile}
echo "End $0" >> ${logFile}
exit 0
