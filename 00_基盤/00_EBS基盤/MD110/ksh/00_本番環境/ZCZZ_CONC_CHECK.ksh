#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##      監視対象機能が長時間走行及び夜間バッチ開始時間時点で実行されていないか##
##      チェックします。                                                      ##
##          監視対象機能は参照タイプにて設定                                  ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK 小山             2015/06/12 1.0.0                 ##
##        更新者  ：   SCSK 小山             2016/06/21 1.0.1                 ##
##                  E_本稼動_13681対応 監視対象ユーザ未指定対応               ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_CONC_CHECK.ksh                     ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

##環境依存値
L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名

L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付

L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"    #ログファイル格納ディレクトリ
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名

##シェル固有環境変数用
LIMIT_OVER_LIST=/uspg/jp1/zc/shl/${L_kankyoumei}/tmp/ZCZZ_CONC_CHECK_temp.lst    #対象リスト一時ファイル

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
   ### リストファイル削除 ###
   if [ -f ${LIMIT_OVER_LIST} ]; then
     rm ${LIMIT_OVER_LIST}
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

### 基盤共通環境変数 ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env が見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

### DB環境設定 ###
if [ -r ${TE_ZCZZDB} ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[Error] ZCZZDB.env が見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

###長時間走行コンカレント取得
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> /dev/null
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 200
set pages 500
col name format a50
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set head off
set feedback off
spool ${LIMIT_OVER_LIST}

SELECT
       fcpv.user_concurrent_program_name                                     || '  ' ||
       'が長時間走行しています。'                                            || '  ' ||
       '要求ID:' || request_id                                               || '  ' ||
       'ステータス:' || decode(fcr.phase_code,'P','保留','R','実行中')       || '  ' ||
       '開始(発行)時間:' || TO_CHAR(NVL(fcr.actual_start_date,fcr.requested_start_date),'YYYY/MM/DD HH24:MI:SS') || '  ' ||
       '実行(保留)時間:' || TRUNC( TO_NUMBER( SYSDATE - NVL(fcr.actual_start_date,fcr.requested_start_date)) * 86400 )
FROM   apps.fnd_lookup_values           flv
      ,apps.fnd_concurrent_programs_vl  fcpv
      ,apps.fnd_concurrent_requests     fcr
      ,apps.fnd_user                    fu
WHERE  flv.lookup_type     = 'XXCCP_CONCURRENT_LIMIT_TIME'
AND    TRUNC(SYSDATE)  BETWEEN NVL(flv.start_date_active,TRUNC(SYSDATE))
                          AND  NVL(flv.end_date_active,  TRUNC(SYSDATE))
AND    flv.enabled_flag    = 'Y'
AND    flv.language        = userenv('LANG')
AND    flv.lookup_code     = fcpv.concurrent_program_name
AND    fcpv.concurrent_program_id = fcr.concurrent_program_id
AND    fcpv.application_id = fcr.program_application_id
AND    fcr.phase_code     in ('R','P')
-- Ver1.0.1 2016-06-21 MOD Start
-- AND    flv.attribute3,fu.user_name      = fu.user_name
AND    NVL(flv.attribute3,fu.user_name) = fu.user_name
-- Ver1.0.1 2016-06-21 MOD End
AND    fu.user_id          = fcr.requested_by
AND   (
        ( TRUNC(SYSDATE,'MI') >= TO_DATE(TO_CHAR(SYSDATE,'YYYY/MM/DD')||' ' ||flv.attribute2,'YYYY/MM/DD HH24:MI'))
        OR
        ( TRUNC( TO_NUMBER( SYSDATE - NVL(fcr.actual_start_date,fcr.requested_start_date)) * 86400 ) >= TO_NUMBER( flv.attribute1 ) ) 
       );

spool off
exit
EOF

### SQL 終了判定 ###

if [ $? != 0 ]
then
   echo "[ERROR]:長時間走行コンカレント取得に失敗しました" | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### エラー対象有無判定 ###
if [ -s ${LIMIT_OVER_LIST} ]; then
  echo "対象あり" | /usr/bin/tee -a ${L_rogumei} 1>&2
else
  echo "対象なし" | /usr/bin/tee -a ${L_rogumei} 1>&2
  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
fi

### エラー出力 ###
while read L_MESSAGE
do 
   if [ -n "${L_MESSAGE}" ] #空白行判定（spoolファイルの1行目が改行のみのため）
   then
       L_rogushuturyoku "ZCZZ00004:${L_MESSAGE}"
   fi

done < ${LIMIT_OVER_LIST}

L_shuryo ${TE_ZCZZIJOUSHURYO}

