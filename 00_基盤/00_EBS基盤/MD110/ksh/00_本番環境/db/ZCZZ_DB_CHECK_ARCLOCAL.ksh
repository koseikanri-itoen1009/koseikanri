#!/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          アーカイブログファイル・ローカル出力監視                          ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK   金岩           2014/07/31 2.0.0                 ##
##        更新履歴：   SCSK   金岩           2014/07/31 2.0.0                 ##
##                       初版/HWリプレース対応(リプレース_00007)              ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_DB_CHECK_ARCLOCAL.ksh              ##
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
##2021/09/30 Hitachi,Ltd Mod Start
#  L_hosutomei=`/bin/hostname`        ##実行ホスト名
  L_hosutomei=`/bin/hostname -s`     ##実行ホスト名
##2021/09/30 Hitachi,Ltd Mod End
  L_enbufairumei="ZCZZCOMN.env"      ##基盤共通環境変数ファイル名
  L_ijou=8                           ##シェル異常終了時のリターンコード

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##ログファイル(フルパス)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##基盤共通環境変数ファイル(フルパス)


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

## ローカルディスクに出力されているアーカイブログファイルの数チェック(メイン)
##2021/09/30 Hitachi,Ltd Mod Start
#  L_archfilesu=`/usr/bin/ls -l ${TE_ZCZZLOCALARCHPASU}/thread* | /usr/bin/wc -l`
  L_archfilesu=`/bin/ls -l ${TE_ZCZZLOCALARCHPASU}/thread* | /usr/bin/wc -l`
##2021/09/30 Hitachi,Ltd Mod End

  if [ ${L_archfilesu} -ge ${TE_ZCZZLOCALARCHMAXCNT} ]
    then
      L_message="${L_hosutomei} [${TE_ZCZZLOCALARCHPASU}] more than ${TE_ZCZZLOCALARCHMAXCNT} files are stored at `date +'%a %b %d %I:%M:%S %Y'`"
      /opt/jp1base/bin/jevsend -i ${TE_ZCZZLOCALARCH_EVENTID} -m "${L_message}" -e SEVERITY=Warning
  fi
  
## ローカルディスクに出力されているアーカイブログファイルの数チェック(ミラー)
##2021/09/30 Hitachi,Ltd Mod Start
  #L_archfilesu=`/usr/bin/ls -l ${TE_ZCZZLOCALARCHMPASU}/thread* | /usr/bin/wc -l`
  L_archfilesu=`/bin/ls -l ${TE_ZCZZLOCALARCHMPASU}/thread* | /usr/bin/wc -l`
##2021/09/30 Hitachi,Ltd Mod End

  if [ ${L_archfilesu} -ge ${TE_ZCZZLOCALARCHMAXCNT} ]
    then
      L_message="${L_hosutomei} [${TE_ZCZZLOCALARCHMPASU}] more than ${TE_ZCZZLOCALARCHMAXCNT} files are stored at `date +'%a %b %d %I:%M:%S %Y'`"
      /opt/jp1base/bin/jevsend -i ${TE_ZCZZLOCALARCH_EVENTID} -m "${L_message}" -e SEVERITY=Warning
  fi
  
### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
