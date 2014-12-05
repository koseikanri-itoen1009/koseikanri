#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : AZZZEXECONCSUB                                            ##
## Description      : EBSコンカレント用汎用スクリプト                           ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 1.5                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1       職責アプリケーション短縮名                                         ##
##  $2       職責名                                                             ##
##  $3       APPSユーザ名                                                       ##
##  $4       コンカレントアプリケーション短縮名                                 ##
##  $5       コンカレントプログラム名                                           ##
##  $6～$40  コンカレントパラメータ ※最大35個                                  ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/28    1.0   Masayuki.Sano    新規作成                               ##
##  2009/03/19    1.1   Masayuki.Sano    ・ENVファイル名変更対応                ##
##                                       ・ファイル名変更                       ##
##                                        (AZBZZEXECONCSUB⇒AZZZEXECONCSUB)     ##
##  2009/04/15    1.2   Masayuki.Sano    障害番号[T1-0522]                      ##
##                                       ・要求IDの取得方法変更                 ##
##                                       ・要求IDの取得失敗時、異常処理を追加   ##
##  2009/06/17    1.3   Shigeto.Niki     [PT単体性能フィードバック]             ##
##                                         CONCSUB要求待ち時間変更              ##
##                                           (デフォルト60秒→1秒)              ##
##  2009/08/19    1.4   Masayuki.Sano    障害番号[0000835]                      ##
##                                       ・一時ファイル名変更                   ##
##  2014/08/05    1.5   Shota.Takahashi  リプレース_00004対応                   ##
##                                                                              ##
##################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

## 変数定義
#2014/08/05 ADD Ver.1.5 by Shota Takahashi START
L_envname=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`       #シェルの格納ディレクトリ
#2014/08/05 ADD Ver.1.5 by Shota Takahashi END

#L_shellpath="/uspg/jp1/zb/shl/T1"                                  #2009/08/19 Ver1.4 DEL
#2014/08/05 UPDATE Ver.1.5 by Shota Takahashi START
#L_logpath="/var/log/jp1/T4"           #ログファイルパス[環境依存値]
#L_tmppath="/var/tmp"                  #一時ファイルパス[環境依存値] #2009/08/19 Ver1.4 Add
L_logpath="/var/log/jp1/${L_envname}" #ログファイルパス
L_tmppath="/tmp"
#2014/08/05 UPDATE Ver.1.5 by Shota Takahashi End

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d"`
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"
#2009/03/19 UPDATE START
#L_envfile=${L_cmddir}/AZBZZAPPS.env
L_envfile=${L_cmddir}/AZZZAPPS.env
#2009/03/19 UPDATE END

#2009/04/15 UPDATE Ver.1.2 by Masayuki.Sano START
#L_exit_norm=0
#L_exit_warn=3
#L_exit_eror=7
L_exit_norm=0
L_exit_warn=4
L_exit_eror=8
#2009/04/15 UPDATE Ver.1.2 by Masayuki.Sano END

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

# 2009/06/17 Ver.1.3 Shigeto.Niki mod START
#L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
L_conc_args="${L_conc_args} WAIT=1 CONCURRENT"
# 2009/06/17 Ver.1.3 Shigeto.Niki mod END

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

#2009/04/15 UPDATE Ver.1.2 BY Masayuki.Sano START
#if [ $L_paracount = 5 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $5}' ${L_std_out}`
#elif [ $L_paracount = 6 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $6}' ${L_std_out}`
#elif [ $L_paracount = 7 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $7}' ${L_std_out}`
#elif [ $L_paracount = 8 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $8}' ${L_std_out}`
#elif [ $L_paracount = 9 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $9}' ${L_std_out}`
#elif [ $L_paracount = 10 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $10}' ${L_std_out}`
#elif [ $L_paracount = 11 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $11}' ${L_std_out}`
#elif [ $L_paracount = 12 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $12}' ${L_std_out}`
#elif [ $L_paracount = 13 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $13}' ${L_std_out}`
#elif [ $L_paracount = 14 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $14}' ${L_std_out}`
#elif [ $L_paracount = 15 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $15}' ${L_std_out}`
#elif [ $L_paracount = 16 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $16}' ${L_std_out}`
#elif [ $L_paracount = 17 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $17}' ${L_std_out}`
#elif [ $L_paracount = 18 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $18}' ${L_std_out}`
#elif [ $L_paracount = 19 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $19}' ${L_std_out}`
#elif [ $L_paracount = 20 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $20}' ${L_std_out}`
#elif [ $L_paracount = 21 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $21}' ${L_std_out}`
#elif [ $L_paracount = 22 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $22}' ${L_std_out}`
#elif [ $L_paracount = 23 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $23}' ${L_std_out}`
#elif [ $L_paracount = 24 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $24}' ${L_std_out}`
#elif [ $L_paracount = 25 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $25}' ${L_std_out}`
#elif [ $L_paracount = 26 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $26}' ${L_std_out}`
#elif [ $L_paracount = 27 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $27}' ${L_std_out}`
#elif [ $L_paracount = 28 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $28}' ${L_std_out}`
#elif [ $L_paracount = 29 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $29}' ${L_std_out}`
#elif [ $L_paracount = 30 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $30}' ${L_std_out}`
#elif [ $L_paracount = 31 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $31}' ${L_std_out}`
#elif [ $L_paracount = 32 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $32}' ${L_std_out}`
#elif [ $L_paracount = 33 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $33}' ${L_std_out}`
#elif [ $L_paracount = 34 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $34}' ${L_std_out}`
#elif [ $L_paracount = 35 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $35}' ${L_std_out}`
#elif [ $L_paracount = 36 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $36}' ${L_std_out}`
#elif [ $L_paracount = 37 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $37}' ${L_std_out}`
#elif [ $L_paracount = 38 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $38}' ${L_std_out}`
#elif [ $L_paracount = 39 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $39}' ${L_std_out}`
#elif [ $L_paracount = 40 ]
#then
#  L_reqid=`/usr/bin/awk 'NR==1 {print $40}' ${L_std_out}`
#fi
# 要求IDの取得
L_reqid=`/usr/bin/awk 'NR==1 {print $3}' ${L_std_out}`
# 取得できたか確認を行なう。
if [ "$(echo ${L_reqid} | egrep '^[0-9]+$')" = "" ]
then
  output_log "Getting RequestID was Failed(RequestID : ${L_reqid} )"
  shell_end ${L_exit_eror}
fi
#2009/04/15 UPDATE Ver.1.2 BY Masayuki.Sano END

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
