#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : AZXXCCP009A02C                                            ##
## Description      : 対向システムジョブ状況更新処理                            ##
## MD.050           : 対向システムジョブ状況更新処理 <MD050_CCP_009_A02>        ##
## Version          : 1.5                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
## $1       処理順付要求ID                                                      ##
## $2       更新ステータス                                                      ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/05    1.0   Koji.Oomata      新規作成                               ##
##  2009/03/04    1.1   Koji.Oomata      [障害COS_138]                          ##
##                                         APPSORA.env読込処理追加              ##
##                                         CONCSUB要求待ち時間変更              ##
##                                           (デフォルト60秒→15秒)             ##
##                                         ログ出力方法変更                     ##
##                                         入力パラメータ必須チェック追加       ##
##                                         ファイル名変更 (AXXXCCP009A02C.sh    ##
##                                                         →AZXXCCP009A02C.ksh)##
##                                         変更履歴のフォーマット変更           ##
##  2009/04/01    1.2   Masayuki.Sano    画面起動ジョブネットの多重制御対応     ##
##                                         外部シェル名変更対応                 ##
##  2009/06/17    1.3   Shigeto.Niki     [PT単体性能フィードバック]             ##
##                                         CONCSUB要求待ち時間変更              ##
##                                           (デフォルト15秒→1秒)              ##
##  2009/11/23    1.4   Shigeto.Niki     ログ出力先修正                         ##
##  2014/08/05    1.5   Shota.Takahashi  リプレース_00004対応                   ##
##################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################
L_resp_appl="XXCCP"                  #職責：アプリケーション短縮名
L_resp_name="JP1SALES"               #職責名
L_user_name="JP1SALES"               #ユーザ名
L_conc_appl="XXCCP"                  #コンカレント：アプリケーション短縮名
L_conc_name="XXCCP009A02C"           #コンカレント：プログラム短縮名
# 2009/03/04 Ver.1.1 Koji.Oomata add START

# 2014/08/05 Ver.1.5 Shota.Takahashi add START
L_envname=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #シェルの格納ディレクトリ
# 2014/08/05 Ver.1.5 Shota.Takahashi add END

# 2009/11/23 Ver.1.4 Shigeto.Niki mod START
#L_logpath="/var/tmp/jp1/log"
# 2014/08/05 Ver.1.5 Shota.Takahashi mod START
#L_logpath="/var/log/jp1/PEBSITO"
L_logpath="/var/log/jp1/${L_envname}"                             #ログファイルパス
# 2014/08/05 Ver.1.5 Shota.Takahashi mod END
# 2009/11/23 Ver.1.4 Shigeto.Niki mod END

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d%H%M%S"`

#ログファイル (→正常終了の場合 削除)
# ファイル名: AZXXCCP009A02C_(ホスト名)_(処理順付要求ID)_yyyymmddhh24miss_(プロセスID).log
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${1}_${L_execdate}_$$.log"

#外部シェル
# 2009/03/04 Ver.1.2 Masayuki.Sano add START
#L_envfile=${L_cmddir}/AZBZZAPPS.env
L_envfile=${L_cmddir}/AZZZAPPS.env
# 2009/03/04 Ver.1.2 Masayuki.Sano add END
#終了ステータス
C_ret_code_err=8
C_ret_code_normal=0

################################################################################
##                                 関数定義                                   ##
################################################################################
### ログ削除処理 ###
log_delete()
{
  if [ -f ${L_logfile} ]
  then
    rm ${L_logfile}
  fi
}

### ログ出力処理 ###
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}

################################################################################
##                                   Main                                     ##
################################################################################
#入力パラメータチェック
if [ -z "${1}" ]
then
  output_log "Parameter Error  parameter1:${1} / parameter2:${2}"
  exit ${C_ret_code_err}
fi
if [ -z "${2}" ]
then
  output_log "Parameter Error  parameter1:${1} / parameter2:${2}"
  exit ${C_ret_code_err}
fi

#外部シェルの読込み
output_log "Reading Shell Env File START"

if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading Shell Env File was Completed"
else
  output_log "Reading Shell Env File was Failed (${L_envfile})"
  exit ${C_ret_code_err}
fi

output_log "Reading Shell Env File END"

#ENVファイルの読込み
output_log "Reading APPS Env File START"

if [ -r ${L_appsora} ]
then
  . ${L_appsora}
  output_log "Reading APPS Env File was Completed"
else
  output_log "Reading APPS Env File was Failed (${L_appsora})"
  exit ${C_ret_code_err}
fi

output_log "Reading APPS Env File END"

# 2009/03/04 Ver.1.1 Koji.Oomata add END

L_pk_request_id_val=$1               #処理順付要求ID
L_status_code=$2                     #更新ステータス

#concsubパラメータ編集
L_conc_args="APPS/APPS"
L_conc_args="${L_conc_args} \"${L_resp_appl}\""
L_conc_args="${L_conc_args} \"${L_resp_name}\""
L_conc_args="${L_conc_args} \"${L_user_name}\""

# 2009/06/17 Ver.1.3 Shigeto.Niki mod START
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
#L_conc_args="${L_conc_args} WAIT=15 CONCURRENT"
L_conc_args="${L_conc_args} WAIT=1 CONCURRENT"
# 2009/03/04 Ver.1.1 Koji.Oomata mod END
# 2009/06/17 Ver.1.3 Shigeto.Niki mod END

L_conc_args="${L_conc_args} \"${L_conc_appl}\""
L_conc_args="${L_conc_args} \"${L_conc_name}\""

NLS_LANG=Japanese_Japan.JA16SJIS
export NLS_LANG

#起動対象コンカレントのパレメータ編集
L_param_args="\"${L_pk_request_id_val}\" \"${L_status_code}\""

#コンカレント起動
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#${FND_TOP}/bin/CONCSUB ${L_conc_args} ${L_param_args}
output_log "Execute CONCSUB START"
${FND_TOP}/bin/CONCSUB ${L_conc_args} ${L_param_args} >>${L_logfile}

# 2009/03/04 Ver.1.1 Koji.Oomata mod END
L_return_code=${?}
if [ ${L_return_code} -ne 0 ]
then
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#  echo "Executing CONCSUB was Failed"
#  L_return_code=8
  output_log "Executing CONCSUB was Failed"
  exit ${C_ret_code_err}
# 2009/03/04 Ver.1.1 Koji.Oomata mod END
fi
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#echo "Execute CONCSUB END"
#exit ${L_return_code}
log_delete
exit ${C_ret_code_normal}
# 2009/03/04 Ver.1.1 Koji.Oomata mod END
