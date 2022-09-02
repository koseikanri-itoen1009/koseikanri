#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_CONC_PROCESS_CHECK.ksh                                           ##
##                                                                            ##
##   [概要]                                                                   ##
##          コンカレントマネージャーサービス起動・停止確認                    ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/05/27 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/05/27 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・コンカレントマネージャの確認方法を変更           ##
##                     SCSK 山田             2022/01/06 3.0.0                 ##
##                       E_本稼動_17512対応                                   ##
##                         ・基幹システムリフト対応                           ##
##                         ・ホスト名取得引数追加                             ##
##                         ・コマンドのパス変更                               ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      なし                                                                  ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_CONC_PROCESS_CHECK.ksh             ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################


## 変数定義
##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#L_hosutomei=`/bin/hostname`       ##実行ホスト名
L_hosutomei=`/bin/hostname -s`     ##実行ホスト名
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応
L_uzamei=`/bin/whoami`             ##実行ユーザ名
L_conc_f=""                        ##コンカレント確認用フラグ


################################################################################
##                                 メイン                                     ##
################################################################################


# コンカレントマネージャ起動確認
##2014/07/31 S.Takahashi Mod Start
#L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep FNDLIBR | /usr/bin/grep -v "grep" | /usr/bin/wc -l`

##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/egrep "FNDLIBR|FNDSM|FNDIMON" | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
L_purosesu=`/bin/ps -ef | grep ${L_uzamei} | /bin/egrep "FNDLIBR|FNDSM|FNDIMON" | /bin/grep -v "grep" | /usr/bin/wc -l`
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応

##2014/07/31 S.Takahashi Mod End

if [ "${L_purosesu}" -eq 0 ]
then
   L_conc_f=0      # コンカレントマネージャ停止済み
else
   L_conc_f=1
fi


# 判定
if [ "${L_conc_f}" -eq 0 ]
then
   echo "${L_hosutomei}サーバのコンカレントマネージャーは停止しています"
else
   echo "${L_hosutomei}サーバのコンカレントマネージャーは起動しています"
fi

