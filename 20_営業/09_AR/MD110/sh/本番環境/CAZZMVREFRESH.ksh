#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : CAZZMVREFRESH                                             ##
## Description      : マテリアライズドビューリフレッシュ機能                    ##
## MD.070           : MD070_IPO_COP_シェル                                      ##
## Version          : 3.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1      マテリアライズドビュー名                                            ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2010/10/13    1.0   S.Niki           新規作成                               ##
##  2014/08/05    1.1   S.Takahashi      リプレース_00004対応                   ##
##  2021/12/21    3.0   S.Takenami       E_本稼動_17774対応(環境依存値の修正)   ##
##                                                                              ##
##################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

# 環境依存値
#2014/08/05 ADD Ver.1.1 by Shota Takahashi START
L_envname=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #シェルの格納ディレクトリ
#2014/08/05 ADD Ver.1.1 by Shota Takahashi END

#2014/08/05 MOD Ver.1.1 by Shota Takahashi START
#L_logpath="/var/log/jp1/T4"                     #ログファイルパス
#2021/12/21 MOD Ver.3.0 by Shun Takenami START
#L_logpath="/var/log/jp1/${L_envname}"           #ログファイルパス
L_logpath="/var/EBS/jp1/${L_envname}/log"       #ログファイルパス
#2021/12/21 MOD Ver.3.0 by Shun Takenami END
#2014/08/05 MOD Ver.1.1 by Shota Takahashi END
C_return_norm=0                                 #正常終了
C_return_error=8                                #異常終了
C_oracle_user="apps"                            #Oracleユーザ
C_oracle_path="apps"                            #Oracleパス

# プログラム情報
L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
#2021/12/21 MOD Ver.3.0 by Shun Takenami START
#L_cmddir=`/bin/dirname ${L_cmd}`
L_cmddir=`/usr/bin/dirname ${L_cmd}`
#2021/12/21 MOD Ver.3.0 by Shun Takenami END
L_hostname=`/bin/hostname`

# 日時
C_date=$(/bin/date "+%Y%m%d%H%M%S") #処理日時
L_execdate=`/bin/date "+%Y%m%d"`    #処理日

L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"
L_envfile=${L_cmddir}/CAZZAPPS.env  #CA共通環境設定ファイル

#===============================================================================
# Description : ログ出力処理
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       ログファイルへ出力する内容
#===============================================================================
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}
#===============================================================================
#                                   Main                                     
#===============================================================================
output_log "Materialized View Refresh Start"

# CA共通ENVファイル読み込み
if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading CA Env File was Completed"
else
  output_log "Reading CA Env File was Failed"
  output_log "Materialized View Refresh Error End"
  exit ${C_return_error}
fi

# 全体共通ENVファイル読み込み
if [ -r ${L_appsora} ]
then
  . ${L_appsora}
  output_log "Reading APPS Env File was Completed"
else
  output_log "Reading APPS Env File was Failed"
  output_log "Materialized View Refresh Error End"
  exit ${C_return_error}
fi

#引数チェック
if [ ${#} -ne 1 ]
then
  output_log "Parameter Error"
  RET_CODE=${C_return_error}
else
  #マテリアライズドビュー名セット
  L_materialized_view_name="${1}"    #チェック対象のファイルパス
  
  #リフレッシュSQL実行
  sqlplus -s ${C_oracle_user}/${C_oracle_path} <<SQLEND >> ${L_logfile}
SET SERVEROUTPUT ON
SET FEEDBACK OFF
VARIABLE refresh_retcode NUMBER;
BEGIN
  DBMS_MVIEW.REFRESH('${L_materialized_view_name}','c');
  :refresh_retcode  := ${C_return_norm};
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE( SQLERRM );
    :refresh_retcode  := ${C_return_error};
END;
/
EXIT :refresh_retcode;
SQLEND

  #SQL戻り値セット
  RET_CODE=`echo $?`
fi

if [ ${RET_CODE} -eq ${C_return_norm} ]
then
  output_log "Materialized View Refresh Normal End"
else
  output_log "Materialized View Refresh Error End"
fi

#終了処理
exit ${RET_CODE}

