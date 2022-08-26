#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZDELETEFILE                                            ##
## Description      : I/Fファイル削除機能                                       ##
## MD.070           : MD070_IPO_CCP_シェル                                      ##
## Version          : 3.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
## $1       ファイル名                                                          ##
## $2       削除ディレクトリ                                                    ##
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
##  2022/07/19    3.0   Shun.Takenami    IaaS化対応                             ##
##                                       ・ls の追加,rm のオプションを削除      ##
##                                                                              ##
##################################################################################
                                                                                
#↓本番プログラム

################################################################################
##                                 変数定義                                   ##
################################################################################

C_appl_name="XXCCP"                    #アプリケーション短縮名
C_program_id="ZBZZDELETEFILE "         #プログラムID
C_return_norm=0                        #正常終了
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.1 Start
#C_return_error=7                       #異常終了
C_return_error=8                       #異常終了
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.1 End

################################################################################
##                                   Main                                     ##
################################################################################

#1.引数チェック
if [ ${#} -ne 2 ]
then
  exit ${C_return_error}
fi

#2.指定したファイルを削除
#(パスを取得)
L_del_file_path="${2}/${1}"

#2022/07/19 3.0 ADD START
ls ${L_del_file_path}
#2022/07/19 3.0 ADD END
#
#(削除)
#2009/05/18 UPDATE BY Masayuki.Sano Ver.1.2 Start
#rm -f "${L_del_file_path}"
#L_ret_code=${?}
#2022/07/19 3.0 MOD START
#rm -f ${L_del_file_path}
rm ${L_del_file_path}
#2022/07/19 3.0 MOD END

L_ret_code=${?}
#2009/05/18 UPDATE BY Masayuki.Sano Ver.1.2 End
if [ ${L_ret_code} -ne 0 ]
then
  exit ${C_return_error}
fi

exit ${C_return_norm}

