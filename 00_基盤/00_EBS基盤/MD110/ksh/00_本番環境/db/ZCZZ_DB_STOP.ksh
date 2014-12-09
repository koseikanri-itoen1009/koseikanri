#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBオンライン・サービス停止処理                                    ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 杉山           2008/03/27 1.0.1                 ##
##        更新履歴：   Oracle 杉山           2008/03/27 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・ローカル変数(L_以降)を小文字に変更               ##
##                         ・APPSリスナーの停止・確認処理を削除               ##
##                         ・DB停止コマンドの変更                             ##
##                         ・TNSリスナープロセスの監視対象の変更              ##
##                         ・シェル名変更                                     ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_DB_STOP.ksh                        ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

##2014/07/31 S.Takahashi Add Start
## 環境依存値
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名
##2014/07/31 S.Takahashi Add End

## ディレクトリ定義
##2014/07/31 S.Takahashi Mod Start
#  L_ROGUPASU="/var/EBS/jp1/PEBSITO/log"      ##ログファイル格納ディレクトリ
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##ログファイル格納ディレクトリ
#2014/07/31 S.Takahashi Mod End

## 変数定義
  L_hizuke=`/bin/date "+%y%m%d"`     ##シェル実行日付
  L_sherumei=`/bin/basename $0`      ##実行シェル名
  L_hosutomei=`/bin/hostname`        ##実行ホスト名
  L_enbufairumei="ZCZZCOMN.env"      ##基盤環境環境変数ファイル名
  L_dbfairumei="ZCZZDB.env"          ##DB環境設定ファイル名
  L_ijou=8                           ##シェル異常終了時の戻り値

## ファイル定義
##2014/07/31 S.Takahashi Mod Start
#  L_rogumei="${L_ROGUPASU}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##ログファイル(フルパス)
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##ログファイル(フルパス)
##2014/07/31 S.Takahashi Mod End

  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                           ##基盤共通環境変数ファイル(フルパス)
  L_dbfairu=`/usr/bin/dirname $0`"/${L_dbfairumei}"                                               ##DB環境設定ファイル(フルパス)


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


### 共通ファイル読み込み ###

## 基盤共通環境変数ファイル読み込み
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

## DB環境設定ファイル読み込み
  L_rogushuturyoku "DB環境設定ファイルを読み込みます。"

  if [ -r "${L_dbfairu}" ]
    then
      . ${L_dbfairu}
      L_rogushuturyoku "DB環境設定ファイルを読み込みました。"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_dbfairu}` が存在しない、または見つかりません。   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_dbfairu}` が存在しない、または見つかりません。   HOST=${L_hosutomei}" 1>&2
      L_shuryo ${L_ijou}
  fi

## コマンド設定
##2014/07/31 S.Takahashi Del Start
#  L_appsteisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh stop"                                        ##APPSリスナー停止コマンド
##2014/07/31 S.Takahashi Del End

##2014/07/31 S.Takahashi Mod Start
#  L_dbteisi="${ORACLE_HOME}/bin/srvctl stop instance -d PEBSITO -i ${ORACLE_SID} -o immediate"  ##データベース停止コマンド
  L_dbteisi="${ORACLE_HOME}/bin/srvctl stop instance -d ${DATABASE_NAME} -i ${ORACLE_SID} -o immediate"  ##データベース停止コマンド
##2014/07/31 S.Takahashi Mod End

  L_risunateisi="${ORACLE_HOME}/bin/srvctl stop listener -n ${TE_ZCZZHOSUTOMEI} -l ${LISTENER_NAME}" ##TNSリスナー停止コマンド

##2014/07/31 S.Takahashi Del Start
### APPSリスナー停止 ###

#  L_rogushuturyoku "APPSリスナーを停止します。"

#  ${L_appsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
#  L_dashutu=${?}
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、adalnctlの動作を判定
#  if [ ${L_dashutu} -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00501}"
#  elif [ ${L_dashutu} -eq 2 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00500}"
#  else
#      L_rogushuturyoku "${TE_ZCZZ00502}"
#      echo "${TE_ZCZZ00502}" 1>&2
#      L_shuryo ${L_ijou}
#  fi


### AP層停止確認 ###

#  L_rogushuturyoku "AP層停止確認"
#  L_rogushuturyoku "AP層の停止を待っています。"
#  sleep ${TE_ZCZZTAIKI}

## APPSリスナー停止確認
#  L_rogushuturyoku "APPSリスナー停止確認"
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00502}"
#      echo "${TE_ZCZZ00502}" 1>&2
#      L_shuryo ${L_ijou}
#  fi

#  L_rogushuturyoku "APPSリスナーの停止を確認しました。"
##2014/07/31 S.Takahashi Del End


### データベース停止 ###

  L_rogushuturyoku "データベースを停止します。"

  ${L_dbteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、srvctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00503}"
  else
      L_rogushuturyoku "${TE_ZCZZ00504}"
      echo "${TE_ZCZZ00504}" 1>&2
      L_shuryo ${L_ijou}
  fi


### TNSリスナー停止 ###

  L_rogushuturyoku "TNSリスナーを停止します。"

  ${L_risunateisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、srvctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00505}"
  else
      L_rogushuturyoku "${TE_ZCZZ00504}"
      echo "${TE_ZCZZ00504}" 1>&2
      L_shuryo ${L_ijou}
  fi


### DBサーバ停止確認 ###

  L_rogushuturyoku "DBサーバ停止確認"
  L_rogushuturyoku "DB層の停止を待っています。"
  sleep ${TE_ZCZZTAIKI}

## TNSリスナー停止確認
  L_rogushuturyoku "TNSリスナー停止確認"
##2014/07/31 S.Takahashi Mod Start  
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep "10.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep "11.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2014/07/31 S.Takahashi Mod End

  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00504}"
      echo "${TE_ZCZZ00504}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "TNSリスナーの停止を確認しました。"

## データベース停止確認
  L_rogushuturyoku "データベース停止確認"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep ora_pmon | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00504}"
      echo "${TE_ZCZZ00504}" 1>&2
      L_shuryo ${L_ijou}
  fi

 L_rogushuturyoku "データベースの停止を確認しました。"
 L_rogushuturyoku "DBサーバを停止しました。"


### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
