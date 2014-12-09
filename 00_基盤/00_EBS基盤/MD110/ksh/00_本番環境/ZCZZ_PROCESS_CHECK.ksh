#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          サービス起動・停止確認                                            ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/05/14 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/05/14 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・TNSリスナーの起動確認対象プロセスを変更          ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      なし                                                                  ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_PROCESS_CHECK.ksh                  ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################


## 変数定義
L_hosutomei=`/bin/hostname`        ##実行ホスト名
L_uzamei=`/bin/whoami`             ##実行ユーザ名
L_web_f=""                         ##Webサーバ確認用フラグ
L_apps_f=""                        ##APサーバ確認用フラグ
L_tns_f=""                         ##TNSリスナー確認用フラグ
L_db_f=""                          ##DBサーバ確認用フラグ


################################################################################
##                                 関数定義                                   ##
################################################################################


## ＡＰサーバ確認
L_ap_kakunin()
{
   # Webサーバ起動確認
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep iAS | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_web_f=0            # Webサーバ停止済み
   else
      L_web_f=1
   fi
   
   # APPSリスナー起動確認
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_apps_f=0           # APPSリスナー停止済み
   else
      L_apps_f=1
   fi

   # 判定
   if [ "${L_web_f}" -eq 0 -a "${L_apps_f}" -eq 0 ]
   then
      echo "${L_hosutomei}サーバのEBSプロセスは停止しています"
   elif [ "${L_web_f}" -eq 1 -a "${L_apps_f}" -eq 1 ]
   then
      echo "${L_hosutomei}サーバのEBSプロセスは起動しています"
   else
      echo "EBSプロセス起動異常"
   fi
}

## ＤＢサーバ確認
L_db_kakunin()
{
   # APPSリスナー起動確認
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_apps_f=0      # APPSリスナー停止済み
   else
      L_apps_f=1
   fi

   # TNSリスナー起動確認
##2014/07/31 S.Takahashi Mod Start
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep "10.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep "11.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
##2014/07/31 S.Takahashi Mod End
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_tns_f=0       # TNSリスナー停止済み
   else
      L_tns_f=1
   fi

   # データベース起動確認
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep ora_pmon | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_db_f=0        # データベース停止済み
   else
      L_db_f=1
   fi

   # 判定
   if [ "${L_apps_f}" -eq 0 -a "${L_tns_f}" -eq 0 -a "${L_db_f}" -eq 0 ]
   then
      echo "${L_hosutomei}サーバのEBSプロセスは停止しています"
   elif [ "${L_apps_f}" -eq 1 -a "${L_tns_f}" -eq 1 -a "${L_db_f}" -eq 1 ]
   then
      echo "${L_hosutomei}サーバのEBSプロセスは起動しています"
   else
      echo "EBSプロセス起動異常"
   fi
}


################################################################################
##                                 メイン                                     ##
################################################################################

L_ap_db_hantei=`echo ${L_hosutomei} | /usr/bin/cut -c 5-6`


case ${L_ap_db_hantei} in
   "ap")   L_ap_kakunin
           ;;
   "db")   L_db_kakunin
           ;;
   *)      echo "判定に失敗しました"
           ;;
esac


