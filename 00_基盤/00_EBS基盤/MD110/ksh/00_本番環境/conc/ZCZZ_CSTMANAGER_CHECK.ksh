#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_CSTMANAGER_CHECK.ksh                                             ##
##                                                                            ##
##   [概要]                                                                   ##
##      最新のコストマネージャがエラーとなっていないことをチェックします      ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK 小山             2019/05/14 1.0.0                 ##
##        更新履歴：   SCSK 山田             2021/12/24 3.0.0                 ##
##                       E_本稼動_17512対応                                   ##
##                         ・基幹システムリフト対応                           ##
##                         ・ホスト名取得引数追加                             ##
##                         ・コマンドのパス変更                               ##
##                         ・サーバー分離に伴いDB環境変数取得からCONC環境変数 ##
##                           取得へ変更                                       ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
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

##2021/12/24 S.Yamada Mod Start         ※E_本稼動_17512対応
##L_hosutomei=`/bin/hostname`                     #ホスト名
L_hosutomei=`/bin/hostname -s`                  #ホスト名
##2021/12/24 S.Yamada Mod End           ※E_本稼動_17512対応

L_hizuke=`/bin/date "+%y%m%d"`                  #日付
L_jikan=`/bin/date "+%Y%m%d%H%M"`               #日付+現在時刻
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"   #ログファイル格納ディレクトリ
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名

##2021/12/24 S.Yamada Mod Start         ※E_本稼動_17512対応
##L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名
L_zczzcomn=`dirname $0`"/ZCZZCOMN.env"          #共通環境変数ファイル名
##2021/12/24 S.Yamada Mod End           ※E_本稼動_17512対応

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

##2021/12/24 S.Yamada Mod Start         ※E_本稼動_17512対応
### 基盤DB環境変数 ###
##if [ -r "${TE_ZCZZDB}" ]
##then
##   . ${TE_ZCZZDB}
##else
##   echo "ZCZZ00003:[エラー] ZCZZDB.env が存在しない、または見つかりません。  HOST=${L_hosutomei}" | /usr/bin/tee -a ${L_rogumei} 1>&2
##   L_shuryo ${TE_ZCZZIJOUSHURYO}
##fi
##### CONC環境設定 #####
if [ -r ${TE_ZCZZCONC} ]
then
   . ${TE_ZCZZCONC}
else
   echo "ZCZZ00003:[エラー] ZCZZCONC.env が存在しない、または見つかりません。  HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi
##2021/12/24 S.Yamada Mod End           ※E_本稼動_17512対応

### コストマネージャ実行確認 ###
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SET LINES 200
SET PAGES 500
SET HEAD OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_LANGUAGE='Japanese';

SELECT fcr.request_id RequestId,
       fcr.request_date RequestDt,
       fcr.phase_code Phase,
       fcr.status_code Status,
       fcr.last_update_date
       FROM
       apps.fnd_concurrent_requests fcr,
       apps.fnd_concurrent_programs fcp
       WHERE fcp.application_id = 702
       AND fcp.concurrent_program_name = 'CMCTCM'
       AND fcr.concurrent_program_id = fcp.concurrent_program_id
       AND fcr.phase_code = 'C'
       AND fcr.REQUEST_ID =  (SELECT max(fcr2.request_id)
                                FROM apps.fnd_concurrent_requests fcr2,
                                     apps.fnd_concurrent_programs fcp2
                               WHERE fcp2.application_id = 702
                                 AND fcp2.concurrent_program_name = 'CMCTCM'
                                 AND fcr2.concurrent_program_id = fcp2.concurrent_program_id )
;

exit
EOF

### SQL 終了判定 ###
if [ $? -ne 0 ]
then
##   L_rogushuturyoku "${TE_ZCZZ02101}"
##   echo "${TE_ZCZZ02101}" 1>&2
##   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "コストマネージャ稼働状況取得でエラー発生"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### 実行中コストマネージャ存在チェック ###
##2021/12/24 S.Yamada Mod Start   ※E_本稼動_17512対応
#if [ `/usr/bin/cat "${TE_ZCZZHYOUJUNSHUTURYOKU}" | wc -l` -ne 0 ]
if [ `/bin/cat "${TE_ZCZZHYOUJUNSHUTURYOKU}" | wc -l` -ne 0 ]
##2021/12/24 S.Yamada Mod End     ※E_本稼動_17512対応
then
##   L_rogushuturyoku "${TE_ZCZZ02102}"
##   echo "${TE_ZCZZ02102}" 1>&2
##   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "コストマネージャが稼動していません。"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
