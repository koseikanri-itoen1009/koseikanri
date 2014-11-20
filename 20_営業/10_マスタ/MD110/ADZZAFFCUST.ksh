#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZAFFCUST                                               ##
## Description      : AFF顧客マスタ更新(FND_LOAD)                               ##
## MD.070           : MD050_IPO_CMM_003_A38_AFF顧客マスタ更新（FND_LOAD）       ##
## Version          : 1.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1       引数チェック(A-1)                                                  ##
##  $2       ファイル存在チェック(A-2)                                          ##
##  $3       FNDLOAD起動処理(A-3)                                               ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/02/16    1.0   Takuya.Kaihara   新規作成                               ##
##                                                                              ##
##################################################################################
                                                                                  
################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCMM"                    #アプリケーション短縮名
C_program_id="ZBZZAFFCUST"             #プログラムID
C_return_norm=0                        #正常終了
C_return_error=7                       #異常終了

################################################################################
##                                   Main                                     ##
################################################################################

#1.引数チェック
if [ ${#} -ne 4 ]
then
  exit ${C_return_error}
fi

#2-1.ファイル存在チェック(構成ファイル)
L_compos_file_path="${2}/${1}"
if [ -f "${L_compos_file_path}" ]
then
  #2-2.ファイル存在チェック(LDTファイル)
  L_check_file_path="${4}/${3}"
  if [ -f "${L_check_file_path}" ]
  then
    #3.AFF顧客マスタ更新
    FNDLOAD apps/apps 0 Y UPLOAD ${L_compos_file_path} ${L_check_file_path} VALUE_SET
    if [ ${?} != 0 ]
    then
      exit ${C_return_error}
    fi
  else
    exit ${C_return_norm}
  fi
else
  exit ${C_return_error}
fi

exit ${C_return_norm}
