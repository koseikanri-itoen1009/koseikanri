#!/bin/ksh
##################################################################################
## Copyright(c)SCSK Corporation, 2023. All rights reserved.                     ##
##                                                                              ##
## Program Name     : ZBZZCONCATFILE                                            ##
## Description      : IFファイル連結機能                                        ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 1.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
## $1       ファイル名（フルパス）                                              ##
## $2       連結ファイル数                                                      ##
## $3       レコード数                                                          ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2023/03/09   1.0   Yoshio.Kubota    新規作成                                ##
##                                                                              ##
##################################################################################
                                                                                
#↓本番プログラム

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCCP"                    #アプリケーション短縮名
C_program_id="ZBZZCONCATFILE"          #プログラムID
C_return_norm=0                        #正常終了
C_return_error=8                       #異常終了

################################################################################
##                                   Main                                     ##
################################################################################

#1.入力パラメータ数のチェック
if [ ${#} -ne 3 ]
then
  exit ${C_return_error}
fi
L_file_name=${1}
L_file_num=${2}
L_record_num=${3}

#2.対象ファイルのチェック
if [ -e ${L_file_name} ]
then
  exit ${C_return_error}
fi

#3.対象ディレクトリのチェック
L_directory=${L_file_name%/*}
if [ ! -d ${L_directory} ]
then
  exit ${C_return_error}
fi

#4.連結ファイル数とレコード数の数値チェック
if [[ ! "${L_file_num}" =~ ^[0-9]+$ ]] || [[ ! "${L_record_num}" =~ ^[0-9]+$ ]]
then
  exit ${C_return_error}
fi

#5.ファイル名パターンの作成
L_file_pattern="${L_file_name##*/}*"

#6.ファイルを連結
L_cnt=0
for L_if_file in $(find "${L_directory}" -maxdepth 1 -type f -name "${L_file_pattern}")
do
  cat ${L_if_file} >> ${L_file_name}
  L_cnt=`expr ${L_cnt} + 1`
done

#7.ファイル数のチェック
if [ ${L_cnt} -eq 0 ] || [ ${L_file_num} -ne ${L_cnt} ]
then
  exit ${C_return_error}
fi

#8.件数の確認
L_rows=(`wc -l ${L_file_name}`)
if [ ${L_rows[0]} -ge `expr ${L_file_num} \* ${L_record_num}` ]
then
  exit ${C_return_error}
fi

#9.対象ファイルを削除
for L_if_file in $(find "${L_directory}" -maxdepth 1 -type f -name "${L_file_pattern}" -not -name "${L_file_name##*/}" )
do
  #対象ファイルを削除
  rm -f ${L_if_file}
  if [ ${?} -ne 0 ]
  then
    exit ${C_return_error}
  fi
done

#10.終了処理
exit ${C_return_norm}
