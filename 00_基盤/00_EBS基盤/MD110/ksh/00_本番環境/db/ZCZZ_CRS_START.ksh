#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBオンライン・CRSサービス起動処理                                 ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/05/22 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/05/22 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・CRSの環境設定ファイルの読み込みを追加            ##
##                         ・CRS起動処理の変更                                ##
##                         ・CRSの起動確認時の判定方法を変更                  ##
##                         ・開始メッセージID変更                             ##
##                         ・シェル名変更                                     ##
##                         ・CRS起動後ASMインスタンス起動までの時間を考慮し   ##
##                           ループ処理を追加                                 ##
##                     SCSK 北河             2015/03/26 2.0.1                 ##
##                       E_本稼動_12712対応                                   ##
##                         ・CRS起動確認処理変更                              ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_CRS_START.ksh                      ##
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
  L_crsfairumei="ZCZZCRS.env"        ##CRS環境設定ファイル名
##2014/07/31 S.Takahashi Add End
  L_ijou=8                           ##シェル異常終了時のリターンコード

## ファイル定義
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##ログファイル(フルパス)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##基盤共通環境変数ファイル(フルパス)
##2014/07/31 S.Takahashi Add Start
  L_crsfairu=`/usr/bin/dirname $0`"/${L_crsfairumei}"                                               ##CRS環境設定ファイル(フルパス)
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

##2014/07/31 S.Takahashi Add Start
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
##2014/07/31 S.Takahashi Add End


## コマンド設定
##2014/07/31 S.Takahashi Mod Start
#  L_crskaisi="/ebsloc/PEBSITO/PEBSITOcrs/10.2.0/bin/crsctl start crs"   ##CRS起動コマンド
  L_crskaisi="crsctl start crs"   ##CRS起動コマンド
##2014/07/31 S.Takahashi Mod End

### CRS起動 ###

  L_rogushuturyoku "CRSを起動します。"

  ${L_crskaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## 戻り値から、crsctlの動作を判定
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01300}"
  else
    L_rogushuturyoku "${TE_ZCZZ01301}"
    echo "${TE_ZCZZ01301}" 1>&2
    L_shuryo ${L_ijou}
  fi


### CRS起動確認 ###

  L_rogushuturyoku "CRS起動確認"
  L_rogushuturyoku "CRSの起動を待っています。"
##2014/07/31 S.Takahashi Mod Start
#  sleep ${TE_ZCZZCRSTAIKI}
#
#  /usr/bin/ps -ef | /usr/bin/grep "ocssd.bin" | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ01301}"
#      echo "${TE_ZCZZ01301}" 1>&2
#      L_shuryo ${L_ijou}
#  fi
##2015/03/26 T.Kitagawa Add Start
## コマンド・変数設定
  L_crschk_cmd="crsctl check crs"                   ##CRSサービスチェックコマンド
  L_crsstat_cmd="crsctl status resource -t -init"   ##CRSリソースチェックコマンド
  L_crschk_str="online"                             ##CRSサービスの起動判定対象文字列
  L_crsstat_str="ONLINE +ONLINE"                    ##CRSリソースの起動判定対象文字列(正規表現)
  L_crschk_num=4                                    ##CRSサービスのonlineの数
  L_crsstat_num=12                                  ##CRSリソースの"ONLINE ONLINE"の数
##2015/03/26 T.Kitagawa Add End
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZCRS_WAITCNT}" ]
  do  
    sleep ${TE_ZCZZCRSTAIKI}

##2015/03/26 T.Kitagawa Mod Start
#    /usr/bin/ps -ef | /usr/bin/egrep 'ocssd.bin|osysmond.bin|asm_pmon|LISTENER_ASM' | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#
#    if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -lt 4 ]
#      then
#        if [ "$cnt" -eq "${TE_ZCZZCRS_WAITCNT}" ]
#         then
#           L_rogushuturyoku "${TE_ZCZZ01301}"
#           echo "${TE_ZCZZ01301}" 1>&2
#           L_shuryo ${L_ijou}
#        fi
#    elif [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ge 4 ]
#      then
#        break;
#    fi
    L_rogushuturyoku "$cnt回目確認"
    L_rogushuturyoku "${L_crschk_cmd} 確認"

    ##CRSサービスチェックコマンド結果を標準出力・エラーファイルに上書き
    ${L_crschk_cmd} 1> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

    ##標準出力ファイルに出力されている${L_crschk_str}の個数の判定
    if [ `/usr/bin/grep ${L_crschk_str} ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l` -eq ${L_crschk_num} ]
      then
        L_rogushuturyoku "${L_crsstat_cmd} 確認"

        ##CRSリソースチェックコマンド結果を標準出力・エラーファイルに追記
        ${L_crsstat_cmd} 1>> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2>> ${TE_ZCZZHYOUJUNERA}

        ##標準出力ファイルに出力されている${L_crsstat_str}の個数の判定
        if [ `/usr/bin/grep -E "${L_crsstat_str}" ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l` -eq ${L_crsstat_num} ]
          then
            ##CRS起動確認終了(ループ終了)
            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
            break;
        fi
    fi

    ##判定回数確認
    if [ "$cnt" -eq "${TE_ZCZZCRS_WAITCNT}" ]
      then
        ##チェックコマンド確認が指定判定回数以内に完了しない場合エラー
        L_rogushuturyoku "${TE_ZCZZ01301}"
        echo "${TE_ZCZZ01301}" 1>&2
        /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
        L_shuryo ${L_ijou}
    fi
##2015/03/26 T.Kitagawa Mod End

    let cnt=cnt+1
  done
##2014/07/31 S.Takahashi Mod End

  L_rogushuturyoku "CRSの起動を確認しました。"


### シェルの終了 ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
