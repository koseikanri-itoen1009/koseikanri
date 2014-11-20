#!/bin/ksh
################################################################################
##                                                                            ##
##    [概要]                                                                  ##
##        HHT入出庫配送計画情報抽出起動スクリプト                             ##
##                                                                            ##
##    [作成／更新履歴]                                                        ##
##        作成者  ：  Oracle    鈴木 雄大    2008/05/01 1.0.1                 ##
##        更新履歴：  Oracle    鈴木 雄大    2008/05/01 1.0.1                 ##
##                    Oracle    鈴木 雄大    2008/07/22 1.0.2                 ##
##                        初版                                                ##
##                    SCS丸下 2009/04/02 要求ID取得位置変更                   ##
##                                                                            ##
##    [戻り値]                                                                ##
##        0     正常                                                          ##
##        4     警告                                                          ##
##        8     異常                                                          ##
##                                                                            ##
##    [パラメータ]                                                            ##
##        部署                                                                ##
##                                                                            ##
##     Copyright  株式会社伊藤園 U5000プロジェクト 2007-2009                  ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

## 変数定義
L_shellpath="/uspg/jp1/dx/shl/PEBSITO"
L_logpath="/var/EBS/jp1/PEBSITO/log"

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
##                                 関数定義                                   ##
################################################################################

### ログ出力処理 ###
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}

### 終了処理 ###
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

if [ ${#} -lt 10 ]
then
  output_log "Parameter Error"
  /usr/bin/cat <<-EOF 1>&2
  ${L_cmdname}
  Department Code01
  Department Code02
  Department Code03
  Department Code04
  Department Code05
  Department Code06
  Department Code07
  Department Code08
  Department Code09
  Department Code10
EOF
shell_end ${L_exit_eror}
fi

### Set Conc Arguments ###
L_resp_appl=${L_def_appl}
L_resp_name=${L_def_resp}
L_user_name=${L_def_user}
L_conc_appl="XXWSH"
L_conc_name="XXWSH600004C"
L_param_001=${1}
#2008/07/22 y.suzuki change
if [ ${2} == \"\" ]
then
  L_param_002=""
else
  L_param_002=${2}
fi
if [ ${3} == \"\" ]
then
  L_param_003=""
else
  L_param_003=${3}
fi
if [ ${4} == \"\" ]
then
  L_param_004=""
else
  L_param_004=${4}
fi
if [ ${5} == \"\" ]
then
  L_param_005=""
else
  L_param_005=${5}
fi
if [ ${6} == \"\" ]
then
  L_param_006=""
else
  L_param_006=${6}
fi
if [ ${7} == \"\" ]
then
  L_param_007=""
else
  L_param_007=${7}
fi
if [ ${8} == \"\" ]
then
  L_param_008=""
else
  L_param_008=${8}
fi
if [ ${9} == \"\" ]
then
  L_param_009=""
else
  L_param_009=${9}
fi
if [ ${10} == \"\" ]
then
  L_param_010=""
else
  L_param_010=${10}
fi
#L_param_002=`/bin/date "+%Y/%m/%d"`
#L_param_003=""
#L_param_004=""
L_param_011=`/bin/date "+%Y/%m/%d"`
L_param_012=""
L_param_013=""

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
#2008/07/22 y.suzuki add
L_conc_args="${L_conc_args} \"${L_param_005}\""
L_conc_args="${L_conc_args} \"${L_param_006}\""
L_conc_args="${L_conc_args} \"${L_param_007}\""
L_conc_args="${L_conc_args} \"${L_param_008}\""
L_conc_args="${L_conc_args} \"${L_param_009}\""
L_conc_args="${L_conc_args} \"${L_param_010}\""
L_conc_args="${L_conc_args} \"${L_param_011}\""
L_conc_args="${L_conc_args} \"${L_param_012}\""
L_conc_args="${L_conc_args} \"${L_param_013}\""

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

#2008/07/22 y.suzuki change
#L_reqid=`/usr/bin/awk 'NR==1 {print $9}' ${L_std_out}`
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
