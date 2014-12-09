#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBオンライン・コンカレント停止処理                                ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/05/22 1.0.1                 ##
##        更新履歴：   Oracle 中村           2008/10/02 1.1.0                 ##
##                       1.1版                                                ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      ZCZZ_PEBSCONC_STOP.ksh                                                ##
##                                                                            ##
##    Copyright 株式会社伊藤園 U5000プロジェクト 2007-2009                    ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

## ディレクトリ定義
  L_ROGUPASU="/var/EBS/jp1/PEBSITO/log"      ##ログファイル格納ディレクトリ

## 変数定義
  L_hizuke=`/bin/date "+%y%m%d"`     ##シェル実行日付
  L_sherumei=`/bin/basename $0`      ##実行シェル名
  L_hosutomei=`/bin/hostname`        ##実行ホスト名
  L_enbufairumei="ZCZZCOMN.env"      ##基盤環境環境変数ファイル名
  L_ijou=8                           ##シェル異常終了時の戻り値

## ファイル定義
  L_rogumei="${L_ROGUPASU}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##ログファイル(フルパス)
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

## コマンド設定
  L_konkarentoteisi="${TE_ZCZZAPKOMANDOPASU}/adcmctl.sh abort apps/apps"                        ##コンカレントマネージャ停止コマンド

### コンカレントマネージャ停止 ###

  L_rogushuturyoku "コンカレントマネージャを停止します。"

  ${L_konkarentoteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、adcmctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01600}"
  else
      L_rogushuturyoku "${TE_ZCZZ01601}"
      echo "${TE_ZCZZ01601}" 1>&2
      L_shuryo ${L_ijou}
  fi


## コンカレントマネージャ停止確認
  L_rogushuturyoku "コンカレントマネージャ停止確認"
  L_rogushuturyoku "コンカレントマネージャの停止を待っています。"
  
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZ_WAITCNT}" ]
  do  
  sleep ${TE_ZCZZCONCTAIKI}
  /usr/bin/ps -ef | grep `/usr/bin/whoami` |/usr/bin/egrep "FNDLIBR |FNDSM" | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
     if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
       then
        if [ "$cnt" -eq "${TE_ZCZZ_WAITCNT}" ]
         then
           L_rogushuturyoku "${TE_ZCZZ01601}"
           echo "${TE_ZCZZ01601}" 1>&2
            L_shuryo ${L_ijou}
        fi
     
     else
        break;
     fi

     let cnt=cnt+1
  done

  L_rogushuturyoku "コンカレントマネージャの停止を確認しました。"


### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
