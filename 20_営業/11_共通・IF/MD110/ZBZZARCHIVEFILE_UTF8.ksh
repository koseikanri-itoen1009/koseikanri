#!/bin/ksh
##################################################################################
## Copyright(c)SCSK Corporation, 2023. All rights reserved.                     ##
##                                                                              ##
## Program Name     : ZBZZARCHIVEFILE_UTF8                                      ##
## Description      : IFファイルアーカイブ作成機能                              ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 1.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
## $1       ファイル名                                                          ##
## $2       ファイル名パターン                                                  ##
## $3       対象ディレクトリ                                                    ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2023/12/08    1.0   Yu.Ryu           UFT8変換なし版新規作成                 ##
##                                                                              ##
##################################################################################
                                                                                
#↓本番プログラム

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCCP"                    #アプリケーション短縮名
C_program_id="ZBZZARCHIVEFILE_UTF8"    #プログラムID
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
L_file_pattern=${2}
L_directory=${3}

#2.対象ファイルのチェック
if [ -e ${L_file_name} ]
then
  exit ${C_return_error}
fi

#3.対象ディレクトリのチェック
if [ ! -d ${L_directory} ]
then
  exit ${C_return_error}
fi

#4.一時ディレクトリ作成と空ディレクトリ作成
L_temp_directory=$(mktemp -d)
mkdir -p ${L_temp_directory}/empty
if [ ! -d ${L_temp_directory}/empty ]
then
  exit ${C_return_error}
fi

#5.一時ディレクトリ削除設定
trap 'rm -rf ${L_temp_directory}' EXIT

#6.対象ファイルを取得
for L_if_file in $(find "${L_directory}" -maxdepth 1 -type f -name "${L_file_pattern}")
do

  #ファイル名と同名の一時フォルダ内のパスを作成
  L_if_directory=${L_temp_directory}/${L_if_file##*/}

  #ファイル名と同名のフォルダを一時フォルダに作成
  mkdir ${L_if_directory}
  if [ ${?} -ne 0 ]
  then
    exit ${C_return_error}
  fi

  #作成したフォルダに対象ファイルのシンボリックリンクを作成
  ln -s -t ${L_if_directory} ${L_if_file}
  if [ ${?} -ne 0 ]
  then
    exit ${C_return_error}
  fi

done

#7.アーカイブを作成
cd ${L_temp_directory}
zip -r -q ${L_file_name} *
if [ ${?} -ne 0 ]
then
  exit ${C_return_error}
fi

#8.対象ファイルを削除
for L_if_file in $(find "${L_directory}" -maxdepth 1 -type f -name "${L_file_pattern}" -not -name "${L_file_name##*/}" )
do
  #対象ファイルを削除
  rm -f ${L_if_file}
  if [ ${?} -ne 0 ]
  then
    exit ${C_return_error}
  fi
done

#9.終了処理
exit ${C_return_norm}
