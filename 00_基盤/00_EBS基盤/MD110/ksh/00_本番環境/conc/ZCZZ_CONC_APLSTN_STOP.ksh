#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_CONC_APLSTN_STOP.ksh                                             ##
##                                                                            ##
##   [概要]                                                                   ##
##      コンカレントサーバで稼動しているEBSプロセス(APPSリスナー)を停止する。 ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ： SCSK   髙橋           2014/07/31 2.0.0                   ##
##        更新履歴： SCSK   髙橋           2014/07/31 2.0.0                   ##
##                     初版/HWリプレース対応(リプレース_00007)                ##
##                   SCSK   山田           2022/01/11 3.0.0                   ##
##                     E_本稼動_17512対応                                     ##
##                     ・基幹システムリフト対応                               ##
##                     ・ホスト名取得引数追加                                 ##
##                     ・コマンドのパス変更                                   ##
##                     ・サーバー変更に伴うファイル名及び概要変更             ##
##                       ZCZZ_DB_APLSTN_STOP.ksh                              ##
##                       -> ZCZZ_CONC_APLSTN_STOP.ksh                         ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_DB_APLSTN_STOP.ksh                 ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

## 環境依存値
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名

## ディレクトリ定義
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##ログファイル格納ディレクトリ

## 変数定義
  L_hizuke=`/bin/date "+%y%m%d"`     ##シェル実行日付
  L_sherumei=`/bin/basename $0`      ##実行シェル名

##2022/01/11 S.Yamada Mod Start    ※ E_本稼動_17512対応
##  L_hosutomei=`/bin/hostname`        ##実行ホスト名
  L_hosutomei=`/bin/hostname -s`     ##実行ホスト名
##2022/01/11 S.Yamada Mod End      ※ E_本稼動_17512対応

  L_enbufairumei="ZCZZCOMN.env"      ##基盤共通環境変数ファイル名
  L_ijou=8                           ##シェル異常終了時のリターンコード

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##ログファイル(フルパス)
##2022/01/11 S.Yamada Mod Start    ※ E_本稼動_17512対応
##  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##基盤共通環境変数ファイル(フルパス)
  L_enbufairu=`dirname $0`"/${L_enbufairumei}"                                                      ##基盤共通環境変数ファイル(フルパス)
##2022/01/11 S.Yamada Mod End      ※ E_本稼動_17512対応


################################################################################
##                                 関数定義                                   ##
################################################################################


### ログ出力処理 ###

  L_rogushuturyoku()
  {
    echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@} | /usr/bin/fold -w 78 >> ${L_rogumei}
  }


### 終了処理 ###

  L_shuryo()
  {
##2022/01/11 S.Yamada Mod Start    ※ E_本稼動_17512対応
##    if [ -f ${TE_ZCZZHYOUJUNSHUTURYOKU} ]
    if [ -f "${TE_ZCZZHYOUJUNSHUTURYOKU}" ]
##2022/01/11 S.Yamada Mod End      ※ E_本稼動_17512対応
      then
        L_rogushuturyoku "標準出力一時ファイル削除実行"
        rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
    fi

##2022/01/11 S.Yamada Mod Start    ※ E_本稼動_17512対応
##    if [ -f ${TE_ZCZZHYOUJUNERA} ]
    if [ -f "${TE_ZCZZHYOUJUNERA}" ]
##2022/01/11 S.Yamada Mod End      ※ E_本稼動_17512対応
      then
        L_rogushuturyoku "標準エラー一時ファイル削除実行"
        rm ${TE_ZCZZHYOUJUNERA}
    fi

    L_modorichi=${1:-0}
    L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了  END_CD="${L_modorichi}
    exit ${L_modorichi}
  }

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                 メイン                                     ##
################################################################################



### 処理開始出力 ###

  touch ${L_rogumei}
  L_rogushuturyoku "ZCZZ00001:${L_sherumei} 開始"


### 環境設定環境変数ファイル読み込み ###

## 基盤共通ファイル読み込み
  L_rogushuturyoku "基盤共通環境変数ファイルを読み込みます。"

  if [ -r "${L_enbufairu}" ]
    then
      . ${L_enbufairu}
      L_rogushuturyoku "基盤共通環境変数ファイルを読み込みました。"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_enbufairu}` が存在しない、または見つかりません。   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_enbufairu}` が存在しない、または見つかりません。   HOST=${L_hosutomei}" 1>&2
      L_shuryo ${L_ijou}
  fi

## コマンド設定
  L_appsteisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh stop"                            ##APPSリスナー停止コマンド

### APPSリスナー停止 ###

  L_rogushuturyoku "APPSリスナーを停止します。"

  ${L_appsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}

##2022/01/11 S.Yamada Mod Start    ※ E_本稼動_17512対応
##  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
  /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
##2022/01/11 S.Yamada Mod End      ※ E_本稼動_17512対応

## 戻り値から、adalnctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00501}"
  elif [ ${L_dashutu} -eq 2 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00500}"
  else
      L_rogushuturyoku "${TE_ZCZZ00502}"
      echo "${TE_ZCZZ00502}" 1>&2
      L_shuryo ${L_ijou}
  fi


### AP層停止確認 ###

  L_rogushuturyoku "AP層停止確認"
  L_rogushuturyoku "AP層の停止を待っています。"
  sleep ${TE_ZCZZTAIKI}

## APPSリスナー停止確認
  L_rogushuturyoku "APPSリスナー停止確認"

##2022/01/11 S.Yamada Mod Start    ※ E_本稼動_17512対応
##  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
  /bin/ps -ef | grep `/usr/bin/whoami` | /bin/grep APPS | /bin/grep inherit | /bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
##2022/01/11 S.Yamada Mod End      ※ E_本稼動_17512対応
    then
      L_rogushuturyoku "${TE_ZCZZ00502}"
      echo "${TE_ZCZZ00502}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "APPSリスナーの停止を確認しました。"


### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
