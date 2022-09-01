#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_AP_START.ksh                                                     ##
##                                                                            ##
##   [概要]                                                                   ##
##          APオンライン・サービス開始処理                                    ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 杉山           2008/03/27 1.0.1                 ##
##        更新履歴：   Oracle 杉山           2008/03/27 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 野口             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・シェル名変更                                     ##
##                     SCSK 廣守             2018/01/12 2.0.1                 ##
##                       E_本稼動_14800対応                                   ##
##                         ・Formsサーバ起動追加                              ##
##                     SCSK 山田             2022/01/06 3.0.0                 ##
##                       E_本稼動_17512対応                                   ##
##                         ・基幹システムリフト対応                           ##
##                         ・ホスト名取得引数追加                             ##
##                         ・コマンドのパス変更                               ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_AP_START.ksh                       ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

##2014/07/31 S.Noguchi Add Start
## 環境依存値
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名
##2014/07/31 S.Noguchi Add End

## ディレクトリ定義
##2014/07/31 S.Noguchi Mod Start
#  L_rogupasu="/var/EBS/jp1/PEBSITO/log"      ##ログファイル格納ディレクトリ
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##ログファイル格納ディレクトリ
##2014/07/31 S.Noguchi Mod End

## 変数定義
  L_hizuke=`/bin/date "+%y%m%d"`     ##シェル実行日付
  L_sherumei=`/bin/basename $0`      ##実行シェル名
##2022/01/06 S.Yamada Mod Start   ※ E_本稼動_17512対応
#  L_hosutomei=`/bin/hostname`       ##実行ホスト名
  L_hosutomei=`/bin/hostname -s`     ##実行ホスト名
##2022/01/06 S.Yamada Mod End     ※ E_本稼動_17512対応
  L_enbufairu="ZCZZCOMN.env"         ##基盤共通環境変数ファイル名
  L_ijou=8                           ##シェル異常終了時の戻り値

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##ログファイル(フルパス)
##2022/01/06 S.Yamada Mod Start   ※ E_本稼動_17512対応
##  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairu}"                                              ##基盤共通環境変数ファイル(フルパス)
  L_enbufairu=`dirname $0`"/${L_enbufairu}"                                                       ##基盤共通環境変数ファイル(フルパス)
##2022/01/06 S.Yamada Mod End     ※ E_本稼動_17512対応


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
##2022/01/06 S.Yamada Mod Start   ※ E_本稼動_17512対応
##    if [ -f ${TE_ZCZZHYOUJUNSHUTURYOKU} ]
    if [ -f "${TE_ZCZZHYOUJUNSHUTURYOKU}" ]
##2022/01/06 S.Yamada Mod End     ※ E_本稼動_17512対応
      then
        L_rogushuturyoku "標準出力一時ファイル削除実行"
        rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
    fi

##2022/01/06 S.Yamada Mod Start   ※ E_本稼動_17512対応
##    if [ -f ${TE_ZCZZHYOUJUNERA} ]
    if [ -f "${TE_ZCZZHYOUJUNERA}" ]
##2022/01/06 S.Yamada Mod End     ※ E_本稼動_17512対応
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


### Webサーバ起動 ###

  ## コマンド設定
  L_apkaisi="${TE_ZCZZAPKOMANDOPASU}/adapcctl.sh start"     ##Webサーバ起動コマンド
  L_appskaisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh start"   ##APPSリスナー起動コマンド

  L_rogushuturyoku "Webサーバを起動します。"

  ${L_apkaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
  /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応

## 戻り値から、adapcctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00400}"
  else
      L_rogushuturyoku "${TE_ZCZZ00402}"
      echo "${TE_ZCZZ00402}" 1>&2
      L_shuryo ${L_ijou}
  fi


### APPSリスナー起動 ###

  L_rogushuturyoku "APPSリスナーを起動します。"

  ${L_appskaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
  /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応

## 戻り値から、adalnctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00401}"
  else
      L_rogushuturyoku "${TE_ZCZZ00402}"
      echo "${TE_ZCZZ00402}" 1>&2
      L_shuryo ${L_ijou}
  fi

## 2018/01/12 Add Start ※E_本稼動_14800対応
### Formsサーバ起動 ###

  ## コマンド設定
  L_formskaisi="${TE_ZCZZAPKOMANDOPASU}/adfrmctl.sh start"     ##Formsサーバ起動コマンド

  L_rogushuturyoku "Formsサーバを起動します。"

  ${L_formskaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
  /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応

## 戻り値から、adfrmctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00403}"
  else
      L_rogushuturyoku "${TE_ZCZZ00402}"
      echo "${TE_ZCZZ00402}" 1>&2
      L_shuryo ${L_ijou}
  fi
## 2018/01/12 Add End ※E_本稼動_14800対応


### APサーバ起動確認 ###

  L_rogushuturyoku "APサーバ起動確認"
  L_rogushuturyoku "APサーバの起動を待っています。"
  sleep ${TE_ZCZZTAIKI}


## Webサーバ起動確認
  L_rogushuturyoku "Webサーバ起動確認"
##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep iAS | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
  /bin/ps -ef | grep `/usr/bin/whoami` | /bin/grep iAS | /bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応
    then
      L_rogushuturyoku "${TE_ZCZZ00402}"
      echo "${TE_ZCZZ00402}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "Webサーバの起動を確認しました。"

## APPSリスナー起動確認
  L_rogushuturyoku "APPSリスナー起動確認"
##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
  /bin/ps -ef | grep `/usr/bin/whoami` | /bin/grep APPS | /bin/grep inherit | /bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応
    then
      L_rogushuturyoku "${TE_ZCZZ00402}"
      echo "${TE_ZCZZ00402}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "APPSリスナーの起動を確認しました。"

## 2018/01/12 Add Start ※E_本稼動_14800対応
## Formsサーバ起動確認
  L_rogushuturyoku "Formsサーバ起動確認"
##2022/01/06 S.Yamada Mod Start    ※ E_本稼動_17512対応
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep f60srvm | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
  /bin/ps -ef | grep `/usr/bin/whoami` | /bin/grep f60srvm |/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
##2022/01/06 S.Yamada Mod End      ※ E_本稼動_17512対応
    then
      L_rogushuturyoku "${TE_ZCZZ00402}"
      echo "${TE_ZCZZ00402}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "Formsサーバの起動を確認しました。"
## 2018/01/12 Add End ※E_本稼動_14800対応
  L_rogushuturyoku "APサーバを起動しました。"


### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
