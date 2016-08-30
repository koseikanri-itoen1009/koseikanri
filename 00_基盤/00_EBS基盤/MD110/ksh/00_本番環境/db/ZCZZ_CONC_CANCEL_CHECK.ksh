#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_CONC_CANCEL_CHECK.ksh                                            ##
##                                                                            ##
##   [概要]                                                                   ##
##      取消済コンカレント(無効化ユーザで実行されたもの)が検索対象期間内に    ##
##      存在しないかチェックします。                                          ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK 北河             2016/01/21 1.0.0                 ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      $1 : 検索対象期間                                                     ##
##            ALL(全期間対象)                                                 ##
##            NIGHT(TE_ZCZZCONC_TO_JIKOKUとTE_ZCZZCONC_KIKANで計算した期間)   ##
##            数値(入力された数値分、過去に遡った期間)                        ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_CONC_CANCEL_CHECK.ksh              ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

L_kankyoumei=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #最下層のカレントディレクトリ名
L_sherumei=`/bin/basename $0`                   #シェル名
L_hosutomei=`/bin/hostname`                     #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`                  #日付
L_jikan=`/bin/date "+%Y%m%d%H%M"`               #日付+現在時刻
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"   #ログファイル格納ディレクトリ
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名
L_hikisu=`echo ${1} | tr [a-z] [A-Z]`           #引数(all、night、数値)
L_amari=0                                       #変数を倍数で割った時の余り(初期化)
L_tsuikajouken=""                               #SQLの追加条件(初期化)

### 環境変数設定 ###
export NLS_LANG=American_America.JA16SJIS       #SQLの結果を文字化けさせない設定

################################################################################
##                                 関数定義                                   ##
################################################################################

### ログ出力処理 ###
L_rogushuturyoku()
{
   echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_rogumei}
}

### 終了処理 ###
L_shuryo()
{
   ### 一時ファイル削除 ###
   if [ -f "${TE_ZCZZHYOUJUNSHUTURYOKU}" ]
   then
      L_rogushuturyoku "標準出力一時ファイル削除実行"
      rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
   fi
   if [ -f "${TE_ZCZZHYOUJUNERA}" ]
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
##                                   Main                                     ##
################################################################################

### 処理開始出力 ###
L_rogushuturyoku "ZCZZ00001:${L_sherumei} 開始"

### 環境設定ファイル読込み ###
L_rogushuturyoku "環境設定ファイル読込み 開始"

### 基盤共通環境変数 ###
if [ -r "${L_zczzcomn}" ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[エラー] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

### 基盤DB環境変数 ###
if [ -r "${TE_ZCZZDB}" ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[エラー] ZCZZDB.env が存在しない、または見つかりません。  HOST=${L_hosutomei}" | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### 入力パラメータ確認 ###
L_rogushuturyoku "入力パラメータ確認 開始(入力パラメータ："${L_hikisu}")"

### 入力パラメータ有無確認 ###
if [ -z "${L_hikisu}" ]
then
   L_rogushuturyoku "${TE_ZCZZ01901}"
   echo "${TE_ZCZZ01901}" 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
else
   ### 入力パラメータがALLの場合 ###
   if [ "${L_hikisu}" = "ALL" ]
   then
      ### 失効済ユーザで実行された要求を全て取得する為、空白ではなくダミー条件を追加 ###
      L_tsuikajouken="AND 1 = 1"
   ### 入力パラメータがNIGHTの場合
   elif [ "${L_hikisu}" = "NIGHT" ]
   then
      ### オンライン停止前からオンライン開始までに失効済ユーザで実行された要求を取得する条件を追加 ###
      L_tsuikajouken="AND fcr.requested_start_date >= TRUNC(SYSDATE) + (${TE_ZCZZCONC_TO_JIKOKU} * 1/24/60) - (${TE_ZCZZCONC_KIKAN} * 1/24/60) \
                      AND fcr.requested_start_date <  TRUNC(SYSDATE) + (${TE_ZCZZCONC_TO_JIKOKU} * 1/24/60)"
   ### 入力パラメータがALL、NIGHT以外の場合 ###
   else
      ### 入力パラメータ数値確認(除算) ###
      L_amari=`expr ${L_hikisu} % ${TE_ZCZZCONC_BAISU}`
      ### 除算結果判定 ###
      if [ $? -ge 2 ]
      then
         L_rogushuturyoku "${TE_ZCZZ01902}"
         echo "${TE_ZCZZ01902}" 1>&2
         echo "入力パラメータ：${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      ### 入力パラメータ0確認 ###
      elif [ ${L_hikisu} -eq 0 ]
      then 
         L_rogushuturyoku "${TE_ZCZZ01902}"
         echo "${TE_ZCZZ01902}" 1>&2
         echo "入力パラメータ：${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      ### 入力パラメータ倍数確認 ###
      elif [ ${L_amari} -ne 0 ]
      then
         L_rogushuturyoku "${TE_ZCZZ01903}"
         echo "${TE_ZCZZ01903}" 1>&2
         echo "入力パラメータ：${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      ### 入力パラメータ範囲確認 ###
      elif [ ${L_hikisu} -lt ${TE_ZCZZCONC_KANKAKUSAISYO} -o ${L_hikisu} -gt ${TE_ZCZZCONC_KANKAKUSAIDAI} ]
      then
         L_rogushuturyoku "${TE_ZCZZ01904}"
         echo "${TE_ZCZZ01904}" 1>&2
         echo "入力パラメータ：${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      fi
      ### 入力パラメータが数値の場合、入力パラメータ値の範囲を検索する条件を追加 ###
      L_tsuikajouken="AND fcr.requested_start_date >= TO_DATE(SUBSTRB('${L_jikan}',1,11)||'0','YYYYMMDDHH24MI') - (${L_hikisu} * 1/24/60) \
                      AND fcr.requested_start_date <  TO_DATE(SUBSTRB('${L_jikan}',1,11)||'0','YYYYMMDDHH24MI')"
   fi
fi

### 取消済コンカレント一覧取得 ###
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SET LINES 200
SET PAGES 500
SET HEAD OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_LANGUAGE='Japanese';

  SELECT  /*+
            LEADING(FCR)
            INDEX(FCR FND_CONCURRENT_REQUESTS_N7)
          */
          fcr.completion_text || '(' || fcpv.user_concurrent_program_name || ')' AS CANCELED_REQUEST
    FROM  apps.fnd_concurrent_requests     fcr
         ,apps.fnd_concurrent_programs_vl  fcpv
   WHERE  fcr.concurrent_program_id     = fcpv.concurrent_program_id
     AND  fcr.program_application_id    = fcpv.application_id
     AND  fcr.phase_code                = 'C' --フェーズ：完了
     AND  fcr.status_code               = 'D' --ステータス：取消済
     AND  fcr.completion_text        like '%expired%' || fcr.request_id || '.'
     ${L_tsuikajouken}
ORDER BY  fcr.request_id
;

exit
EOF

### SQL 終了判定 ###
if [ $? -ne 0 ]
then
   L_rogushuturyoku "${TE_ZCZZ01905}"
   echo "${TE_ZCZZ01905}" 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### 取消済コンカレント存在チェック ###
if [ `/usr/bin/cat "${TE_ZCZZHYOUJUNSHUTURYOKU}" | wc -l` -ne 0 ]
then
   L_rogushuturyoku "${TE_ZCZZ01906}"
   echo "${TE_ZCZZ01906}" 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
