#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          APオンライン・サービス停止処理                                    ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 杉山           2008/03/27 1.0.1                 ##
##        更新履歴：   Oracle 杉山           2008/03/27 1.0.1                 ##
##                       初版                                                 ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      ZCZZ_PEBSAP_STOP.ksh                                                  ##
##                                                                            ##
##    Copyright 株式会社伊藤園 U5000プロジェクト 2007-2009                    ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

## ディレクトリ定義
  L_rogupasu="/var/EBS/jp1/PEBSITO/log"      ##ログファイル格納ディレクトリ

## 変数定義
  L_hizuke=`/bin/date "+%y%m%d"`     ##シェル実行日付
  L_sherumei=`/bin/basename $0`      ##実行シェル名
  L_hosutomei=`/bin/hostname`        ##実行ホスト名
  L_enbufairumei="ZCZZCOMN.env"      ##基盤共通環境変数ファイル名
  L_ijou=8                           ##シェル異常終了時の戻り値

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##ログファイル(フルパス)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                           ##基盤共通環境変数ファイル(フルパス)


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
    if [ -f ${TE_ZCZZHYOUJUNSHUTURYOKU} ]
      then
        L_rogushuturyoku "標準出力一時ファイル削除実行"
        rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
    fi

    if [ -f ${TE_ZCZZHYOUJUNERA} ]
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


### 基盤共通環境変数ファイル読み込み ###


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


### APPSリスナー停止 ###

  ## コマンド設定
  L_apteisi="${TE_ZCZZAPKOMANDOPASU}/adapcctl.sh stop"       ##Webサーバ停止コマンド
  L_appsteisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh stop"     ##APPSリスナー停止コマンド

  L_rogushuturyoku "APPSリスナーを停止します。"

  ${L_appsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、adalnctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00201}"
  elif [ ${L_dashutu} -eq 2 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00200}"
  else
      L_rogushuturyoku "${TE_ZCZZ00204}"
      echo "${TE_ZCZZ00204}" 1>&2
      L_shuryo ${L_ijou}
  fi


### Webサーバ停止 ###

  L_rogushuturyoku "Webサーバを停止します。"

  ${L_apteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、adapcctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00203}"
  elif [ ${L_dashutu} -eq 2 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00202}"
  else
      L_rogushuturyoku "${TE_ZCZZ00204}"
      echo "${TE_ZCZZ00204}" 1>&2
      L_shuryo ${L_ijou}
  fi


### APサーバ停止確認 ###

  L_rogushuturyoku "APサーバ停止確認"
  L_rogushuturyoku "APサーバの停止を待っています。"
  sleep ${TE_ZCZZTAIKI}

## APPSリスナー停止確認
  L_rogushuturyoku "APPSリスナー停止確認"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00204}"
      echo "${TE_ZCZZ00204}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "APPSリスナーの停止を確認しました。"

## Webサーバ停止確認
  L_rogushuturyoku "Webサーバ停止確認"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep iAS | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00204}"
      echo "${TE_ZCZZ00204}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "Webサーバの停止を確認しました。"
  L_rogushuturyoku "APサーバを停止しました。"


### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
