#!/bin/ksh
################################################################################
##                                                                            ##
##    [概要]                                                                  ##
##        品目マスタ更新(日次)処理起動スクリプト                              ##
##                                                                            ##
##    [作成／更新履歴]                                                        ##
##        作成者  ：  Oracle    鈴木 雄大    2008/05/01 1.0.1                 ##
##        更新履歴：  Oracle    鈴木 雄大    2008/05/01 1.0.1                 ##
##                        初版                                                ##
##                    Oracle    椎名 昭圭    2009/03/02 1.0.2                 ##
##                      品目マスタ更新(日次)_呼出パラメータ｢起動区分｣追加     ##
##                    Oracle    椎名 昭圭    2009/03/13 1.0.3  本番#1315対応  ##
##                    SCS丸下 2009/04/02 要求ID取得位置変更                   ##
##                                                                            ##
##    [戻り値]                                                                ##
##        0     正常                                                          ##
##        4     警告                                                          ##
##        8     異常                                                          ##
##                                                                            ##
##    [パラメータ]                                                            ##
##        なし                                                                ##
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

### Set Conc Arguments ###
L_resp_appl=${L_def_appl}
L_resp_name=${L_def_resp}
L_user_name=${L_def_user}
L_conc_appl="XXCMN"
L_conc_name="XXCMN810002C"
L_param_001=`/bin/date "+%Y/%m/%d"`

L_conc_args="APPS/APPS"
L_conc_args="${L_conc_args} \"${L_resp_appl}\""
L_conc_args="${L_conc_args} \"${L_resp_name}\""
L_conc_args="${L_conc_args} \"${L_user_name}\""
L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
L_conc_args="${L_conc_args} \"${L_conc_appl}\""
L_conc_args="${L_conc_args} \"${L_conc_name}\""
L_conc_args="${L_conc_args} \"${L_param_001}\""
# 2009/03/02 v1.0.2 ADD START
L_conc_args="${L_conc_args} \"0\""
# 2009/03/02 v1.0.2 ADD END

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
