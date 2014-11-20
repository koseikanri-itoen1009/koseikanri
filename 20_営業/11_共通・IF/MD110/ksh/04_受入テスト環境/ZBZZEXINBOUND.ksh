#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZEXINBOUND                                             ##
## Description      : EDIシステム用I/F連携機能（INBOUND)                        ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 1.13                                                      ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1       データ種コード                                                     ##
##  $2～36   コンカレント引数1～35                                              ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/27    1.0   Masayuki.Sano    新規作成                               ##
##  2009/02/18    1.1   Masayuki.Sano    結合テスト動作不正対応                 ##
##                                       ･NASサーバディレクトリ取得方法変更     ##
##                                        に伴う対応                            ##
##  2009/02/23    1.2   Masayuki.Sano    結合テスト動作不正対応                 ##
##                                       ･パラメータのファイル⇒フルパスへ変更  ##
##  2009/02/27    1.3   Masayuki.Sano    結合テスト動作不正対応                 ##
##                                       ・SQL Loaderを用いた場合の             ##
##                                         業務コンカレントのパラメータは　　　 ##
##                                         ファイル名にフルパスを指定　　　　　 ##
##                                       ・SQL Loaderを用ない場合の　　　　　　 ##
##                                         業務コンカレントのパラメータは　　　 ##
##                                         ファイル名のみ指定        　　　　　 ##
##  2009/04/03    1.4   Masayuki.Sano    障害番号[T1-0286]                      ##
##                                       ・処理開始時に"AZBZZAPPS.env"を 　　　 ##
##                                         読み込むように修正。                 ##
##  2009/04/06    1.5   Masayuki.Sano    障害番号[T1-0312]                      ##
##                                       ・警告終了を"4"、異常終了を"8"に変更   ##
##  2009/04/07    1.6   Masayuki.Sano    障害番号[T1-0377]                      ##
##                                       ・起動対象コンカレントの引数を変更     ##
##  2009/04/15    1.7   Masayuki.Sano    障害番号[T1-0522]                      ##
##                                       ・要求IDの取得方法変更                 ##
##                                       ・要求IDの取得失敗時、異常処理を追加   ##
##  2009/06/17    1.8   Shigeto.Niki     障害番号[E_PT_00001]                   ##
##                                         CONCSUB要求待ち時間変更              ##
##                                           (デフォルト60秒→1秒)              ##
##  2009/07/17    1.9   Shigeto.Niki     障害番号[E_T3_00341]                   ##
##                                         日本語のパス情報を取得するよう修正   ##
##  2009/08/19    1.10  Masayuki.Sano    障害番号[0000835]                      ##
##                                         一時ファイル名変更                   ##
##  2009/11/25    1.12  Masayuki.Sano    障害番号[E_本稼動_00056]               ##
##                                         SQL-Loader動作不正対応               ##
##  2010/09/21    1.13  Nobuo.Koyama     障害番号[E_本稼動_04934]               ##
##                                         SANサーバファイル存在チェック追加    ##
##                                                                              ##
##################################################################################
                                                                                
#↓本番プログラム

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCCP"           #アプリケーション短縮名
C_program_id="ZBZZEXINBOUND"  #プログラムID
L_logpath="/var/log/jp1/T4"   #ログファイルパス[環境依存値]
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
L_tmppath="/var/tmp"          #一時ファイルパス[環境依存値]
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START

# 戻り値
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 Start
C_ret_code_norm=0     #正常終了
#C_ret_code_warn=3     #警告終了
#C_ret_code_eror=7     #異常終了
C_ret_code_warn=4     #警告終了
C_ret_code_eror=8     #異常終了
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 End
# 2010/09/21 Ver.1.13 Nobuo.Koyama Add Start
C_ret_code_nofile=5   #SANファイルなし終了
# 2010/09/21 Ver.1.13 Nobuo.Koyama Add End

# 日時
C_date=$(/bin/date "+%Y%m%d%H%M%S") #処理日時
L_execdate=`/bin/date "+%Y%m%d"`    #処理日

# プログラム情報
L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`

#外部シェル(設定関連)パス
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#L_envfile=${L_cmddir}/AZBZZAPPS.env
L_envfile=${L_cmddir}/ZBZZAPPS2.env
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

#ログファイル関連
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"

# 2009/08/19 Ver1.10 Mod START
##一時ファイル
##2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
##L_tmpbase=/var/tmp/${L_cmdname}.$$
#L_tmpbase="${L_tmppath}/${L_cmdname}.$$"
##2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
#L_std_out=${L_tmpbase}.stdout
#L_err_out=${L_tmpbase}.errout
#L_path_ou_sldr="${L_tmpbase}.${C_date}.ctl"
#L_path_sql_log="${L_tmpbase}.${C_date}.log"
##2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
##SQL-Loaderログファイルパス
#L_path_log_sldr="/var/tmp/`/bin/basename ${L_cmdname} .ksh`_$$_${C_date}.log"
#一時ファイル一覧
L_tmpbase="${L_cmdname}.${C_date}.$$"
L_std_out=${L_tmppath}/${L_tmpbase}.stdout.tmp        #一時ファイル（正常）
L_err_out=${L_tmppath}/${L_tmpbase}.errout.tmp        #一時ファイル（異常）
L_path_sql_log="${L_tmppath}/${L_tmpbase}.log.tmp"    #一時ファイル（SQL関連)
L_path_ou_sldr="${L_tmppath}/${L_tmpbase}.ctl.tmp"    #SQL-Loader制御ファイル
# 2009/08/19 Ver1.10 Mod End
#エラーメッセージ一覧
C_log_msg_00001="Parameter Error"
C_log_msg_00002="設定情報の値が不正です。（アプリケーション短縮名(職責)）"
C_log_msg_00003="設定情報の値が不正です。（職責名）"
C_log_msg_00004="設定情報の値が不正です。（ユーザ名）"
C_log_msg_00005="設定情報の値が不正です。（アプリケーション短縮名(コンカレント)）"
C_log_msg_00006="設定情報の値が不正です。（コンカレント短縮名）"
C_log_msg_00007="設定情報の値が不正です。（オブジェクトディレクトリ名(NASサーバ)）"
C_log_msg_00008="設定情報の値が不正です。（ローカルサーバディレクトリパス）"
C_log_msg_00009="設定情報の値が不正です。（退避先ディレクトリパス）"
C_log_msg_00010="設定情報の値が不正です。（世代数）"
C_log_msg_00011="設定情報の値が不正です。（SQL実行フラグ）"
C_log_msg_00012="設定情報の値が不正です。（SQL-Loader制御ファイルパス）"
C_log_msg_00013="設定情報の値が不正です。（ワークテーブル名）"
C_log_msg_00014="設定情報の値が不正です。（削除SQL処理区分）"
C_log_msg_00015="NASサーバディリレクトリパスが取得できませんでした。"
C_log_msg_00016="NASサーバに実行対象のファイルが存在します。"
C_log_msg_00017="NASサーバへのI/Fファイルのコピーに失敗しました。"
C_log_msg_00018="ローカルサーバ内のI/Fファイルの削除に失敗しました。"
C_log_msg_00019="SQL-Loaderの実行に失敗しました。"
C_log_msg_00020="NASサーバ内のI/Fファイルの削除に失敗しました。"
C_log_msg_00021="ワークテーブルのデータ削除に失敗しました。"
C_log_msg_00022="IFファイル退避先ディレクトリへの移動に失敗しました。"
C_log_msg_00023="退避先ディレクトリ内のバックアップファイルの削除に失敗しました。"
# 2010/09/21 Ver.1.13 Nobuo.Koyama Add Start
C_log_msg_00024="SANサーバに実行対象のファイルが存在しません。"
# 2010/09/21 Ver.1.13 Nobuo.Koyama Add End
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START

################################################################################
##                                 関数定義                                   ##
################################################################################

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
#2009/11/25 MOD Ver.1.12 Start
#  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
  echo $$-`date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
