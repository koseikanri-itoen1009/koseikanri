#!/bin/ksh
##################################################################################
## Copyright(c)SCSK Corporation, 2022. All rights reserved.                     ##
##                                                                              ##
## Program Name     : ZBZZPOSTTRIM                                              ##
## Description      : IFファイル桁数カット後処理                                ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 1.0                                                       ##
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
##                                                                              ##
##################################################################################
                                                                                
#↓本番プログラム

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCCP"                    #アプリケーション短縮名
C_program_id="ZBZZPOSTTRIM"            #プログラムID
C_return_norm=0                        #正常終了
C_return_error=8                       #異常終了
C_delim=","                            #デリミタ

################################################################################
##                                   Main                                     ##
################################################################################

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
echo -n > ${L_temp_file_name}

#4.置換処理
sed -e 's/ \+"\|?"/"/g' ${L_file_name} > ${L_temp_file_name}
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

