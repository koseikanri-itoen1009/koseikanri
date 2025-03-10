#!/bin/ksh -vx
##################################################################################
## Copyright(c)SCSK Corporation, 2022. All rights reserved.                     ##
##                                                                              ##
## Program Name     : ZBZZCONVSJIS2UTF                                          ##
## Description      : I/Fファイル文字コード変換機能(SJIS->UTF8)                 ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 1.2                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
## $1       ファイル名                                                          ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2022/12/14   1.0   Yoshio.Kubota    新規作成                                ##
##   2023/03/02   1.1   Yoshio.Kubota    EBS環境でも動作するよう調整            ##
##  2025/01/08   1.2   Keisuke.Yoshikawa E_本稼動_20420                         ##
##                                                                              ##
##################################################################################
                                                                                
#↓本番プログラム

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCCP"                    #アプリケーション短縮名
C_program_id="ZBZZCONVSJIS2UTF"        #プログラムID
C_return_norm=0                        #正常終了
C_return_error=8                       #異常終了
C_from_charset=WINDOWS-31J             #変換元文字コード
C_to_charset=UTF-8                     #変換先文字コード

################################################################################
##                                   Main                                     ##
################################################################################
## 1.2 add start
#0.後続処理へのログファイルリダイレクト設定
T_env_name=`whoami | sed -r 's/xebs06|xebs09/T4/' | tr [a-z] [A-Z]`
T_log_dir="/uspg/jp1/zc/shl/${T_env_name}/log"
exec >> ${T_log_dir}/${C_program_id}_`date '+%Y%m%d'`.log 2>&1
## 1.2 add end

#1.入力パラメータ数のチェック
if [ ${#} -ne 1 ]
then
  exit ${C_return_error}
fi
L_file_name=${1}

#2.ファイルのチェック
if [ ! -e ${L_file_name} ]
then
  exit ${C_return_error}
fi
if [ ! -s ${L_file_name} ]
then
  exit ${C_return_norm}
fi

#3.一時ファイル名の作成と内容消去
L_temp_file_name=${L_file_name}.temp

#4.文字コード変換処理
iconv -f ${C_from_charset} -t ${C_to_charset} ${L_file_name} -o ${L_temp_file_name}
if [ ${?} -ne 0 ]
then
  exit ${C_return_error}
fi

#5.ファイル上書き処理
mv -f ${L_temp_file_name} ${L_file_name}
if [ ${?} -ne 0 ]
then
  exit ${C_return_error}
fi

#6.終了処理
exit ${C_return_norm}
