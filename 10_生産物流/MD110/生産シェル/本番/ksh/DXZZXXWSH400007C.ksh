#!/bin/ksh
################################################################################
##                                                                            ##
##    [�T�v]                                                                  ##
##        �o�׈˗����ߏ����N���X�N���v�g                                      ##
##                                                                            ##
##    [�쐬�^�X�V����]                                                        ##
##        �쐬��  �F  Oracle    ��� �Y��    2008/05/01 1.0.1                 ##
##        �X�V�����F  Oracle    ��� �Y��    2008/05/01 1.0.1                 ##
##                    Oracle    ��� �Y��    2008/07/07 1.0.2                 ##
##                    Oracle    ��� �Y��    2008/07/14 1.0.3                 ##
##                        ����                                                ##
##                    SCS�ۉ� 2009/04/02 �v��ID�擾�ʒu�ύX                   ##
##                    SCSK      ���� ����    2014/08/05 1.0.4                 ##
##                        ���v���[�X_00004�Ή�                                ##
##                                                                            ##
##    [�߂�l]                                                                ##
##        0     ����                                                          ##
##        4     �x��                                                          ##
##        8     �ُ�                                                          ##
##                                                                            ##
##    [�p�����[�^]                                                            ##
##        �o�Ɍ`��                                                            ##
##        �o�Ɍ�                                                              ##
##        ���_�J�e�S��                                                        ##
##        ���Y����LT/����ύXLT                                               ##
##        �o�ɓ�                                                              ##
##        ���i�敪                                                            ##
##        ����                                                                ##
##                                                                            ##
##     Copyright  ������Јɓ��� U5000�v���W�F�N�g 2007-2009                  ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

## �ϐ���`
#2014/08/05 ADD Ver.1.0.4 by Shota Takahashi START
L_envname=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #�V�F���̊i�[�f�B���N�g��
#2014/08/05 ADD Ver.1.0.4 by Shota Takahashi END

#2014/08/05 MOD Ver.1.0.4 by Shota Takahashi START
#L_shellpath="/uspg/jp1/dx/shl/PEBSITO"
#L_logpath="/var/EBS/jp1/PEBSITO/log"
L_shellpath="/uspg/jp1/dx/shl/${L_envname}"
L_logpath="/var/EBS/jp1/${L_envname}/log"
#2014/08/05 MOD Ver.1.0.4 by Shota Takahashi END

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d"`
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"
L_envfile=${L_cmddir}/DXZZAPPS.env

L_exit_norm=0
L_exit_warn=4
L_exit_eror=8

L_tmpbase=/tmp/${L_cmdname}.$$
L_std_out=${L_tmpbase}.stdout
L_err_out=${L_tmpbase}.errout

################################################################################
##                                 �֐���`                                   ##
################################################################################

### ���O�o�͏��� ###
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}

### �I������ ###
shell_end()
{
  if [ -f ${L_std_out} ]
  then
    rm ${L_std_out}
  fi
  if [ -f ${L_err_out} ]
  then
    rm ${L_err_out}
  fi
  L_retcode=${1:-0}
  output_log "`/bin/basename ${0}` END  END_CD="${L_retcode}
  exit ${L_retcode}
}

################################################################################
##                                   Main                                     ##
################################################################################

### Put log ###
touch ${L_logfile}
output_log "`/bin/basename ${0}` START"

### Read Shell Env File ###
output_log "Reading Shell Env File START"

if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading Shell Env File was Completed"
else
  output_log "Reading Shell Env File was Failed"
  shell_end ${L_exit_eror}
fi

output_log "Reading Shell Env File END"

### Read APPS Env File ###
output_log "Reading APPS Env File START"

if [ -r ${L_appsora} ]
then
  . ${L_appsora}
  output_log "Reading APPS Env File was Completed"
else
  output_log "Reading APPS Env File was Failed"
  shell_end ${L_exit_eror}
fi

output_log "Reading APPS Env File END"

