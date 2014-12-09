#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBオンライン・コンカレント起動処理                                ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/05/22 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/05/22 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・コンカレント環境変数の読み込みを追加             ##
##                         ・cmcleanの処理を追加                              ##
##                         ・シェル名変更                                     ##
##                         ・開始メッセージID変更                             ##
##                         ・ZCZZCONC.env読み込み追加                         ##
##                         ・プロセス確認処理変更                             ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_CONC_START.ksh                     ##
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
  L_hosutomei=`/bin/hostname`        ##実行ホスト名
  L_enbufairumei="ZCZZCOMN.env"      ##基盤共通環境変数ファイル名
##2014/07/31 S.Takahashi Add Start
  L_kurinfairumei="ZCZZ_CMCLEAN.sql" ##コンカレントマネージャ管理表のクリーンアップスクリプト名
  L_apps='APPS/APPS'                 ##コマンド実行ユーザ名
##2014/07/31 S.Takahashi Add End
  L_ijou=8                           ##シェル異常終了時のリターンコード

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##ログファイル(フルパス)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##基盤共通環境変数ファイル(フルパス)
##2014/07/31 S.Takahashi Add Start
  L_kurinfairu=`/usr/bin/dirname $0`"/${L_kurinfairumei}"                                           ##コンカレントマネージャ管理表のクリーンアップスクリプト名(フルパス)
##2014/07/31 S.Takahashi Add End

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

##2014/07/31 S.Takahashi Add Start
#コンカレント環境設定
  if [ -r ${TE_ZCZZCONC} ]
  then
     . ${TE_ZCZZCONC}
  else
     echo "ZCZZ00003:[Error] ZCZZCONC.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
          | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
     L_shuryo ${TE_ZCZZIJOUSHURYO}
  fi

  L_rogushuturyoku "環境設定ファイル読込み 終了"
##2014/07/31 S.Takahashi Add End

## コマンド設定
  L_konkarentokaisi="${TE_ZCZZAPKOMANDOPASU}/adcmctl.sh start apps/apps"             ##コンカレント開始コマンド

##2014/07/31 S.Takahashi Add Start
###コンカレントマネージャ管理表のクリーンアップ
  L_rogushuturyoku "コンカレントマネージャ管理表のクリーンアップ処理を実行します。"
  sqlplus -s ${L_apps} << EOF >> ${L_rogumei}
  set echo on;
  @${L_kurinfairu}
  commit;
  EXIT;
EOF
  L_rogushuturyoku "${TE_ZCZZ01502}"
##2014/07/31 S.Takahashi Add End

### コンカレントマネージャ起動 ###

  L_rogushuturyoku "コンカレントマネージャを起動します。"

  ${L_konkarentokaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、adcmctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01500}"
  else
      L_rogushuturyoku "${TE_ZCZZ01501}"
      echo "${TE_ZCZZ01501}" 1>&2
      L_shuryo ${L_ijou}
  fi


## コンカレントマネージャ起動確認
  L_rogushuturyoku "コンカレントマネージャ起動確認"
  L_rogushuturyoku "コンカレントマネージャの起動を待っています。"
##2014/07/31 S.Takahashi Mod Start
#  sleep ${TE_ZCZZCONCTAIKI}

#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep FNDLIBR | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ01501}"
#      echo "${TE_ZCZZ01501}" 1>&2
#      L_shuryo ${L_ijou}
#  fi
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZ_WAITCNT}" ]
  do
    sleep ${TE_ZCZZCONCTAIKI}
    /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/egrep "FNDLIBR|FNDSM|FNDIMON" | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
    if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -lt 3 ]
      then
        if [ "$cnt" -eq "${TE_ZCZZ_WAITCNT}" ]
          then
            L_rogushuturyoku "${TE_ZCZZ01501}"
            echo "${TE_ZCZZ01501}" 1>&2
            L_shuryo ${L_ijou}
        fi
     else
        break;
     fi
     let cnt=cnt+1
  done
##2014/07/31 S.Takahashi Mod End

  L_rogushuturyoku "コンカレントマネージャの起動を確認しました。"
  L_rogushuturyoku "コンカレントマネージャを起動しました。"


### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
