#!/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBオンライン・CRSサービス停止処理                                 ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/05/22 1.0.1                 ##
##        更新履歴：   Oracle 中村           2008/10/02 1.1.0                 ##
##                     SCS    川田           2008/11/28 1.2.0                 ##
##                       1.2版                                                ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・CRSの停止確認時の判定方法を変更                  ##
##                         ・シェル名変更                                     ##
##                         ・CRS停止コマンドの変更                            ##
##                         ・CRSリソース停止コマンドの変更                    ##
##                         ・開始メッセージID変更                             ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_CRS_STOP.ksh                       ##
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
## 2008/11/28 CRS変数定義追加 川田
  L_crsfairumei="ZCZZCRS.env"        ##CRS環境設定ファイル名
## 2008/11/28 追加END
  L_ijou=8                           ##シェル異常終了時のリターンコード

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##ログファイル(フルパス)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##基盤共通環境変数ファイル(フルパス)
## 2008/11/28 CRSファイル定義追加 川田
  L_crsfairu=`/usr/bin/dirname $0`"/${L_crsfairumei}"                                               ##CRS環境設定ファイル(フルパス)
## 2008/11/28 追加END


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
    
    ### パーミッション変更 ###
    chmod 666 ${L_rogumei}
    
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

## 2008/11/28 追加 川田
## CRS環境設定ファイル読み込み
  L_rogushuturyoku "CRS環境設定ファイルを読み込みます。"

  if [ -r "${L_crsfairu}" ]
    then
      . ${L_crsfairu}
      L_rogushuturyoku "CRS環境設定ファイルを読み込みました。"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_crsfairu}` が存在しない、または見つかりません。   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_crsfairu}` が存在しない、または見つかりません。   HOST=${L_hosutomei}" 1>&2
      L_shuryo ${L_ijou}
  fi
## 2008/11/28 追加END


## コマンド設定
##2014/07/31 S.Takahashi Mod Start
#  L_crsteisi="/ebsloc/PEBSITO/PEBSITOcrs/10.2.0/bin/crsctl stop crs"   ##CRS停止コマンド
  L_crsteisi="crsctl stop crs"   ##CRS停止コマンド
##2014/07/31 S.Takahashi Mod End

## 2008/11/28 CRSリソース停止コマンド追加 川田
##2014/07/31 S.Takahashi Mod Start
#  L_crsappsteisi="/ebsloc/PEBSITO/PEBSITOcrs/10.2.0/bin/srvctl stop nodeapps -n ${L_hosutomei}"
  L_crsappsteisi="srvctl stop nodeapps -n ${L_hosutomei}"
##2014/07/31 S.Takahashi Mod End
## 2008/11/28 追加END


### CRS停止 ###

  L_rogushuturyoku "CRSを停止します。"

## 2008/11/28 CRSリソース停止コマンド追加 川田
  ${L_crsappsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
## 2008/11/28 追加END

  ${L_crsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
##2021/09/30 Hitachi,Ltd Mod Start
  #/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
  /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 
##2021/09/30 Hitachi,Ltd Mod End

## 戻り値から、crsctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01400}"
  else
    L_rogushuturyoku "${TE_ZCZZ01401}"
    echo "${TE_ZCZZ01401}" 1>&2
    L_shuryo ${L_ijou}
  fi


### CRS停止確認 ###

  L_rogushuturyoku "CRS停止確認"
  L_rogushuturyoku "CRSの停止を待っています。"
  
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZ_WAITCNT}" ]
  do
     sleep ${TE_ZCZZCRSTAIKI}
##2014/07/31 S.Takahashi Mod Start     
#     /usr/bin/ps -ef | /usr/bin/egrep "ocssd.bin |evmd.bin |evmlogger.bin |oclsomon.bin |crsd.bin |ons -d |crs/10.2.0/jdk/jre/bin/java" |/usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2021/09/30 Hitachi,Ltd Mod Start
#     /usr/bin/ps -ef | /usr/bin/egrep 'ocssd.bin|osysmond.bin|asm_pmon' | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
     /bin/ps -ef | /bin/egrep 'ocssd.bin|osysmond.bin|asm_pmon' | /bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2021/09/30 Hitachi,Ltd Mod End
##2014/07/31 S.Takahashi Mod End
##2021/09/30 Hitachi,Ltd Mod Start
#     if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
     if [ `/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
##2021/09/30 Hitachi,Ltd Mod Start
       then
        if [ "$cnt" -eq "${TE_ZCZZ_WAITCNT}" ]
         then
            L_rogushuturyoku "${TE_ZCZZ01401}"
            echo "${TE_ZCZZ01401}" 1>&2
            L_shuryo ${L_ijou}
        fi
     
     else
        break;
     fi

     let cnt=cnt+1
  done

  L_rogushuturyoku "CRSの停止を確認しました。"

### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
