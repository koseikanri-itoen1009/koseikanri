#!/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          CRSサービス起動・停止確認                                         ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/05/27 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/05/27 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・CRSプロセスの判定方法を変更                      ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      なし                                                                  ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_CRS_PROCESS_CHECK.ksh              ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################


## 変数定義
##2021/09/30 Hitachi,Ltd Mod Start
#L_hosutomei=`/bin/hostname`        ##実行ホスト名
L_hosutomei=`/bin/hostname -s`     ##実行ホスト名
##2021/09/30 Hitachi,Ltd Mod End
L_crs_f=""                         ##CRS確認用フラグ


################################################################################
##                                 メイン                                     ##
################################################################################


# CRSプロセス起動確認
##2014/07/31 S.Takahashi Mod Start
#L_purosesu=`/usr/bin/ps -ef | /usr/bin/grep "ocssd.bin" | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
##2021/09/30 Hitachi,Ltd Mod Start
#L_purosesu=`/usr/bin/ps -ef | /usr/bin/egrep 'ocssd.bin|osysmond.bin|asm_pmon' | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
L_purosesu=`/bin/ps -ef | /bin/egrep 'ocssd.bin|osysmond.bin|asm_pmon' | /bin/grep -v "grep" | /usr/bin/wc -l`
##2021/09/30 Hitachi,Ltd Mod End
##2014/07/31 S.Takahashi Mod End

if [ "${L_purosesu}" -eq 0 ]
then
   L_crs_f=0      # CRSプロセス停止済み
else
   L_crs_f=1
fi


# 判定
if [ "${L_crs_f}" -eq 0 ]
then
   echo "${L_hosutomei}サーバのCRSプロセスは停止しています"
else
   echo "${L_hosutomei}サーバのCRSプロセスは起動しています"
fi

