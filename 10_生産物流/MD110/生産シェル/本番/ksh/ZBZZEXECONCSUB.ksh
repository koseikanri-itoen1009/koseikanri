#!/bin/ksh
################################################################################
##                                                                            ##
##    [概要]                                                                  ##
##        EBSコンカレント用汎用スクリプト                                     ##
##                                                                            ##
##    [作成／更新履歴]                                                        ##
##        作成者  ：  Oracle    鈴木 雄大    2008/04/01 1.0.1                 ##
##        更新履歴：  Oracle    鈴木 雄大    2008/04/01 1.0.1                 ##
##                        初版                                                ##
##                    SCS丸下 2009/04/02 要求ID取得位置変更                   ##
##                    SCS佐野 2009/04/28 ST環境用のパラメータへ変更           ##
##                    SCS仁木 2009/06/17 CONCSUB要求待ち時間変更(60秒→1秒)   ##
##                    SCS佐野 2009/08/19 一時ファイル名変更                   ##
##                                                                            ##
##    [戻り値]                                                                ##
##        0     正常                                                          ##
##        4     警告                                                          ##
##        8     異常                                                          ##
##                                                                            ##
##    [パラメータ]                                                            ##
##        職責アプリケーション短縮名                                          ##
##        職責名                                                              ##
##        APPSユーザ名                                                        ##
##        コンカレントアプリケーション短縮名                                  ##
##        コンカレントプログラム名                                            ##
##        コンカレントパラメータ                                              ##
##                                                                            ##
##     Copyright  株式会社伊藤園 U5000プロジェクト 2007-2009                  ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

## 変数定義
#L_shellpath="/uspg/jp1/zb/shl/PEBSITO"                             #2009/08/19 DEL
L_logpath="/var/EBS/jp1/PEBSITO/log"  #ログファイルパス[環境依存値]
L_tmppath="/ebs/PEBSITO/PEBSITOcomn/temp"   #一時ファイルパス[環境依存値] #2009/08/19 Add

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

#2009/08/19 Ver1.4 Mod START
#L_tmpbase=/var/tmp/${L_cmdname}.$$
#L_std_out=${L_tmpbase}.stdout
#L_err_out=${L_tmpbase}.errout
L_tmpbase=${L_cmdname}.`/bin/date +"%Y%m%d%H%M%S"`.$$
L_std_out=${L_tmppath}/${L_tmpbase}.stdout.tmp
L_err_out=${L_tmppath}/${L_tmpbase}.errout.tmp
#2009/08/19 Ver1.4 Mod End

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

# 2009/06/17 SCS_Shigeto.Niki mod START
#L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
L_conc_args="${L_conc_args} WAIT=1 CONCURRENT"
# 2009/06/17 SCS_Shigeto.Niki mod END

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

L_reqid=`/usr/bin/awk 'NR==1 {print $3}' ${L_std_out}`

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
