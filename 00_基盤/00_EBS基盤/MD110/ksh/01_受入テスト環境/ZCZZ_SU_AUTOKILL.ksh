#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##      一時表領域を1時間以上使用している下記機能のプロセスをkillする(T4用)   ##
##          1:クイック受注(OEXOETEL)                                          ##
##          2:AR入金(ARXRWMAI)                                                ##
##          3:AR取引(ARXTWMAI)                                                ##
##          4:AR回収(ARXCWMAI)                                                ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCS 吉元              2011/07/13 1.0.0                 ##
##        更新履歴：                                                          ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      ZCZZ_SU_AUTOKILL.ksh                                                  ##
##                                                                            ##
##    Copyright 株式会社伊藤園 U5000プロジェクト 2007-2009                    ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_rogupasu="/var/log/jp1/T4"             #ログパス
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .sh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名

##シェル固有環境変数
KILL_PID_LIST=/var/tmp/ZCZZ_kill_pid_list_temp.lst    #kill対象PIDリスト一時ファイル

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
   
   L_modorichi=${1:-0}
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
   echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了"
   L_shuryo 8
fi

### DB環境設定 ###
if [ -r ${TE_ZCZZDB} ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[Error] ZCZZDB.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

###一時表領域 kill対象PID取得
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

SELECT s.module
      ,p.spid
      ,s.sql_id
      ,MAX(s.seconds_in_wait) seconds_in_wait
FROM   v\$sort_usage su
      ,v\$session    s
      ,v\$process    p
      ,fnd_lookup_values_vl lvvl
WHERE  su.session_addr = s.saddr
AND    s.paddr         = p.addr
AND    s.status        = 'ACTIVE'
AND    s.module        = lvvl.meaning
AND    lvvl.lookup_type  = 'XXCCP1_SU_KILL_MODULE'
AND    lvvl.enabled_flag = 'Y'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
                          AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
AND    s.seconds_in_wait >= 3600
GROUP BY s.module
        ,p.spid
        ,s.sql_id;

spool off
exit
EOF

### SQL 終了判定 ###

if [ $? != 0 ]
then
   echo "[ERROR]:kill対象PID取得に失敗しました" >> ${L_rogumei}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了"
   exit 8
fi

### プロセスkill ###
while read L_MODULE L_KILL_PID L_SQL_ID L_SESSION_IN_WAIT
do 
   if [ -n "${L_KILL_PID}" ] #空白行判定（spoolファイルの1行目が改行のみのため）
   then
       L_rogushuturyoku "kill MODULE : ${L_MODULE} PID : ${L_KILL_PID} SQL_ID : ${L_SQL_ID} SESSION_IN_WAIT : ${L_SESSION_IN_WAIT}"
       kill -9 ${L_KILL_PID}
   fi
   sleep 1

done < ${KILL_PID_LIST}

### リストファイル削除 ###
rm -f ${KILL_PID_LIST} >> ${L_rogumei}

### 処理開始出力 ###
L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了"

L_shuryo ${TE_ZCZZSEIJOUSHURYO}
