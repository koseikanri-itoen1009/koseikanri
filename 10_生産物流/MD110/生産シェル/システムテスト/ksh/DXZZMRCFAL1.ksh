#!/bin/ksh
################################################################################
##                                                                            ##
##    [�T�v]                                                                  ##
##        ���v�\���̃R�s�[/�}�[�W�����N���X�N���v�g                           ##
##                                                                            ##
##    [�쐬�^�X�V����]                                                        ##
##        �쐬��  �F  Oracle    ��� �Y��    2008/05/01 1.0.1                 ##
##        �X�V�����F  Oracle    ��� �Y��    2008/05/01 1.0.1                 ##
##                        ����                                                ##
##                                                                            ##
##    [�߂�l]                                                                ##
##        0     ����                                                          ##
##        4     �x��                                                          ##
##        8     �ُ�                                                          ##
##                                                                            ##
##    [�p�����[�^]                                                            ##
##        �g�D�R�[�h                                                          ##
##        �\����                                                              ##
##        ���v�\��/���[�h�E�\�[�g�E���X�g                                     ##
##                                                                            ##
##     Copyright  ������Јɓ��� U5000�v���W�F�N�g 2007-2009                  ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

## �ϐ���`
L_shellpath="/uspg/jp1/dx/shl/TEBS02"
L_logpath="/var/tmp/jp1/log"

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

if [ ${#} -lt 3 ]
then
  output_log "Parameter Error"
  /usr/bin/cat <<-EOF 1>&2
  ${L_cmdname}
  Organization Code
  Destination Forecast
  Forecast/Load Source List
EOF
shell_end ${L_exit_eror}
fi

### Get Organization Id ###
output_log "Getting Organization Id START"
sqlplus -s apps/apps <<SQLEND >${L_std_out}
SET HEADING OFF
SET FEED OFF
SELECT ood.organization_id
FROM   org_organization_definitions ood
WHERE  ood.organization_code = '${L_mrcfal1_org_code}';
EXIT
SQLEND

L_org_id=`/usr/bin/awk '( $0 != "" ){print $1}' ${L_std_out}`

if [ ${L_org_id} ]
then
  L_param_002=${L_org_id}
  L_param_005=${L_org_id}
  output_log "Getting Organization Id was Completed"
else
  output_log "Getting Organization Id was Failed"
  shell_end ${L_exit_eror}
fi

output_log "Getting Organization Id END"

### Get StartDate and EndDate ###
output_log "Getting StartDate and EndDate START"
sqlplus -s apps/apps <<SQLEND >${L_std_out}
SET HEADING OFF
SET FEED OFF
SELECT flv.meaning
      ,TO_CHAR(FND_DATE.CANONICAL_TO_DATE(flv.meaning) + TO_NUMBER(flv.description),'YYYY/MM/DD')
FROM   fnd_lookup_values flv
      ,fnd_application fa
WHERE  flv.lookup_type = 'XXINV_KEIKAKU_TERM'
AND    fa.application_short_name = 'XXCMN'
AND    fa.application_id = flv.view_application_id
AND    flv.language = 'JA'
AND    ROWNUM = 1;
EXIT
SQLEND

L_st_date=`/usr/bin/awk '( $0 != "" && NR==2 && NF==1 ){print $1}' ${L_std_out}`
L_ed_date=`/usr/bin/awk '( $0 != "" && NR==3 && NF==1 ){print $1}' ${L_std_out}`

if [ ${L_st_date} ]
then
  L_param_011=${L_st_date}" 00:00:00"
  output_log "Getting StartDate was Completed"
else
  output_log "Getting StartDate was Failed"
  shell_end ${L_exit_eror}
fi

if [ ${L_ed_date} ]
then
  L_param_012=${L_ed_date}" 00:00:00"
  output_log "Getting EndDate was Completed"
else
  output_log "Getting EndDate was Failed"
  shell_end ${L_exit_eror}
fi
output_log "Getting StartDate and EndDate END"

### Set Conc Arguments ###
L_resp_appl=${L_def_appl}
L_resp_name=${L_def_resp}
L_user_name=${L_def_user}
L_conc_appl="MRP"
L_conc_name="MRCFAL1"
L_param_001="1"
L_param_003=${3}
L_param_004="2"
L_param_006=${2}
L_param_007="1"
L_param_008=""
L_param_009="1"
L_param_010="1"
L_param_013="2"
L_param_014="1"
L_param_015="2"
L_param_016="0"
L_param_017="0"
L_param_018="0"
L_param_019="1"
L_param_020="0"
L_param_021="0"
L_param_022="100"
L_param_023="2"
L_param_024="2"

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
L_conc_args="${L_conc_args} \"${L_param_011}\""
L_conc_args="${L_conc_args} \"${L_param_012}\""
L_conc_args="${L_conc_args} \"${L_param_013}\""
L_conc_args="${L_conc_args} \"${L_param_014}\""
L_conc_args="${L_conc_args} \"${L_param_015}\""
L_conc_args="${L_conc_args} \"${L_param_016}\""
L_conc_args="${L_conc_args} \"${L_param_017}\""
L_conc_args="${L_conc_args} \"${L_param_018}\""
L_conc_args="${L_conc_args} \"${L_param_019}\""
L_conc_args="${L_conc_args} \"${L_param_020}\""
L_conc_args="${L_conc_args} \"${L_param_021}\""
L_conc_args="${L_conc_args} \"${L_param_022}\""
L_conc_args="${L_conc_args} \"${L_param_023}\""
L_conc_args="${L_conc_args} \"${L_param_024}\""

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

L_reqid=`/usr/bin/awk 'NR==1 {print $31}' ${L_std_out}`

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
