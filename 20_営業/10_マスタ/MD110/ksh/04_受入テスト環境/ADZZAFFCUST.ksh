#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ADZZAFFCUST                                               ##
## Description      : AFF顧客マスタ更新(FND_LOAD)                               ##
## MD.070           : MD050_IPO_CMM_003_A38_AFF顧客マスタ更新（FND_LOAD）       ##
## Version          : 1.3                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $0       ENVファイル読み込み                                                ##
##  $1       引数チェック(A-1)                                                  ##
##  $2       ファイル存在チェック(A-2)                                          ##
##  $3       FNDLOAD起動処理(A-3)                                               ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/02/16    1.0   Takuya.Kaihara   新規作成                               ##
##  2009/06/04    1.1   Yutaka.Kuboshima 障害T1_1052の対応                      ##
##  2009/07/09    1.2   Yutaka.Kuboshima 統合テスト障害0000230の対応            ##
##  2010/01/14    1.3   Shigeto.Niki     障害：E_本稼動_00868の対応             ##
##                                                                              ##
##################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCMM"                    #アプリケーション短縮名
C_program_id="ADZZAFFCUST"             #プログラムID
C_return_norm=0                        #正常終了
C_return_error=7                       #異常終了

##2009/06/04 Ver1.1 add start by Yutaka.Kuboshima
L_cmd=${0}
L_cmddir=`/bin/dirname ${L_cmd}`

#外部シェル
L_envfile=${L_cmddir}/ADZZAPPS.env
##2009/06/04 Ver1.1 add end by Yutaka.Kuboshima

################################################################################
##                                   Main                                     ##
################################################################################

##2009/06/04 Ver1.1 add start by Yutaka.Kuboshima
#0-1.外部シェルの読込み
if [ -r ${L_envfile} ]
then
  . ${L_envfile}
else
  exit ${C_return_error}
fi

#0-2.ENVファイルの読込み
if [ -r ${L_appsora} ]
then
  . ${L_appsora}
else
  exit ${C_return_error}
fi

##2009/06/04 Ver1.1 add end by Yutaka.Kuboshima

#1.引数チェック
##2009/07/09 Ver1.2 delete start by Yutaka.Kuboshima
#if [ ${#} -ne 4 ]
#then
#  exit ${C_return_error}
#fi
##2009/07/09 Ver1.2 delete end by Yutaka.Kuboshima

#2-1.ファイル存在チェック(構成ファイル)
##2009/07/09 Ver1.2 modify start by Yutaka.Kuboshima
#L_compos_file_path="${2}/${1}"
L_compos_file_path="${L_load_file_path}/${L_load_file_name}"
##2009/07/09 Ver1.2 modify end by Yutaka.Kuboshima

##2010/01/14 Ver1.3 add start by Shigeto.Niki
#ログ出力ディレクトリの変更
cd "${L_log_file_path}"
##2010/01/14 Ver1.3 add end by Shigeto.Niki

if [ -f "${L_compos_file_path}" ]
then
  #2-2.ファイル存在チェック(LDTファイル
##2009/07/09 Ver1.2 modify start by Yutaka.Kuboshima
#  L_check_file_path="${4}/${3}"
  L_check_file_path="${L_ldt_file_path}/${L_ldt_file_name}"
##2009/07/09 Ver1.2 modify end by Yutaka.Kuboshima
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
