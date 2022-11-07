#!/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBオンライン・サービス起動処理                                    ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 杉山           2008/03/27 1.0.1                 ##
##        更新履歴：   Oracle 杉山           2008/03/27 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK   戸谷田         2012/05/14 1.0.2                 ##
##                       障害番号#08434対応                                   ##
##                       ・DBインスタンス起動後にNLS_LANGUAGEパラメータの     ##
##                         設定ロジックを追加                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・DB停止コマンドの変更                             ##
##                         ・TNSリスナープロセスの監視対象の変更              ##
##                         ・APPSリスナーの起動・確認処理を削除               ##
##                         ・終了処理のログ出力内容を修正                     ##
##                         ・シェル名変更                                     ##
##                     SCSK   廣守           2017/12/06 2.0.1                 ##
##                       E_本稼動_14688対応                                   ##
##                         ・TNSエラーメッセージ変更                          ##
##                             TE_ZCZZ00603 -> TE_ZCZZ00605                   ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_DB_START.ksh                       ##
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
#  L_rogupasu="/var/EBS/jp1/PEBSITO/log"      ##ログファイル格納ディレクトリ
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##ログファイル格納ディレクトリ
##2014/07/31 S.Takahashi Mod End

## 変数定義
  L_hizuke=`/bin/date "+%y%m%d"`     ##シェル実行日付
  L_sherumei=`/bin/basename $0`      ##実行シェル名
##2021/09/30 Hitachi,Ltd Mod Start
#  L_hosutomei=`/bin/hostname`        ##実行ホスト名
  L_hosutomei=`/bin/hostname -s`     ##実行ホスト名
##2021/09/30 Hitachi,Ltd Mod End
  L_enbufairumei="ZCZZCOMN.env"      ##基盤共通環境変数ファイル名
  L_dbfairumei="ZCZZDB.env"          ##DB環境設定ファイル名
  L_ijou=8                           ##シェル異常終了時のリターンコード

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##ログファイル(フルパス)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##基盤共通環境変数ファイル(フルパス)
  L_dbfairu=`/usr/bin/dirname $0`"/${L_dbfairumei}"                                                 ##DB環境設定ファイル(フルパス)


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
##2014/07/31 S.Takahashi Mod Start
#  L_rogushuturyoku "ZCZZ00002:${L_sherumei} 開始"
  L_rogushuturyoku "ZCZZ00001:${L_sherumei} 開始"
##2014/07/31 S.Takahashi Mod End

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
#  L_appskaisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh start"                            ##APPSリスナー開始コマンド
##2014/07/31 S.Takahashi Del End

##2014/07/31 S.Takahashi Mod Start
#  L_dbkaisi="${ORACLE_HOME}/bin/srvctl start instance -d PEBSITO -i ${ORACLE_SID}"   ##データベース開始コマンド
  L_dbkaisi="${ORACLE_HOME}/bin/srvctl start instance -d ${DATABASE_NAME} -i ${ORACLE_SID}"   ##データベース開始コマンド
##2014/07/31 S.Takahashi Mod End
  L_risunakaisi="${ORACLE_HOME}/bin/srvctl start listener -n ${TE_ZCZZHOSUTOMEI} -l ${LISTENER_NAME}"    ##TNSリスナー開始コマンド