### Argument Check ###
L_paracount=${#}

#2008/07/07 y.suzuki change
#if [ ${#} -lt 6 ]
if [ ${#} -lt 7 ]
then
  output_log "Parameter Error"
  /usr/bin/cat <<-EOF 1>&2
  ${L_cmdname}
  Delivery Type
  Delivery From
  Base Category
  LeadTime
  DeliveryDate(Offset)
  Item Type
  Department Code
EOF
shell_end ${L_exit_eror}
fi

#2008/07/07 y.suzuki change
#L_offset=${4}
L_offset=${5}

### Get Delivery Date ###
output_log "Getting Delivery Date START"
sqlplus -s apps/apps <<SQLEND >${L_std_out}
SET HEADING OFF
SET FEED OFF
SELECT TO_CHAR(SYSDATE + TO_NUMBER('${L_offset}'),'YYYY/MM/DD')
FROM   DUAL;
EXIT
SQLEND

#2008/07/07 y.suzuki change
#L_param_005=`/usr/bin/awk '( $0 != "" ){print $1}' ${L_std_out}`
L_param_006=`/usr/bin/awk '( $0 != "" ){print $1}' ${L_std_out}`

#2008/07/07 y.suzuki change
#if [ ${L_param_005} ]
if [ ${L_param_006} ]
then
  output_log "Getting Delivery Date was Completed"
else
  output_log "Getting Delivery Date was Failed"
  shell_end ${L_exit_eror}
fi

output_log "Getting Delivery Date END"

### Set Conc Arguments ###
L_resp_appl=${L_def_appl}
L_resp_name=${L_def_resp}
L_user_name=${L_def_user}
L_conc_appl="XXWSH"
L_conc_name="XXWSH400007C"
#2008/07/07 y.suzuki change
#L_param_001=${1}
#L_param_002=""
#L_param_003=${2}
#L_param_004=${3}
#L_param_006="Y"
#L_param_007=""
#L_param_008="1"
#L_param_009=${5}
#L_param_010=${6}
#2008/07/14 y.suzuki change
#L_param_001=${1}
if [ ${1} == \"\" ]
then
  L_param_001=""
else
  L_param_001=${1}
fi
#2008/07/14 y.suzuki change
#L_param_002=${2}
if [ ${2} == \"\" ]
then
  L_param_002=""
else
  L_param_002=${2}
fi
L_param_003=""
L_param_004=${3}
L_param_005=${4}
L_param_007="Y"
L_param_008=""
L_param_009="1"
L_param_010=${6}
L_param_011=""
L_param_012=${7}

L_conc_args="APPS/APPS"
L_conc_args="${L_conc_args} \"${L_resp_appl}\""
L_conc_args="${L_conc_args} \"${L_resp_name}\""
L_conc_args="${L_conc_args} \"${L_user_name}\""
L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
L_conc_args="${L_conc_args} \"${L_conc_appl}\""
L_conc_args="${L_conc_args} \"${L_conc_name}\""
L_conc_args="${L_conc_args} \"${L_param_001}\""
L_conc_args="${L_conc_args} \"${L_param_002}\""
L_conc_args="${L_conc_args} \"${L_param_003}\""
L_conc_args="${L_conc_args} \"${L_param_004}\""
L_conc_args="${L_conc_args} \"${L_param_005}\""
L_conc_args="${L_conc_args} \"${L_param_006}\""
L_conc_args="${L_conc_args} \"${L_param_007}\""
L_conc_args="${L_conc_args} \"${L_param_008}\""
L_conc_args="${L_conc_args} \"${L_param_009}\""
L_conc_args="${L_conc_args} \"${L_param_010}\""
#2008/07/07 y.suzuki add
L_conc_args="${L_conc_args} \"${L_param_011}\""
L_conc_args="${L_conc_args} \"${L_param_012}\""

### Set Language ###
NLS_LANG=Japanese_Japan.JA16SJIS
export NLS_LANG

### Submit Concurrent Program ###
output_log "Execute CONCSUB START"
${FND_TOP}/bin/CONCSUB ${L_conc_args} >${L_std_out} 2>${L_err_out}
L_return_code=${?}

if [ ${L_return_code} -ne 0 ]
then
  output_log "Executing CONCSUB was Failed"
  /usr/bin/cat <<-EOF 1>&2
  ${L_cmdname} SYSTEM ERROR. CONCSUB ABORT.
  Return Code: ${L_return_code}
EOF
  /usr/bin/cat ${L_std_out} ${L_err_out} 1>&2
  shell_end ${L_exit_eror}
fi

#2008/07/07 y.suzuki change
#L_reqid=`/usr/bin/awk 'NR==1 {print $15}' ${L_std_out}`
L_reqid=`/usr/bin/awk 'NR==1 {print $3}' ${L_std_out}`

output_log "RequestID : ${L_reqid}"

output_log "Execute CONCSUB END"

### Output Concurrent Status ###
output_log "Getting Concurrent Status START"
sqlplus -s apps/apps <<SQLEND >${L_std_out}
SET HEADING OFF
SELECT request_id, phase_code, status_code
FROM fnd_concurrent_requests
WHERE request_id = '${L_reqid}';
EXIT
SQLEND

L_get_req_id=`/usr/bin/awk '( $0 != "" ){print $1}' ${L_std_out}`
L_phase_code=`/usr/bin/awk '( $0 != "" ){print $2}' ${L_std_out}`
L_status_code=`/usr/bin/awk '( $0 != "" ){print $3}' ${L_std_out}`

output_log RequestID : $L_get_req_id Phase_Code : $L_phase_code Status Code : $L_status_code

output_log "Getting Concurrent Status END"

### Status Check ###
case ${L_status_code} in
C)
  # Normal
  output_log "Concurrent Status was normal"
  L_exit_status=$L_exit_norm
  ;;
G)
  # Warning
  output_log "Concurrent Status was warning"
  L_exit_status=$L_exit_warn
  ;;
*)
  # Other(Error/Unknown)
  output_log "Concurrent Status was error"
  L_exit_status=$L_exit_eror
  ;;
esac

### Shell end ###
shell_end $L_exit_status
