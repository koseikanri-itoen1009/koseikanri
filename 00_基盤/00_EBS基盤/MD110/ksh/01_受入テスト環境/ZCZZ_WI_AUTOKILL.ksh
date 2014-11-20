#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##      PGAを閾値以上使用しているセッションをkillする(T4用)                   ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCS 川田              2010/02/22 1.0.0                 ##
##        更新履歴：   SCS 川田              2010/02/22 1.0.0                 ##
##        更新履歴：   SCS 北河              2010/03/23 1.0.1                 ##
##                       閾値を2GBから1GBに変更                               ##
##        更新履歴：   SCS 吉元              2011/10/04 1.0.2                 ##
##                       閾値に占有時間を追加                                 ##
##                       対象機能を参照タイプ定義に変更                       ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      1 : 容量(MB)                                                          ##
##      2 : 時間(秒)                                                          ##
##                                                                            ##
##   [使用方法]                                                               ##
##      ZCZZ_WI_AUTOKILL.ksh                                                  ##
##                                                                            ##
##    Copyright 株式会社伊藤園 U5000プロジェクト 2007-2009                    ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_rogupasu="/var/log/jp1/T4"    #ログパス
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .sh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名

##シェル固有環境変数
KILL_PID_LIST=/var/tmp/ZCZZ_kill_pid_list_temp2.lst    #kill対象PIDリスト一時ファイル

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
  
  L_Modorichi=${1:-0}
  exit ${L_Modorichi}
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
## 2011/10/04 t.yoshimoto Mod Start E_本稼動_07971
##   echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
  echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei} STATUS:8" \
       | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
## 2011/10/04 t.yoshimoto Mod End E_本稼動_07971
  L_shuryo 8
fi

### DB環境設定 ###
if [ -r ${TE_ZCZZDB} ]
then
  . ${TE_ZCZZDB}
else
## 2011/10/04 t.yoshimoto Mod Start E_本稼動_07971
##   echo "ZCZZ00003:[Error] ZCZZDB.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
  echo "ZCZZ00003:[Error] ZCZZDB.env が存在しない、または見つかりません。 HOST=${L_hosutomei} STATUS:${TE_ZCZZIJOUSHURYO}" \
       | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
##   L_shuryo ${TE_ZCZZKEIKOKUSHURYO}
  L_shuryo ${TE_ZCZZIJOUSHURYO}
## 2011/10/04 t.yoshimoto Mod End E_本稼動_07971
fi

## 2011/10/04 t.yoshimoto Add Start E_本稼動_07971
### INパラメータ取得 ###
L_para1=${1}
L_para2=${2}
## 2011/10/04 t.yoshimoto Add End E_本稼動_07971

### kill対象PID取得 ###
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> /dev/null
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 120
set pages 500
col name format a50
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set head off
set feedback off
spool ${KILL_PID_LIST}
-- 2011/10/04 t.yoshimoto Mod Start E_本稼動_07971
--select p.spid, s.SQL_ID, round(p.PGA_USED_MEM/1024/1024) PGA_MG
--from v\$session s, v\$process p
--where s.paddr = p.addr and status = 'ACTIVE' and Module is not null and round(p.PGA_USED_MEM/1024/1024) > 1000
--and s.Module in ('ARWI', 'GLWI');
SELECT p.spid
      ,s.sql_id
      ,ROUND(p.pga_used_mem / 1024 / 1024) pga_mg
      ,s.seconds_in_wait
FROM v\$session s
    ,v\$process p
    ,fnd_lookup_values_vl lvvl
WHERE s.paddr           = p.addr
AND   s.status          = 'ACTIVE'
AND   s.module          = lvvl.meaning
AND   lvvl.lookup_type  = 'XXCCP1_WI_KILL_MODULE'
AND   lvvl.enabled_flag = 'Y'
AND   TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
                         AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
AND   ((ROUND(p.pga_used_mem / 1024 / 1024) > ${L_para1} )
  OR   (s.seconds_in_wait >= ${L_para2}));
-- 2011/10/04 t.yoshimoto Mod End E_本稼動_07971
spool off
exit
EOF

### SQL 終了判定 ###

if [ $? != 0 ]
then
## 2011/10/04 t.yoshimoto Mod Start E_本稼動_07971
##   echo "[ERROR]:kill対象PID取得に失敗しました" >> ${L_rogumei}
##   exit 8
  echo "[ERROR]:kill対象PID取得に失敗しました。 STATUS:${TE_ZCZZIJOUSHURYO}" >> ${L_rogumei}
  exit ${TE_ZCZZIJOUSHURYO}
## 2011/10/04 t.yoshimoto Mod Start E_本稼動_07971
fi

### webInquiryプロセスkill ###
## 2011/10/04 t.yoshimoto Mod Start E_本稼動_07971
##while read L_KILL_PID L_SQL_ID L_PGA_SIZE
while read L_KILL_PID L_SQL_ID L_PGA_SIZE L_SESSION_IN_WAIT
## 2011/10/04 t.yoshimoto Mod End E_本稼動_07971
do 
  if [ -n "${L_KILL_PID}" ] #空白行判定（spoolファイルの1行目が改行のみのため）
  then
## 2011/10/04 t.yoshimoto Mod Start E_本稼動_07971
##       L_rogushuturyoku "kill PID : ${L_KILL_PID} SQL_ID : ${L_SQL_ID} PGA_SIZE : ${L_PGA_SIZE}"
    L_rogushuturyoku "kill PID : ${L_KILL_PID} SQL_ID : ${L_SQL_ID} PGA_SIZE : ${L_PGA_SIZE} SESSION_IN_WAIT : ${L_SESSION_IN_WAIT}"
## 2011/10/04 t.yoshimoto Mod End E_本稼動_07971
    kill -9 ${L_KILL_PID}

  fi
  sleep 1

done < ${KILL_PID_LIST}

### リストファイル削除 ###
rm -f ${KILL_PID_LIST} >> ${L_rogumei}

## 2011/10/04 t.yoshimoto Add Start E_本稼動_07971
### 処理終了出力（正常） ###
L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 STATUS:${TE_ZCZZSEIJOUSHURYO}"
## 2011/10/04 t.yoshimoto Add End E_本稼動_07971
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
