#!/bin/ksh
################################################################################
##                                                                            ##
##    [�T�v]                                                                  ##
##        EBS�R���J�����g�p�ėp�X�N���v�g                                     ##
##                                                                            ##
##    [�쐬�^�X�V����]                                                        ##
##        �쐬��  �F  Oracle    ��� �Y��    2008/04/01 1.0.1                 ##
##        �X�V�����F  Oracle    ��� �Y��    2008/04/01 1.0.1                 ##
##                        ����                                                ##
##                                                                            ##
##    [�߂�l]                                                                ##
##        0     ����                                                          ##
##        4     �x��                                                          ##
##        8     �ُ�                                                          ##
##                                                                            ##
##    [�p�����[�^]                                                            ##
##        �E�ӃA�v���P�[�V�����Z�k��                                          ##
##        �E�Ӗ�                                                              ##
##        APPS���[�U��                                                        ##
##        �R���J�����g�A�v���P�[�V�����Z�k��                                  ##
##        �R���J�����g�v���O������                                            ##
##        �R���J�����g�p�����[�^                                              ##
##                                                                            ##
##     Copyright  ������Јɓ��� U5000�v���W�F�N�g 2007-2009                  ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

## �ϐ���`
L_shellpath="/uspg/jp1/zb/shl/PEBSITO"
L_logpath="/var/EBS/jp1/PEBSITO/log"

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d"`
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"
L_envfile=${L_cmddir}/ZBZZAPPS.env

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

if [ ${#} -lt 5 ]
then
  output_log "Parameter Error"
  /usr/bin/cat <<-EOF 1>&2
  ${L_cmdname}
  Responsibility_Application_Short_Name
  Responsibility_Name
  User_name
  Concurrent_Program_Application_Short_Name
  Concurrent_Program_Name
  [Concurrent_Program_Arguments]
EOF
shell_end ${L_exit_eror}
fi

L_para_appl=${1}
L_para_resp=${2}
L_para_user=${3}
L_conc_appl=${4}
L_conc_name=${5}
shift 5

if [ "${L_para_appl}" != \"\" ]
then
  L_resp_appl=${L_para_appl}
else
  L_resp_appl=${L_def_appl}
fi

if [ "${L_para_resp}" != \"\" ]
then
  L_resp_name=${L_para_resp}
else
  L_resp_name=${L_def_resp}
fi

if [ "${L_para_user}" != \"\" ]
then
  L_user_name=${L_para_user}
else
  L_user_name=${L_def_user}
fi

### Generate Arguments ###
L_conc_args="APPS/APPS"
L_conc_args="${L_conc_args} \"${L_resp_appl}\""
L_conc_args="${L_conc_args} \"${L_resp_name}\""
L_conc_args="${L_conc_args} \"${L_user_name}\""
L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
L_conc_args="${L_conc_args} \"${L_conc_appl}\""
L_conc_args="${L_conc_args} \"${L_conc_name}\""

### Set Language ###
NLS_LANG=Japanese_Japan.JA16SJIS
export NLS_LANG

### Submit Concurrent Program ###
output_log "Execute CONCSUB START"
${FND_TOP}/bin/CONCSUB ${L_conc_args} ${@+"$@"} >${L_std_out} 2>${L_err_out}
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

if [ $L_paracount = 5 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $5}' ${L_std_out}`
elif [ $L_paracount = 6 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $6}' ${L_std_out}`
elif [ $L_paracount = 7 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $7}' ${L_std_out}`
elif [ $L_paracount = 8 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $8}' ${L_std_out}`
elif [ $L_paracount = 9 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $9}' ${L_std_out}`
elif [ $L_paracount = 10 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $10}' ${L_std_out}`
elif [ $L_paracount = 11 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $11}' ${L_std_out}`
elif [ $L_paracount = 12 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $12}' ${L_std_out}`
elif [ $L_paracount = 13 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $13}' ${L_std_out}`
elif [ $L_paracount = 14 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $14}' ${L_std_out}`
elif [ $L_paracount = 15 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $15}' ${L_std_out}`
elif [ $L_paracount = 16 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $16}' ${L_std_out}`
elif [ $L_paracount = 17 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $17}' ${L_std_out}`
elif [ $L_paracount = 18 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $18}' ${L_std_out}`
elif [ $L_paracount = 19 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $19}' ${L_std_out}`
elif [ $L_paracount = 20 ]
then
  L_reqid=`/usr/bin/awk 'NR==1 {print $20}' ${L_std_out}`
fi

L_out_all=`/usr/bin/awk '{print $0}' ${L_std_out}`
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
