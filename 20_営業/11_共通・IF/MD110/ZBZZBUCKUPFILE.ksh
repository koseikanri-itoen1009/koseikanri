#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZBUCKUPFILE                                            ##
## Description      : I/Fファイルバックアップ機能                               ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 1.2                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1       ファイル名                                                         ##
##  $2       バックアップ元ディレクトリ                                         ##
##  $3       バックアップ先ディレクトリ                                         ##
##  $4       世代数                                                             ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/08    1.0   Masayuki.Sano    新規作成                               ##
##  2009/05/07    1.1   Masayuki.Sano    障害番号T1_0917対応                    ##
##                                       ・異常終了(7⇒8)へ修正                 ##
##  2009/05/18    1.2   Masayuki.Sano    障害番号T1_1006対応                    ##
##                                       ・ワイルドカード使用可対応             ##
##                                                                              ##
##################################################################################
                                                                                  
#↓本番プログラム

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCCP"                    #アプリケーション短縮名
C_program_id="ZBZZESCAPEFILE"          #プログラムID
C_return_norm=0                        #正常終了
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.1 Start
#C_return_error=7                       #異常終了
C_return_error=8                       #異常終了
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.1 End
C_date_format="+%Y%m%d%H%M%S"          #日時フォーマット(YYYYMMDDH24MISS)

################################################################################
##                                   Main                                     ##
################################################################################

#1.引数チェック
if [ ${#} -ne 4 ]
then
  exit ${C_return_error}
fi

#2.世代数チェック
#(数値かどうかチェック)
if [ "$(echo ${4} | egrep '^[0-9]+$')" -eq "" ]
then
  exit ${C_return_error}
fi
#(1以下かどうかチェック)
if [ ${4} -lt 1 ]
then
  exit ${C_return_error}
fi

#2009/05/18 UPDATE BY Masayuki.Sano Ver.1.2 Start
##3.ベース名、拡張子、処理日時を取得
#L_base=$(echo "${1}" | sed -e 's/\.[^\.]*$//')        #入力ファイルのベース名
#L_exte=$(echo "${1}" | sed -e 's/^'"${L_base}"'\.//') #入力ファイルの拡張子
#L_date=$(date "${C_date_format}")                     #処理日時
#
##4.指定したファイルをバックアップ元からバックアップ先へコピー
##(パス情報を取得)
#L_in_file_path="${2}/${1}"                            #バックアップ元ファイルパス
#L_ou_file_path="${3}/${L_base}_${L_date}.${L_exte}"   #バックアップ先ファイルパス
##(コピー)
#cp -pf "${L_in_file_path}" "${L_ou_file_path}"
#L_ret_code=${?}
#if [ ${L_ret_code} -ne 0 ]
#then
#  exit ${C_return_error}
#fi
cd "${2}"
for L_if_file in $(ls -1r ${1})
do
  #3ベース名・拡張子・処理日時を取得
  L_base=$(echo "${L_if_file}" | sed -e 's/\.[^\.]*$//')        #入力ファイルのベース名
  L_exte=$(echo "${L_if_file}" | sed -e 's/^'"${L_base}"'\.//') #入力ファイルの拡張子
  L_date=$(date "${C_date_format}")                     #処理日時

  #4.指定したファイルをバックアップ先へコピー
  cp -f "${2}/${L_if_file}" "${3}/${L_base}_${L_date}.${L_exte}"
  L_ret_code=${?}
  if [ ${L_ret_code} -ne 0 ]
  then
    exit ${C_return_error}
  fi
#2009/05/18 UPDATE BY Masayuki.Sano Ver.1.2 End

  #5.バックアップ数が世代数を超えている分だけファイルを削除
  #(初期設定)
  let L_cnt=0
  #(処理)
  for L_file in $(ls -1r "${3}" | egrep -x "${L_base}_[0-9]{14}\.${L_exte}")
  do
    let L_cnt=${L_cnt}+1
    if [ ${4} -lt ${L_cnt} ]
    then
      rm -f "${3}/${L_file}"
      L_ret_code=${?}
      if [ ${L_ret_code} -ne 0 ]
      then
        exit ${C_return_error}
      fi
    fi
  done
#2009/05/18 ADD BY Masayuki.Sano Ver.1.2 Start
done
L_ret_code=${?}
#対象ファイルが存在しない等により異常終了した場合、異常終了
if [ ${L_ret_code} -ne 0 ]
then
  exit ${C_return_error}
fi
#2009/05/18 ADD BY Masayuki.Sano Ver.1.2 End

exit ${C_return_norm}