### TNSリスナー起動 ###

  L_rogushuturyoku "TNSリスナーを起動します。"

  ${L_risunakaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
##2021/09/30 Hitachi,Ltd Mod Start
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
  /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
##2021/09/30 Hitachi,Ltd Mod End

## 戻り値から、srvctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00604}"
  else
##2017/12/06 S.Hiromori Message Change Start TE_ZCZZ00603 -> TE_ZCZZ00605
#    L_rogushuturyoku "${TE_ZCZZ00603}"
#    echo "${TE_ZCZZ00603}" 1>&2
    L_rogushuturyoku "${TE_ZCZZ00605}"
    echo "${TE_ZCZZ00605}" 1>&2
##2017/12/06 S.Hiromori Message Change End
    L_shuryo ${L_ijou}
  fi


### データベース起動 ###

  L_rogushuturyoku "データベースを起動します。"

  ${L_dbkaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
##2021/09/30 Hitachi,Ltd Mod Start
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
  /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
##2021/09/30 Hitachi,Ltd Mod End

## 戻り値から、srvctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00602}"
  else
    L_rogushuturyoku "${TE_ZCZZ00603}"
    echo "${TE_ZCZZ00603}" 1>&2
    L_shuryo ${L_ijou}
  fi


### DBサーバ起動確認 ###

  L_rogushuturyoku "DBサーバ起動確認"
  L_rogushuturyoku "DB層の起動を待っています。"
  sleep ${TE_ZCZZTAIKI}

## TNSリスナー起動確認
  L_rogushuturyoku "TNSリスナー起動確認"
##2014/07/31 S.Takahashi Mod Start
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep "10.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2021/09/30 Hitachi,Ltd Mod Start
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep "11.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  /bin/ps -ef | grep `/usr/bin/whoami` | /bin/grep "11.2.0" | /bin/grep inherit | /bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2021/09/30 Hitachi,Ltd Mod End
##2014/07/31 S.Takahashi Mod End
##2021/09/30 Hitachi,Ltd Mod Start
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
  if [ `/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
##2021/09/30 Hitachi,Ltd Mod End
    then
##2017/12/06 S.Hiromori Message Change Start TE_ZCZZ00603 -> TE_ZCZZ00605
#      L_rogushuturyoku "${TE_ZCZZ00603}"
#      echo "${TE_ZCZZ00603}" 1>&2
      L_rogushuturyoku "${TE_ZCZZ00605}"
      echo "${TE_ZCZZ00605}" 1>&2
##2017/12/06 S.Hiromori Message Change End
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "TNSリスナーの起動を確認しました。"

## データベース起動確認
  L_rogushuturyoku "データベース起動確認"
##2021/09/30 Hitachi,Ltd Mod Start
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep ora_pmon | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  /bin/ps -ef | grep `/usr/bin/whoami` | /bin/grep ora_pmon | /bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2021/09/30 Hitachi,Ltd Mod End
##2021/09/30 Hitachi,Ltd Mod Start
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
  if [ `/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
##2021/09/30 Hitachi,Ltd Mod End
    then
      L_rogushuturyoku "${TE_ZCZZ00603}"
      echo "${TE_ZCZZ00603}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "データベースの起動を確認しました。"

## 日付書式設定(障害番号#08766対応)

  L_rogushuturyoku "日付書式「NLS_LANGUAGE」を設定します"

  . ${ORACLE_HOME}/${ORACLE_SID}_${TE_ZCZZHOSUTOMEI}.env
  L_rogushuturyoku "ORA_NLS10 : `echo $ORA_NLS10`"

  ${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF 1> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
  WHENEVER OSERROR EXIT FAILURE
  WHENEVER SQLERROR EXIT FAILURE

  alter session set nls_language=JAPANESE;
  exit
EOF

  L_dashutu=${?}

## 戻り値から、SQLの実行結果を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01700}"
    else
      L_rogushuturyoku "${TE_ZCZZ01701}"
##2021/09/30 Hitachi,Ltd Mod Start
#      echo "${TE_ZCZZ00601}" 1>&2
      echo "${TE_ZCZZ01701}" 1>&2
##2021/09/30 Hitachi,Ltd Mod End
      L_shuryo ${L_ijou}
    fi

    L_rogushuturyoku "日付書式「NLS_LANGUAGE」の設定が完了しました"

##2014/07/31 S.Takahashi Del Start
### APPSリスナー起動 ###

#  L_rogushuturyoku "APPSリスナーを起動します。"

#  ${L_appskaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
#  L_dashutu=${?}
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、adalnctlの動作を判定
#  if [ ${L_dashutu} -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00600}"
#  else
#      L_rogushuturyoku "${TE_ZCZZ00601}"
#      echo "${TE_ZCZZ00601}" 1>&2
#      L_shuryo ${L_ijou}
#  fi


#### AP層起動確認 ###
#
#  L_rogushuturyoku "AP層起動確認"
#  L_rogushuturyoku "AP層の起動を待っています。"
#  sleep ${TE_ZCZZTAIKI}

## APPSリスナー起動確認
#  L_rogushuturyoku "APPSリスナー起動確認"
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00601}"
#      echo "${TE_ZCZZ00601}" 1>&2
#      L_shuryo ${L_ijou}
#  fi

#  L_rogushuturyoku "APPSリスナーの起動を確認しました。"
##2014/07/31 S.Takahashi Del End

### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