#2009/11/25 MOD Ver.1.12 End
}

#===============================================================================
# Description : 終了処理
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       リターン・コード
#===============================================================================
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
  return ${L_retcode}
}

#===============================================================================
# Description : EBSコンカレントを起動する。
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       職責アプリケーション短縮名
#  $2       職責名
#  $3       APPSユーザ名
#  $4       コンカレントアプリケーション短縮名
#  $5       コンカレントプログラム名
#  $6～$41  コンカレントパラメータ ※最大35個
#===============================================================================
AZBZZEXECONCSUB()
{
#2009/04/03 DELETE BY Masayuki.Sano Ver.1.4 Start
#  #ログファイルの最終アクセス日時と最終更新日時を処理日に更新
#  touch ${L_logfile}
#  output_log "`/bin/basename ${0}` START"
#
#  #----------------------------------------------------------------------------
#  #EBS関連の定義情報を取得
#  #----------------------------------------------------------------------------
#  #職責などのデフォルト値を取得
#  #・実行ファイルが存在しない⇒戻り値(7)をセットして処理終了
#  output_log "Reading Shell Env File START"
#  if [ -r ${L_envfile} ]
#  then
#    . ${L_envfile}
#    output_log "Reading Shell Env File was Completed"
#  else
#    output_log "Reading Shell Env File was Failed"
#    shell_end ${C_ret_code_eror}
#    return ${?}
#  fi
#  output_log "Reading Shell Env File END"
#
#  #EBS関連の定義情報を取得
#  #・実行ファイルが存在しない⇒戻り値(7)をセットして処理終了
#  output_log "Reading APPS Env File START"
#  if [ -r ${L_appsora} ]
#  then
#    . ${L_appsora}
#    output_log "Reading APPS Env File was Completed"
#  else
#    output_log "Reading APPS Env File was Failed"
#    shell_end ${C_ret_code_eror}
#    return ${?}
#  fi
#  output_log "Reading APPS Env File END"
#2009/04/03 DELETE BY Masayuki.Sano Ver.1.4 End

  #----------------------------------------------------------------------------
  #コンカレント（I/Fファイルのヘッダ・フッタ削除、業務用コンカレント）を実行
  #----------------------------------------------------------------------------
  #パラメータ数をチェック
  #・5未満⇒異常終了の戻り値（7）をセットして、処理終了
  L_paracount=${#}

  if [ $L_paracount -lt 5 ]
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
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    shell_end ${C_ret_code_eror}
#    return ${?}
    return ${C_ret_code_eror}
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano END
  fi

  #入力パラメータからコンカレント情報を取得
  L_para_appl=${1}  # 職責のアプリケーション短縮名
  L_para_resp=${2}  # 職責名
  L_para_user=${3}  # APPユーザ名
  L_conc_appl=${4}  # コンカレントのアプリケーション短縮名
  L_conc_name=${5}  # コンカレント短縮名
  shift 5

  #職責のアプリケーション短縮名、職責名、APPユーザ名が未入力の場合、デフォルト値を設定
  #(職責のアプリケーション短縮名)
  if [ "${L_para_appl}" != \"\" ]
  then
    L_resp_appl=${L_para_appl}
  else
    L_resp_appl=${L_def_appl}
  fi
  #(職責名)
  if [ "${L_para_resp}" != \"\" ]
  then
    L_resp_name=${L_para_resp}
  else
    L_resp_name=${L_def_resp}
  fi
  #(APPユーザ名)
  if [ "${L_para_user}" != \"\" ]
  then
    L_user_name=${L_para_user}
  else
    L_user_name=${L_def_user}
  fi

  #SUBCONCを実施するためのパラメータをセットする。
  L_conc_args="APPS/APPS"
  L_conc_args="${L_conc_args} \"${L_resp_appl}\""
  L_conc_args="${L_conc_args} \"${L_resp_name}\""
  L_conc_args="${L_conc_args} \"${L_user_name}\""

  # 2009/06/17 Ver.1.8 Shigeto.Niki mod START
  #L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
  L_conc_args="${L_conc_args} WAIT=1 CONCURRENT"
  # 2009/06/17 Ver.1.8 Shigeto.Niki mod END

  L_conc_args="${L_conc_args} \"${L_conc_appl}\""
  L_conc_args="${L_conc_args} \"${L_conc_name}\""

  #言語コードを日本語に変更
  NLS_LANG=Japanese_Japan.JA16SJIS
  export NLS_LANG

  #SUBCONC(EBSコンカレントを起動するためのプログラム)を起動
  #・パラメータ不正による異常終了⇒異常終了の戻り値（7）をセットして、処理終了
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
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    shell_end ${C_ret_code_eror}
#    return ${?}
    return ${C_ret_code_eror}
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano END
  fi

  #----------------------------------------------------------------------------
  #SUBCONCの標準出力から、要求IDを取得
  #----------------------------------------------------------------------------
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#  if [ $L_paracount = 5 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $5}' ${L_std_out}`   # コンカレントパラメータ数：0
#  elif [ $L_paracount = 6 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $6}' ${L_std_out}`   # コンカレントパラメータ数：1
#  elif [ $L_paracount = 7 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $7}' ${L_std_out}`   # コンカレントパラメータ数：2
#  elif [ $L_paracount = 8 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $8}' ${L_std_out}`   # コンカレントパラメータ数：3
#  elif [ $L_paracount = 9 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $9}' ${L_std_out}`   # コンカレントパラメータ数：4
#  elif [ $L_paracount = 10 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $10}' ${L_std_out}`  # コンカレントパラメータ数：5
#  elif [ $L_paracount = 11 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $11}' ${L_std_out}`  # コンカレントパラメータ数：6
#  elif [ $L_paracount = 12 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $12}' ${L_std_out}`  # コンカレントパラメータ数：7
#  elif [ $L_paracount = 13 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $13}' ${L_std_out}`  # コンカレントパラメータ数：8
#  elif [ $L_paracount = 14 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $14}' ${L_std_out}`  # コンカレントパラメータ数：9
#  elif [ $L_paracount = 15 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $15}' ${L_std_out}`  # コンカレントパラメータ数：10
#  elif [ $L_paracount = 16 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $16}' ${L_std_out}`  # コンカレントパラメータ数：11
#  elif [ $L_paracount = 17 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $17}' ${L_std_out}`  # コンカレントパラメータ数：12
#  elif [ $L_paracount = 18 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $18}' ${L_std_out}`  # コンカレントパラメータ数：13
#  elif [ $L_paracount = 19 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $19}' ${L_std_out}`  # コンカレントパラメータ数：14
#  elif [ $L_paracount = 20 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $20}' ${L_std_out}`  # コンカレントパラメータ数：15
#  elif [ $L_paracount = 21 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $21}' ${L_std_out}`  # コンカレントパラメータ数：16
#  elif [ $L_paracount = 22 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $22}' ${L_std_out}`  # コンカレントパラメータ数：17
#  elif [ $L_paracount = 23 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $23}' ${L_std_out}`  # コンカレントパラメータ数：18
#  elif [ $L_paracount = 24 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $24}' ${L_std_out}`  # コンカレントパラメータ数：19
#  elif [ $L_paracount = 25 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $25}' ${L_std_out}`  # コンカレントパラメータ数：20
#  elif [ $L_paracount = 26 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $26}' ${L_std_out}`  # コンカレントパラメータ数：21
#  elif [ $L_paracount = 27 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $27}' ${L_std_out}`  # コンカレントパラメータ数：22
#  elif [ $L_paracount = 28 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $28}' ${L_std_out}`  # コンカレントパラメータ数：23
#  elif [ $L_paracount = 29 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $29}' ${L_std_out}`  # コンカレントパラメータ数：24
#  elif [ $L_paracount = 30 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $30}' ${L_std_out}`  # コンカレントパラメータ数：25
#  elif [ $L_paracount = 31 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $31}' ${L_std_out}`  # コンカレントパラメータ数：26
#  elif [ $L_paracount = 32 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $32}' ${L_std_out}`  # コンカレントパラメータ数：27
#  elif [ $L_paracount = 33 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $33}' ${L_std_out}`  # コンカレントパラメータ数：28
#  elif [ $L_paracount = 34 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $34}' ${L_std_out}`  # コンカレントパラメータ数：29
#  elif [ $L_paracount = 35 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $35}' ${L_std_out}`  # コンカレントパラメータ数：30
#  elif [ $L_paracount = 36 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $36}' ${L_std_out}`  # コンカレントパラメータ数：31
#  elif [ $L_paracount = 37 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $37}' ${L_std_out}`  # コンカレントパラメータ数：32
#  elif [ $L_paracount = 38 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $38}' ${L_std_out}`  # コンカレントパラメータ数：33
#  elif [ $L_paracount = 39 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $39}' ${L_std_out}`  # コンカレントパラメータ数：34
#  elif [ $L_paracount = 40 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $40}' ${L_std_out}`  # コンカレントパラメータ数：35
#  else
#    L_reqid=""
#  fi
  # 要求IDの取得
  L_reqid=`/usr/bin/awk 'NR==1 {print $3}' ${L_std_out}`
  # 要求IDのチェック
  if [ "$(echo ${L_reqid} | egrep '^[0-9]+$')" = "" ]
  then
    output_log "Getting RequestID was Failed(RequestID : ${L_reqid} )"
    return ${C_ret_code_eror}
  fi
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

  L_out_all=`/usr/bin/awk '{print $0}' ${L_std_out}`
  output_log "RequestID : ${L_reqid}"

  output_log "Execute CONCSUB END"

  #----------------------------------------------------------------------------
  #要求IDをキーに"ステータス・コード"を取得
  #ステータス・コードをチェック("C":正常 "G":警告 "左記以外"：異常)
  #----------------------------------------------------------------------------
  #コンカレントの詳細情報（ステータスコード等)を取得するSQLの実行(キー:要求ID)
# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END
  output_log "Getting Concurrent Status START"
  sqlplus -s apps/apps <<SQLEND >${L_std_out}
  SET HEADING OFF
  SELECT request_id, phase_code, status_code
  FROM fnd_concurrent_requests
  WHERE request_id = '${L_reqid}';
  EXIT
SQLEND
  #実行結果からコンカレントの詳細情報（ステータスコード等)を取得
  L_get_req_id=`/usr/bin/awk '( $0 != "" ){print $1}' ${L_std_out}`
  L_phase_code=`/usr/bin/awk '( $0 != "" ){print $2}' ${L_std_out}`
  L_status_code=`/usr/bin/awk '( $0 != "" ){print $3}' ${L_std_out}`

  output_log RequestID : $L_get_req_id Phase_Code : $L_phase_code Status Code : $L_status_code

  output_log "Getting Concurrent Status END"

  #ステータス・コードをチェック
  #     "C"：正常(Normal)
  #　　 "G"：警告(Warning)
  #上記以外：異常(Other(Error/Unknown))
  case ${L_status_code} in
  C)
    # Normal
    output_log "Concurrent Status was normal"
    L_exit_status=$C_ret_code_norm
    ;;
  G)
    # Warning
    output_log "Concurrent Status was warning"
    L_exit_status=$C_ret_code_warn
    ;;
  *)
    # Other(Error/Unknown)
    output_log "Concurrent Status was error"
    L_exit_status=$C_ret_code_eror
    ;;
  esac

  ### Shell end ###
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#  shell_end $L_exit_status
#  return ${?}
  return ${L_exit_status}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

}
#===============================================================================
# Description : 設定情報の取得(データベースから設定情報を取得後、
#             : 正しい値かチェックを行う。
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.      Description
# -------- ----------------------------------------------------------
#   $1     データ種コード
#===============================================================================
FLEX_VALUES_GET()
{
  #----------------------------------------------------------------------------
  # 1) 本シェルで使用する設定情報を取得します。
  #----------------------------------------------------------------------------
# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END
  sqlplus -s apps/apps <<GETSQL > ${L_std_out}
    SET HEADING OFF
    SET TRIMSPOOL ON
    SET FEEDBACK OFF
    SELECT ffva.flex_value || ',' || ffva.description
    FROM   fnd_flex_values_vl ffva
          ,fnd_flex_vset_v    ffvs
    WHERE  ffvs.flex_value_set_id = ffva.flex_value_set_id  
    AND    ffvs.parent_value_set_name = 'XXCCP1_IF_CONF_PARA'
    AND    ffva.flex_value IN ('${1}_arg_001','${1}_arg_002','${1}_arg_003',
                               '${1}_arg_004','${1}_arg_005','${1}_arg_006',
                               '${1}_arg_007','${1}_arg_008','${1}_arg_009',
                               '${1}_arg_010','${1}_arg_011','${1}_arg_012',
                               '${1}_arg_013')
    AND    SYSDATE BETWEEN NVL(ffva.start_date_active, SYSDATE)
                       AND NVL(ffva.end_date_active,   TO_DATE('9999/12/31','YYYY/MM/DD'))
    AND    ffva.enabled_flag='Y'
    ;
    EXIT
GETSQL

  #----------------------------------------------------------------------------
  #2) 上記SQLの実行結果からシェルの設定情報を取得します。
  #----------------------------------------------------------------------------
  G_resp_app_name=`sed -n "s/${1}_arg_001,//p" "${L_std_out}"`          #職責アプリケーション短縮名
  G_resp_name=`sed -n "s/${1}_arg_002,//p" "${L_std_out}"`              #職責名
  G_user_name=`sed -n "s/${1}_arg_003,//p" "${L_std_out}"`              #APPSユーザ名
  G_con_app_name=`sed -n "s/${1}_arg_004,//p" "${L_std_out}"`           #コンカレントアプリケーション短縮名
  G_con_name=`sed -n "s/${1}_arg_005,//p" "${L_std_out}"`               #コンカレント名
#2009/02/18 UPDATE BY M.Sano 結合テスト動作不正対応 START
#  G_dire_nas=`sed -n "s/${1}_arg_006,//p" "${L_std_out}"`               #NASサーバディレクトリ
  G_dir_name_nas=`sed -n "s/${1}_arg_006,//p" "${L_std_out}"`           #オブジェクトディレクトリ名(NASサーバ)
#2009/02/18 UPDATE BY M.Sano 結合テスト動作不正対応 END
  G_dire_san=`sed -n "s/${1}_arg_007,//p" "${L_std_out}"`               #SANサーバディレクトリ
  G_drie_esc=`sed -n "s/${1}_arg_008,//p" "${L_std_out}"`               #退避用ディレクトリ
  G_gene_num=`sed -n "s/${1}_arg_009,//p" "${L_std_out}"`               #世代数
  G_flag_sldr=`sed -n "s/${1}_arg_010,//p" "${L_std_out}"`              #SQL実行フラグ
  G_path_sldr=`sed -n "s/${1}_arg_011,//p" "${L_std_out}"`              #SQL-Loader制御ファイルパス
  G_del_tbl_name=`sed -n "s/${1}_arg_012,//p" "${L_std_out}"`           #ワークテーブル名
  G_del_sql_type=`sed -n "s/${1}_arg_013,//p" "${L_std_out}"`           #削除SQL処理区分

  #----------------------------------------------------------------------------
  #3) 一時ファイルを削除
  #----------------------------------------------------------------------------
  rm -f "${L_std_out}"

  #----------------------------------------------------------------------------
  #4) 取得したデータが正しい入力かチェックします。
  #----------------------------------------------------------------------------
  #職責アプリケーション短縮名のチェック(必須チェック)
  if [ "${G_resp_app_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00002}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #職責名のチェック(必須チェック)
  if [ "${G_resp_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00003}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #APPSユーザ名のチェック(必須チェック)
  if [ "${G_user_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00004}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #コンカレントアプリケーション短縮名のチェック(必須チェック)
  if [ "${G_con_app_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00005}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #コンカレント名のチェック(必須チェック)
  if [ "${G_con_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00006}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
#2009/02/18 UPDATE BY M.Sano 結合テスト動作不正対応 START
#  #NASサーバディレクトリのチェック(ディレクトリ存在チェック)
#  if [ ! -d "${G_dire_nas}" ]
#  then
#    return ${C_ret_code_eror}
#  fi
  #オブジェクトディレクトリ名(NASサーバ)のチェック(必須チェック)
  if [ "${G_dir_name_nas}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00007}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
#2009/02/18 ADD BY M.Sano 結合テスト動作不正対応 END

  #SANサーバディレクトリのチェック(ディレクトリ存在チェック)
  if [ ! -d "${G_dire_san}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00008}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #退避用ディレクトリのチェック(ディレクトリ存在チェック)
  if [ ! -d "${G_drie_esc}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00009}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #世代数のチェック(数値有無チェック)
  if [ "$(echo ${G_gene_num} | egrep '^[0-9]+$')" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00010}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #世代数のチェック(範囲チェック)
  if [ ${G_gene_num} -lt 1 ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00010}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #SQL実行フラグのチェック("0"または"1")
  if [ "${G_flag_sldr}" = "1" ] || [ "${G_flag_sldr}" = "0" ]
  then
  :
  else
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00011}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #SQL-Loader制御ファイルパスのチェック(必須チェック ※SQL実行フラグ="1"の場合のみ)
  if [ "${G_flag_sldr}" = "1" ] && [ ! -f "${G_path_sldr}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00012}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #ワークテーブル名のチェック(必須チェック ※SQL実行フラグ="1"の場合のみ)
  if [ "${G_flag_sldr}" = "1" ] && [ "${G_del_tbl_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00013}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #削除SQL処理区分のチェック("0"または"1"  ※SQL実行フラグ="1"の場合のみ)
  if [ "${G_flag_sldr}" = "1" ]
  then
    if [ "${G_del_sql_type}" != "1" ] && [ "${G_del_sql_type}" != "0" ]
    then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
      output_log "${C_log_msg_00014}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      return ${C_ret_code_eror}
    fi
  fi

#2009/02/18 ADD BY M.Sano 結合テスト動作不正対応 START

# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END
  #----------------------------------------------------------------------------
  #5) 本シェルで使用するディレクトリ情報を取得します。
  #----------------------------------------------------------------------------
  #SQLの実行
  sqlplus -s apps/apps <<GETSQL >> ${L_std_out}
    SET HEADING OFF
    SET TRIMSPOOL ON
    SET FEEDBACK OFF
    SELECT 'nas_directory_path,' || adir.directory_path
    FROM   all_directories adir
    WHERE  adir.directory_name = '${G_dir_name_nas}'
    ;
    EXIT
GETSQL
  #NASサーバディレクトリの取得
  G_dire_nas=`sed -n "s/nas_directory_path,//p" "${L_std_out}"`
  #一時ファイル削除
  rm -f "${L_std_out}"

  #----------------------------------------------------------------------------
  #6) 取得したディレクトリが存在するディレクトリかどうかチェックを行います。
  #----------------------------------------------------------------------------
  if [ ! -d "${G_dire_nas}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.SanoSTART
    output_log "${C_log_msg_00015}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

#2009/02/18 ADD BY M.Sano 結合テスト動作不正対応 END

  return ${C_ret_code_norm}
}
#===============================================================================
# Description : I/F連携ヘッダーフッター削除コンカレントを起動
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#   $1     ファイル名
#   $2     システム名
#   $3     オブジェクトディレクトリ名
#===============================================================================
XXCCP005A01C_EXECUTE()
{
  #ディレクトリ名を取得する。
#2009/02/18 DELETE BY M.Sano 結合テスト動作不正対応 START
#  L_nas_dir_name=`echo "${3}" | sed -e 's/^.*\///' | tr [a-z] [A-Z]`
#2009/02/18 DELETE BY M.Sano 結合テスト動作不正対応 START

  #引数を作成
  L_ksh_para="${G_resp_app_name}"                   #アプリケーション短縮名(職責)
  L_ksh_para="${L_ksh_para} ${G_resp_name}"         #職責名
  L_ksh_para="${L_ksh_para} ${G_user_name}"         #ユーザ名
  L_ksh_para="${L_ksh_para} XXCCP"                  #アプリケーション短縮名(コンカレント)
  L_ksh_para="${L_ksh_para} XXCCP005A01C"           #コンカレント短縮名
  L_ksh_para="${L_ksh_para} \"${1}\""               #ファイル名
  L_ksh_para="${L_ksh_para} \"${2}\""               #システム名
#2009/02/18 UPDATE BY M.Sano 結合テスト動作不正対応 START
#  L_ksh_para="${L_ksh_para} \"${L_nas_dir_name}\""  #削除ディレクトリ名
  L_ksh_para="${L_ksh_para} \"${3}\""               #削除ディレクトリ名
#2009/02/18 UPDATE BY M.Sano 結合テスト動作不正対応 END
  #EBS共通コンカレント起動シェル経由でヘッダーフッター削除コンカレント実行
  AZBZZEXECONCSUB ${L_ksh_para}
  return ${?}

}

#===============================================================================
# Description : SQL-Loaderを実行する。(対象データ：I/Fファイル(NAS))
#===============================================================================
SQL_LOADER_EXECUTE()
{
  #"???????????"をI/Fファイルパスへ置換 結果は一時ファイルへ格納
  G_path_nas_tmp=`echo "${G_path_nas}" | sed 's/\\//\\\\\\//g'`
  sed -e 's/\?\?\?\?\?\?\?\?\?\?\?/'"${G_path_nas_tmp}"'/g' "${G_path_sldr}" > "${L_path_ou_sldr}"

# 2009/08/19 Ver1.10 Add START
  #SQL-Loader実行ログのパスを取得
  L_path_log_sldr="${L_tmppath}/${G_base_if}_${C_date}_$$.log.tmp"
# 2009/08/19 Ver1.10 Add End

  #SQL-Loader実行
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#  sqlldr userid=apps/apps control="${L_path_ou_sldr}" errors=0 > "${L_path_sql_log}"
#  L_ret_code=${?}
# 2009/08/19 Ver1.10 Del START
#  #(SQL-Loader実行ログのパスを取得)
#  L_path_log_sldr="${L_tmppath}/${G_base_if}_${C_date}.log"
# 2009/08/19 Ver1.10 Del END
  sqlldr userid=apps/apps control="${L_path_ou_sldr}" log="${L_path_log_sldr}" errors=0 > ${L_path_sql_log} 2>${L_err_out}
  L_ret_code=${?}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  #SQL-Loaderが成功したかどうかチェックを行なう。
  #成功時 ⇒ SQL-Loaderログファイルを削除
  #失敗時 ⇒ ログファイルにエラーメッセージを出力。
  if [ ${L_ret_code} -eq 0 ]
  then
    rm -f "${L_path_log_sldr}"
  else
    output_log "${C_log_msg_00019}"
  fi
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END

  #一時ファイルを削除
  rm -f "${L_path_ou_sldr}"
  rm -f "${L_path_sql_log}"

  return ${L_ret_code}
}

#===============================================================================
# Description : 業務用コンカレントを起動
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       データ種コード
#  $2～$36  コンカレント引数
#===============================================================================
#CONCURRENT_EXECUTE()
#{
#  #パラメータを作成する
#  L_ksh_para="${G_resp_app_name}"                 #アプリケーション短縮名(職責)
#  L_ksh_para="${L_ksh_para} ${G_resp_name}"       #職責名
#  L_ksh_para="${L_ksh_para} ${G_user_name}"       #ユーザ名
#  L_ksh_para="${L_ksh_para} ${G_con_app_name}"    #アプリケーション短縮名(コンカレント)
#  L_ksh_para="${L_ksh_para} ${G_con_name}"        #コンカレント短縮名
#  L_set_para_flag=0
#  for L_file in "${@}"
#  do
##2009/02/23 UPDATE BY M.Sano 結合テスト動作不正対応 START
##    if [ L_set_para_flag -eq 1 ]
##    then
##      L_ksh_para="${L_ksh_para} \"${L_file}\""      #コンカレントパラメータ
##    fi
##    L_set_para_flag=1
#    if [ L_set_para_flag -eq 0 ]
#    then
#      L_set_para_flag=1
#    elif [ L_set_para_flag -eq 1 ]
#    then
#      L_ksh_para="${L_ksh_para} \"${G_path_nas}\""            #I/Fファイルパス(NASサーバ)
#      L_set_para_flag=2
#    else
#      L_ksh_para="${L_ksh_para} \"${L_file}\""                #コンカレントパラメータ
#    fi
##2009/02/23 UPDATE BY M.Sano 結合テスト動作不正対応 START
#  done
#  #EBS共通コンカレント起動シェル経由で業務コンカレント実行する
#  AZBZZEXECONCSUB ${L_ksh_para}
#  return ${?}
#}

#===============================================================================
# Description : SQL-Loaderにて格納したデータを削除する。
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       データ種コード
#===============================================================================
SQL_LOADER_DELETE()
{
# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END

  #SQL Loader取り込みデータ削除(削除SQL処理区分＝"1")
  if [ ${G_del_sql_type} = "1" ]
  then
    sqlplus -s apps/apps <<DELSQL1 >${L_path_sql_log}
      WHENEVER SQLERROR EXIT FAILURE ROLLBACK
      DELETE
      FROM   ${G_del_tbl_name}
      WHERE  if_file_name='${1}'
      AND    err_status='0'
      ;
      COMMIT;
      EXIT 0
DELSQL1
    L_ret_code=${?}
  #SQL Loader取り込みデータ削除(削除SQL処理区分≠"1")
  else
    sqlplus -s apps/apps <<DELSQL2 >${L_path_sql_log}
      WHENEVER SQLERROR EXIT FAILURE ROLLBACK
      DELETE
      FROM   ${G_del_tbl_name}
      WHERE  if_file_name='${1}'
      ;
      COMMIT;
      EXIT 0
DELSQL2
    L_ret_code=${?}
  fi

  #一時ファイルを削除
  rm -f "${L_path_sql_log}"

  #実行結果の戻り値を返す
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 Start
#  return ${L_ret_code}
  if [ ${L_ret_code} -ne 0 ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00021}(${G_del_tbl_name})"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  return ${C_ret_code_norm}
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 End
}

#===============================================================================
# Description : I/FファイルをNASサーバディレクトリ(G_path_nas)から
#             : 退避先ディレクトリ(G_path_esc)へ退避する
#===============================================================================
FILE_ESCAPE()
{
  L_cnt=0   #カウント変数

  #退避先ディレクトリへ移動
  mv -f "${G_path_nas}" "${G_path_esc}"
  L_ret_code=${?}
  if [ ${L_ret_code} -ne 0 ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00022}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #バックアップファイルの削除
  for L_file in $(ls -1r "${G_drie_esc}" | egrep -x "${G_base_if}_[0-9]{14}\.${G_exte_if}")
  do
    let L_cnt=${L_cnt}+1
    if [ ${G_gene_num} -lt ${L_cnt} ]
    then
      rm -f "${G_drie_esc}/${L_file}"
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#      L_ret_code=${?}
#      if [ ${L_ret_code} -ne 0 ]
#      then
      if [ -f "${G_drie_esc}/${L_file}" ]
      then
        output_log "${C_log_msg_00023}"
        return ${C_ret_code_eror}
      fi
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
    fi
  done
  return ${C_ret_code_norm}
}

################################################################################
##                                   Main                                     ##
################################################################################

#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
touch ${L_logfile}
output_log "`/bin/basename ${0}` START"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
#===============================================================================
#1.入力パラメータ数のチェック
#===============================================================================
# 1) 入力パラメータ数チェック
if [ ${#} -lt 2 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  output_log "${C_log_msg_00001}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
# 2) 入力パラメータをログファイルへ出力
output_log "Input Parameter"
let L_cnt=0
for L_para in ${@}
do
  let L_cnt=${L_cnt}+1
  output_log '$'"${L_cnt} : ${L_para}"
done
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END

#2009/04/03 ADD BY Masayuki.Sano Ver.1.4 Start
#===============================================================================
#1-1.外部設定ファイル(AZBZZAPPS.env)読込処理
#===============================================================================
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano START
##ログファイルの最終アクセス日時と最終更新日時を処理日に更新
#touch ${L_logfile}
#output_log "`/bin/basename ${0}` START"
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano END
#"AZBZZAPPS.env"を実行
#・"AZBZZAPPS.env"がない⇒戻り値(7)をセットして処理終了
output_log "Reading Shell Env File START"
if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading Shell Env File was Completed"
else
  output_log "Reading Shell Env File was Failed"
  shell_end ${C_ret_code_eror}
  return ${?}
fi
output_log "Reading Shell Env File END"

#"APPSORA.env"を実行
#・"APPSORA.env"がない⇒戻り値(7)をセットして処理終了
output_log "Reading APPS Env File START"
if [ -r ${L_appsora} ]
then
  . ${L_appsora}
  output_log "Reading APPS Env File was Completed"
else
  output_log "Reading APPS Env File was Failed"
  shell_end ${C_ret_code_eror}
  return ${?}
fi
output_log "Reading APPS Env File END"
#2009/04/03 ADD BY Masayuki.Sano Ver.1.4 End

#===============================================================================
#2.設定情報の取得
#===============================================================================
#値セットテーブルからデータ種コードに紐づくデータを取得
#・異常終了⇒戻り値(7)をセットして処理終了
FLEX_VALUES_GET "${1}"
L_ret_code=${?}
if [ ${L_ret_code} -ne 0 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#3.データの作成
#※データ：入力パラメータ、２で取得した設定情報
#===============================================================================
#(ファイル情報を取得)
G_base_if=$(echo "${2}" | sed -e 's/\.[^.]*$//')                #I/Fファイルのベース名
G_exte_if=$(echo "${2}" | sed -e 's/^'"${G_base_if}"'\.//')     #I/Fファイルの拡張子名
G_path_san="${G_dire_san}/${2}"                                 #I/Fファイル(SANサーバ)パス
G_path_nas="${G_dire_nas}/${2}"                                 #I/Fファイル(NASサーバ)パス
G_path_esc="${G_drie_esc}/${G_base_if}_${C_date}.${G_exte_if}"  #I/Fファイル(退避用)パス

# 2010/09/21 Ver.1.13 Nobuo.Koyama Add Start
#===============================================================================
#4.I/Fファイル（SANサーバ）の存在チェック
#===============================================================================
#SANサーバへI/Fファイルが存在するかチェックする
#・存在しない⇒戻り値(5)をセットして処理終了
if [ ! -f "${G_path_san}" ]
then
  output_log "${C_log_msg_00024}"
  shell_end ${C_ret_code_nofile}
  exit ${C_ret_code_nofile}
fi
# 2010/09/21 Ver.1.13 Nobuo.Koyama Add End

#===============================================================================
#4.I/Fファイル（NASサーバ）の存在チェック
#===============================================================================
#SNASサーバへI/Fファイルが存在するかチェックする
#・存在する⇒戻り値(7)をセットして処理終了
if [ -f "${G_path_nas}" ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  output_log "${C_log_msg_00016}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#5.I/Fファイル（NASサーバ）へのコピー
#===============================================================================
#SANサーバ内からNASサーバへI/Fファイルをコピー
#・異常終了⇒戻り値(7)をセットして処理終了
cp -pf "${G_path_san}" "${G_path_nas}"
L_ret_code=${?}
if [ ${L_ret_code} -ne 0 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  output_log "${C_log_msg_00017}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#6.I/Fファイル（SANサーバ）の削除
#===============================================================================
#SANサーバ内のI/Fファイルを削除
#・異常終了⇒戻り値(7)をセットして処理終了
rm -f "${G_path_san}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
#L_ret_code=${?}
#if [ ${L_ret_code} -ne 0 ]
#then
if [ -f "${G_path_san}" ]
then
  output_log "${C_log_msg_00018}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#7.I/F連携ヘッダーフッター削除コンカレント起動
#===============================================================================
#I/F連携ヘッダーフッター削除コンカレント起動
#・異常終了⇒EBS共通コンカレント起動シェルの戻り値をセットして処理終了
#2009/02/18 UPDATE BY M.Sano 結合テスト動作不正対応 START
#XXCCP005A01C_EXECUTE "${2}" "EDI" "${G_dire_nas}"
#L_exit_code=${?}
XXCCP005A01C_EXECUTE "${2}" "EDI" "${G_dir_name_nas}"
L_exit_code=${?}
#2009/02/18 UPDATE BY M.Sano 結合テスト動作不正対応 END
if [ ${L_exit_code} -ne 0 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  shell_end ${L_exit_code}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${L_exit_code}
fi

#===============================================================================
#8.業務コンカレント起動（SQL Loader使用）
#  ※実行条件：SQL-Loader実行フラグ＝"1"
#===============================================================================
if [ "${G_flag_sldr}" = "1" ]
then
  #----------------------------------------------------------------------------
  #【SQL Loader処理】
  #----------------------------------------------------------------------------
  SQL_LOADER_EXECUTE
  L_ret_code=${?}

  #----------------------------------------------------------------------------
  #【SQL Loader処理】が正常に処理できた場合
  #----------------------------------------------------------------------------
  if [ ${L_ret_code} -eq 0 ]
  then
    #NASサーバディレクトリ内のファイル削除
    #・異常終了→戻り値(7)をセットして処理終了
    rm -f "${G_path_nas}"
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    L_ret_code=${?}
#    if [ ${L_ret_code} -ne 0 ]
#    then
    if [ -f "${G_path_nas}" ]
    then
      output_log "${C_log_msg_00020}"
      shell_end ${C_ret_code_eror}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

#2009/02/27 UPDATE BY M.Sano 結合テスト動作不正対応 START
#    #業務コンカレント起動
#    #・異常終了→EBS共通コンカレント起動シェルの戻り値をセットして処理終了
#    CONCURRENT_EXECUTE "${@}"
#    L_exit_code=${?}
#    if [ ${L_exit_code} -ne 0 ]
#    then
#      exit ${L_exit_code}
#    fi
    #業務コンカレント用パラメータを作成する
    L_ksh_para="${G_resp_app_name}"                 #アプリケーション短縮名(職責)
    L_ksh_para="${L_ksh_para} ${G_resp_name}"       #職責名
    L_ksh_para="${L_ksh_para} ${G_user_name}"       #ユーザ名
    L_ksh_para="${L_ksh_para} ${G_con_app_name}"    #アプリケーション短縮名(コンカレント)
    L_ksh_para="${L_ksh_para} ${G_con_name}"        #コンカレント短縮名
    L_set_para_flag=0
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#    for L_file in "${@}"
    for L_file in ${@+"$@"}
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
    do
      if [ L_set_para_flag -eq 0 ]
      then
        L_set_para_flag=1
      elif [ L_set_para_flag -eq 1 ]
      then
        L_ksh_para="${L_ksh_para} \"${G_path_nas}\""            #I/Fファイルパス(NASサーバ)
        L_set_para_flag=2
      else
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#        L_ksh_para="${L_ksh_para} \"${L_file}\""               #コンカレントパラメータ
        #入力パラメータ2以降は、コンカレント引数となる
        #⇒CONCSUB実行ファンクションの引数に追加する。
        if [ -z "${L_file}" ]
        then
          #コンカレント引数が""の場合、最初と最後にダブルクォートを追加
          L_ksh_para="${L_ksh_para} \"${L_file}\""
        else
          #コンカレント引数が""以外の場合、そのまま渡す。
          L_ksh_para="${L_ksh_para} ${L_file}"
        fi
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
      fi
    done
    #EBS共通コンカレント起動シェル経由で業務コンカレント実行する
    AZBZZEXECONCSUB ${L_ksh_para}
    L_exit_code=${?}
    if [ ${L_exit_code} -ne 0 ]
    then
#2009/11/25 MOD Ver.1.12 Start
##2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
#      shell_end ${C_ret_code_eror}
##2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      shell_end ${L_exit_code}
#2009/11/25 MOD Ver.1.12 End
      exit ${L_exit_code}
    fi
#2009/02/27 UPDATE BY M.Sano 結合テスト動作不正対応 END

  #----------------------------------------------------------------------------
  #【SQL Loader処理】が正常に処理できなかった場合
  #----------------------------------------------------------------------------
  else
    #SQL Loaderにて取り込んだデータ削除
    #・異常終了→戻り値(7)をセットして処理終了
#2009/11/25 MOD Ver.1.12 Start
#    SQL_LOADER_DELETE "${2}"
    SQL_LOADER_DELETE "${G_path_nas}"
#2009/11/25 MOD Ver.1.12 End
    L_ret_code=${?}
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano START
#    if [ ${L_ret_code} -ne 0 ]
#    then
#      exit ${C_ret_code_eror}
#    fi
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano START

    #ファイルを退避する。(NASサーバディレクトリ⇒退避先ディレクトリ)
    #・異常終了→戻り値(7)をセットして処理終了
    FILE_ESCAPE
    L_ret_code=${?}
    if [ ${L_ret_code} -ne 0 ]
    then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
      shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

    #処理の終了(異常終了)
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    exit ${C_ret_code_eror}
  fi
fi

#===============================================================================
#9.業務コンカレント起動（SQL Loader未使用）
#  ※実行条件：SQL-Loader実行フラグ≠"1"
#===============================================================================
if [ "${G_flag_sldr}" != "1" ]
then
  #----------------------------------------------------------------------------
  #【業務コンカレント起動処理】
  #----------------------------------------------------------------------------
#2009/02/27 UPDATE BY M.Sano 結合テスト動作不正対応 START
#  CONCURRENT_EXECUTE "${@}"
#  L_exit_code=${?}
  #業務コンカレント用パラメータを作成する
  L_ksh_para="${G_resp_app_name}"                 #アプリケーション短縮名(職責)
  L_ksh_para="${L_ksh_para} ${G_resp_name}"       #職責名
  L_ksh_para="${L_ksh_para} ${G_user_name}"       #ユーザ名
  L_ksh_para="${L_ksh_para} ${G_con_app_name}"    #アプリケーション短縮名(コンカレント)
  L_ksh_para="${L_ksh_para} ${G_con_name}"        #コンカレント短縮名
  L_set_para_flag=0
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#  for L_file in "${@}"
  for L_file in ${@+"$@"}
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
  do
    if [ L_set_para_flag -eq 0 ]
    then
      L_set_para_flag=1
    else
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#      L_ksh_para="${L_ksh_para} \"${L_file}\""    #コンカレントパラメータ
      #入力パラメータ2以降は、コンカレント引数となる
      #⇒CONCSUB実行ファンクションの引数に追加する。
      if [ -z "${L_file}" ]
      then
        #コンカレント引数が""の場合、最初と最後にダブルクォートを追加
        L_ksh_para="${L_ksh_para} \"${L_file}\""
      else
        #コンカレント引数が""以外の場合、そのまま渡す。
        L_ksh_para="${L_ksh_para} ${L_file}"
      fi
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
    fi
  done
  #EBS共通コンカレント起動シェル経由で業務コンカレント実行する
  AZBZZEXECONCSUB ${L_ksh_para}
  L_exit_code=${?}
#2009/02/27 UPDATE BY M.Sano 結合テスト動作不正対応 END

  #----------------------------------------------------------------------------
  #【業務コンカレント起動処理】が正常に処理できた場合
  #----------------------------------------------------------------------------
  if [ ${L_exit_code} -eq 0 ]
  then
    #NASサーバディレクトリ内のファイル削除（①）
    #・異常終了→戻り値(7)をセットして処理終了
    rm -f "${G_path_nas}"
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    L_ret_code=${?}
#    if [ ${L_ret_code} -ne 0 ]
#    then
    if [ -f "${G_path_nas}" ]
    then
      output_log "${C_log_msg_00020}"
      shell_end ${C_ret_code_eror}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

  #----------------------------------------------------------------------------
  #【業務コンカレント起動処理】が正常に処理できなかった場合
  #----------------------------------------------------------------------------
  else
    #ファイルを退避する。(NASサーバディレクトリ⇒退避先ディレクトリ)（①～④）
    #・異常終了→戻り値(7)をセットして処理終了
    FILE_ESCAPE
    L_ret_code=${?}
    if [ ${L_ret_code} -ne 0 ]
    then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
      shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

    #処理の終了(業務コンカレント実行結果)
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    shell_end ${L_exit_code}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    exit ${L_exit_code}
  fi
fi

#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
shell_end ${C_ret_code_norm}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
exit ${C_ret_code_norm}
