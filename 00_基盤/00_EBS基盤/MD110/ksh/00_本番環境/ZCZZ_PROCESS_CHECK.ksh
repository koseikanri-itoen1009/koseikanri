#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_PROCESS_CHECK.ksh                                                ##
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
##                     SCSK 廣守             2018/01/12 2.0.1                 ##
##                       E_本稼動_14800対応                                   ##
##                         ・Formsサーバ起動確認追加                          ##
##                     SCSK 山田             2021/12/22 3.0.0                 ##
##                       E_本稼動_17512対応                                   ##
##                         ・基幹システムリフト対応                           ##
##                         ・ホスト名取得引数追加                             ##
##                         ・コマンドのパス変更                               ##
##                         ・コンカレントサーバー新設に伴うチェック内容の変更 ##
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
##2021/12/22 S.Yamada Mod Start  ※E_本稼動_17512対応
#L_hosutomei=`/bin/hostname`       ##実行ホスト名
#L_uzamei=`/bin/whoami`            ##実行ユーザ名
L_hosutomei=`/bin/hostname -s`     ##実行ホスト名
L_uzamei=`/usr/bin/whoami`         ##実行ユーザ名
##2021/12/22 S.Yamada Mod End    ※E_本稼動_17512対応

L_web_f=""                         ##Webサーバ確認用フラグ
L_apps_f=""                        ##APサーバ確認用フラグ
L_tns_f=""                         ##TNSリスナー確認用フラグ
L_db_f=""                          ##DBサーバ確認用フラグ
## 2018/01/12 Add Start ※E_本稼動_14800対応
L_forms_f=""                       ##Formsサーバ確認用フラグ
## 2018/01/12 Add End   ※E_本稼動_14800対応


################################################################################
##                                 関数定義                                   ##
################################################################################


## ＡＰサーバ確認
L_ap_kakunin()
{
   # Webサーバ起動確認
##2021/12/22 S.Yamada Mod Start     ※E_本稼動_14800対応
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep iAS | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   L_purosesu=`/bin/ps -ef | grep ${L_uzamei} | /bin/grep iAS | /bin/grep -v "grep" | /usr/bin/wc -l`
##2021/12/22 S.Yamada Mod End        ※E_本稼動_14800対応
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_web_f=0            # Webサーバ停止済み
   else
      L_web_f=1
   fi

   # APPSリスナー起動確認
##2021/12/22 S.Yamada Mod Start     ※E_本稼動_14800対応
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   L_purosesu=`/bin/ps -ef | grep ${L_uzamei} | /bin/grep APPS | /bin/grep inherit | /bin/grep -v "grep" | /usr/bin/wc -l`
##2021/12/22 S.Yamada Mod End       ※E_本稼動_14800対応
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_apps_f=0           # APPSリスナー停止済み
   else
      L_apps_f=1
   fi

## 2018/01/12 Add Start ※E_本稼動_14800対応
   # Formsサーバ起動確認
##2021/12/22 S.Yamada Mod Start
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep f60srvm | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   L_purosesu=`/bin/ps -ef | grep ${L_uzamei} | /bin/grep f60srvm | /bin/grep -v "grep" | /usr/bin/wc -l`
##2021/12/22 S.Yamada Mod End
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_forms_f=0            # Formsサーバ停止済み
   else
      L_forms_f=1
   fi
## 2018/01/12 Add End ※E_本稼動_14800対応

   # 判定
## 2018/01/12 Mod Start ※E_本稼動_14800対応
#   if [ "${L_web_f}" -eq 0 -a "${L_apps_f}" -eq 0 ]
   if [ "${L_web_f}" -eq 0 -a "${L_apps_f}" -eq 0 -a "${L_forms_f}" -eq 0 ]
## 2018/01/12 Mod End ※E_本稼動_14800対応
   then
      echo "${L_hosutomei}サーバのEBSプロセスは停止しています"
## 2018/01/12 Mod Start ※E_本稼動_14800対応
#   elif [ "${L_web_f}" -eq 1 -a "${L_apps_f}" -eq 1 ]
   elif [ "${L_web_f}" -eq 1 -a "${L_apps_f}" -eq 1 -a "${L_forms_f}" -eq 1 ]
## 2018/01/12 Mod End ※E_本稼動_14800対応
   then
      echo "${L_hosutomei}サーバのEBSプロセスは起動しています"
   else
      echo "EBSプロセス起動異常"
   fi
}

##2021/12/22 S.Yamada Add Start  ※E_本稼動_17512対応
## コンカレントサーバ確認
L_conc_kakunin()
{
   # APPSリスナー稼働確認
   L_purosesu=`ps -ef | grep ${L_uzamei} | grep APPS | grep inherit | grep -v "grep" | wc -l`

   if [ "${L_purosesu}" -eq 0 ]
   then
      L_apps_f=0      # APPSリスナー停止済み
   else
      L_apps_f=1      # APPSリスナー起動済み
   fi

   # プロセス稼働判定
   if [ "${L_apps_f}" -eq 0 ]
   then
      echo "${L_hosutomei}サーバのEBSプロセスは停止しています"
   elif [ "${L_apps_f}" -eq 1 ]
   then
      echo "${L_hosutomei}サーバのEBSプロセスは起動しています"
   else
      echo "EBSプロセス起動異常"
   fi
}
##2021/12/22 S.Yamada Add End  ※E_本稼動_17512対応

## ＤＢサーバ確認
L_db_kakunin()
{
##2021/12/22 S.Yamada Del Start  ※E_本稼動_17512対応
##   # APPSリスナー起動確認
##   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
##   if [ "${L_purosesu}" -eq 0 ]
##   then
##      L_apps_f=0      # APPSリスナー停止済み
##   else
##      L_apps_f=1
##   fi
##2021/12/22 S.Yamada Del End    ※E_本稼動_17512対応

   # TNSリスナー起動確認
##2014/07/31 S.Takahashi Mod Start
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep "10.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
##2021/12/22 S.Yamada Mod Start    ※E_本稼動_17512対応
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep "11.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   L_purosesu=`/bin/ps -ef | grep ${L_uzamei} | /bin/grep "11.2.0" | /bin/grep inherit | /bin/grep -v "grep" | /usr/bin/wc -l`
##2021/12/22 S.Yamada Mod End      ※E_本稼動_17512対応
##2014/07/31 S.Takahashi Mod End
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_tns_f=0       # TNSリスナー停止済み
   else
      L_tns_f=1
   fi

   # データベース起動確認
##2021/12/22 S.Yamada Mod Start  ※E_本稼動_17512対応
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep ora_pmon | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   L_purosesu=`/bin/ps -ef | grep ${L_uzamei} | /bin/grep ora_pmon | /bin/grep -v "grep" | /usr/bin/wc -l`
##2021/12/22 S.Yamada Mod End    ※E_本稼動_17512対応
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_db_f=0        # データベース停止済み
   else
      L_db_f=1
   fi

   # 判定
##2021/12/22 S.Yamada Mod Start  ※E_本稼動_17512対応
##   if [ "${L_apps_f}" -eq 0 -a "${L_tns_f}" -eq 0 -a "${L_db_f}" -eq 0 ]
   if [ "${L_tns_f}" -eq 0 -a "${L_db_f}" -eq 0 ]
##2021/12/22 S.Yamada End Start  ※E_本稼動_17512対応
   then
      echo "${L_hosutomei}サーバのEBSプロセスは停止しています"
##2021/12/22 S.Yamada Mod Start  ※E_本稼動_17512対応
##   elif [ "${L_apps_f}" -eq 1 -a "${L_tns_f}" -eq 1 -a "${L_db_f}" -eq 1 ]
   elif [ "${L_tns_f}" -eq 1 -a "${L_db_f}" -eq 1 ]
##2021/12/22 S.Yamada End Start  ※E_本稼動_17512対応
   then
      echo "${L_hosutomei}サーバのEBSプロセスは起動しています"
   else
      echo "EBSプロセス起動異常"
   fi
}

################################################################################
##                                 メイン                                     ##
################################################################################

##2021/12/22 S.Yamada Mod Start   ※E_本稼動_17512対応
#L_ap_db_hantei=`echo ${L_hosutomei} | /usr/bin/cut -c 5-6`
L_ap_db_hantei=`echo ${L_hosutomei} | /bin/cut -c 5-6`
##2021/12/22 S.Yamada Mod End     ※E_本稼動_17512対応

case ${L_ap_db_hantei} in
   "ap")   L_ap_kakunin
           ;;
   "db")   L_db_kakunin
           ;;
##2021/12/22 S.Yamada Add Start  ※E_本稼動_17512対応
   "co")   L_conc_kakunin
           ;;
##2021/12/22 S.Yamada Add End    ※E_本稼動_17512対応
   *)      echo "判定に失敗しました"
           ;;
esac
